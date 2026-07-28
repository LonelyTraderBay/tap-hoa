import { Injectable } from '@nestjs/common';
import { Prisma, Role, StockDocType } from '@prisma/client';
import { randomUUID } from 'crypto';
import { AuthUser } from '../auth/jwt.strategy';
import { splitInclusiveVat } from '../ledger/journal-builders';
import { LedgerService } from '../ledger/ledger.service';
import { PrismaService } from '../prisma/prisma.service';
import { PushSaleReturnDto } from './dto/push-sale.dto';

type ProcessResult =
  | { accepted: true }
  | { accepted: false; reason: string };

const ICT_OFFSET_MS = 7 * 60 * 60 * 1000;

function ictDateKey(d: Date): string {
  const ict = new Date(d.getTime() + ICT_OFFSET_MS);
  const y = ict.getUTCFullYear();
  const m = String(ict.getUTCMonth() + 1).padStart(2, '0');
  const day = String(ict.getUTCDate()).padStart(2, '0');
  return `${y}-${m}-${day}`;
}

@Injectable()
export class SaleReturnsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly ledger: LedgerService,
  ) {}

  private canAccessStore(user: AuthUser, storeId: string): boolean {
    return user.role === Role.owner || user.storeIds.includes(storeId);
  }

  private isManagerOrOwner(user: AuthUser): boolean {
    return user.role === Role.owner || user.role === Role.store_manager;
  }

  async processFromSync(
    user: AuthUser,
    dto: PushSaleReturnDto,
  ): Promise<ProcessResult> {
    if (!this.isManagerOrOwner(user)) {
      return { accepted: false, reason: 'role_forbidden' };
    }
    if (!dto.id || !dto.storeId || !dto.originalSaleId) {
      return { accepted: false, reason: 'invalid_return' };
    }
    if (!this.canAccessStore(user, dto.storeId)) {
      return { accepted: false, reason: 'store_forbidden' };
    }
    if (!Array.isArray(dto.lines) || dto.lines.length === 0) {
      return { accepted: false, reason: 'invalid_return' };
    }

    const existing = await this.prisma.saleReturn.findUnique({
      where: { id: dto.id },
    });
    if (existing) {
      return { accepted: true };
    }

    const sale = await this.prisma.sale.findUnique({
      where: { id: dto.originalSaleId },
      include: { lines: true },
    });
    if (!sale || sale.storeId !== dto.storeId) {
      return { accepted: false, reason: 'sale_not_found' };
    }

    const clientCreatedAt = new Date(dto.clientCreatedAt);
    if (Number.isNaN(clientCreatedAt.getTime())) {
      return { accepted: false, reason: 'invalid_return' };
    }
    if (ictDateKey(sale.clientCreatedAt) !== ictDateKey(clientCreatedAt)) {
      return { accepted: false, reason: 'return_not_same_day' };
    }

    const priorReturns = await this.prisma.saleReturn.findMany({
      where: { originalSaleId: sale.id },
      include: { lines: true },
    });
    const returnedQty = new Map<string, Prisma.Decimal>();
    for (const r of priorReturns) {
      for (const line of r.lines) {
        const prev = returnedQty.get(line.productId) ?? new Prisma.Decimal(0);
        returnedQty.set(line.productId, prev.plus(line.qty));
      }
    }

    const soldByProduct = new Map(
      sale.lines.map((l) => [l.productId, l] as const),
    );

    for (const line of dto.lines) {
      let qty: Prisma.Decimal;
      try {
        qty = new Prisma.Decimal(line.qty);
      } catch {
        return { accepted: false, reason: 'invalid_return' };
      }
      if (!qty.isFinite() || qty.lessThanOrEqualTo(0)) {
        return { accepted: false, reason: 'invalid_return' };
      }
      const sold = soldByProduct.get(line.productId);
      if (!sold) {
        return { accepted: false, reason: 'invalid_return_line' };
      }
      const already = returnedQty.get(line.productId) ?? new Prisma.Decimal(0);
      if (already.plus(qty).greaterThan(sold.qty)) {
        return { accepted: false, reason: 'return_qty_exceeded' };
      }
    }

    const cash = dto.cashRefundVnd ?? 0;
    const transfer = dto.transferRefundVnd ?? 0;
    const debtCredit = dto.debtCreditVnd ?? 0;
    const total = dto.totalRefundVnd ?? cash + transfer + debtCredit;
    if (
      !Number.isSafeInteger(cash) ||
      !Number.isSafeInteger(transfer) ||
      !Number.isSafeInteger(debtCredit) ||
      !Number.isSafeInteger(total) ||
      cash < 0 ||
      transfer < 0 ||
      debtCredit < 0 ||
      total < 0 ||
      cash + transfer + debtCredit !== total
    ) {
      return { accepted: false, reason: 'invalid_return' };
    }
    if (debtCredit > 0 && !sale.customerId) {
      return { accepted: false, reason: 'invalid_return' };
    }

    // Tax snapshot per line: prefer original sale line snapshot rate,
    // then product override, then store default (when VAT on).
    const store = await this.prisma.store.findUnique({
      where: { id: dto.storeId },
      select: { vatEnabled: true, defaultVatRateBps: true },
    });
    const storeVat =
      store?.vatEnabled && store.defaultVatRateBps > 0
        ? store.defaultVatRateBps
        : null;
    const productVat = new Map<string, number | null>();
    for (const line of dto.lines) {
      if (!productVat.has(line.productId)) {
        const p = await this.prisma.product.findUnique({
          where: { id: line.productId },
          select: { vatRateBps: true },
        });
        productVat.set(line.productId, p?.vatRateBps ?? null);
      }
    }
    const taxSnapshot = (line: {
      productId: string;
      lineRefundVnd: number;
    }): { vatRateBps: number | null; netVnd: number | null; vatVnd: number | null } => {
      const orig = soldByProduct.get(line.productId);
      const rate =
        orig?.vatRateBps ?? productVat.get(line.productId) ?? storeVat;
      if (rate == null || rate <= 0) {
        return { vatRateBps: null, netVnd: null, vatVnd: null };
      }
      const { netVnd, vatVnd } = splitInclusiveVat(line.lineRefundVnd, rate);
      return { vatRateBps: rate, netVnd, vatVnd };
    };

    try {
      await this.prisma.$transaction(async (tx) => {
        await tx.saleReturn.create({
          data: {
            id: dto.id,
            storeId: dto.storeId,
            originalSaleId: dto.originalSaleId,
            shiftId: dto.shiftId ?? null,
            recordedById: user.userId,
            cashRefundVnd: cash,
            transferRefundVnd: transfer,
            debtCreditVnd: debtCredit,
            totalRefundVnd: total,
            note: dto.note ?? null,
            clientCreatedAt,
            lines: {
              create: dto.lines.map((l) => {
                const snap = taxSnapshot(l);
                return {
                  id: l.id ?? randomUUID(),
                  productId: l.productId,
                  qty: new Prisma.Decimal(l.qty),
                  unitPrice: l.unitPrice,
                  lineRefundVnd: l.lineRefundVnd,
                  vatRateBps: snap.vatRateBps,
                  netVnd: snap.netVnd,
                  vatVnd: snap.vatVnd,
                };
              }),
            },
          },
        });

        for (const line of dto.lines) {
          const lineId = line.id ?? randomUUID();
          const qty = new Prisma.Decimal(line.qty);
          const product = await tx.product.findUnique({
            where: { id: line.productId },
            include: { comboComponents: true },
          });
          if (product?.kind === 'combo' && product.comboComponents.length > 0) {
            for (const c of product.comboComponents) {
              const delta = qty.mul(c.qtyBase);
              await this.restock(tx, {
                storeId: dto.storeId,
                productId: c.componentProductId,
                delta,
                docId: dto.id,
                docLineId: lineId,
                recordedById: user.userId,
                clientCreatedAt,
              });
            }
          } else {
            await this.restock(tx, {
              storeId: dto.storeId,
              productId: line.productId,
              delta: qty,
              docId: dto.id,
              docLineId: lineId,
              recordedById: user.userId,
              clientCreatedAt,
            });
          }
        }

        if (debtCredit > 0 && sale.customerId) {
          const customer = await tx.customer.findUniqueOrThrow({
            where: { id: sale.customerId },
          });
          const newBalance = Math.max(0, customer.balanceVnd - debtCredit);
          await tx.customer.update({
            where: { id: customer.id },
            data: { balanceVnd: newBalance },
          });
          await tx.debtLedgerEntry.create({
            data: {
              id: randomUUID(),
              storeId: dto.storeId,
              customerId: customer.id,
              type: 'sale_return_credit',
              amountVnd: debtCredit,
              balanceAfterVnd: newBalance,
              recordedById: user.userId,
              note: `return:${dto.id}`,
              clientCreatedAt,
            },
          });
        }

        // §5.7: trả hàng/hủy đơn phải có nhật ký kiểm soát — ghi cùng
        // transaction tạo SaleReturn để không thể có bản ghi mồ côi.
        await tx.auditLog.create({
          data: {
            id: randomUUID(),
            actorUserId: user.userId,
            action: 'sale_return_create',
            entityType: 'sale_return',
            entityId: dto.id,
            detailJson: JSON.stringify({
              saleId: dto.originalSaleId,
              storeId: dto.storeId,
              totalVnd: total,
              cashRefundVnd: cash,
              transferRefundVnd: transfer,
              debtCreditVnd: debtCredit,
              reason: dto.note ?? null,
            }),
          },
        });
      });
      await this.ledger.safePost(
        () => this.ledger.postFromSaleReturn(dto.id, user.userId),
        {
          sourceType: 'sale_return',
          sourceId: dto.id,
          actorUserId: user.userId,
        },
      );
      return { accepted: true };
    } catch (error) {
      if (error instanceof Error && error.message === 'stock_not_found') {
        return { accepted: false, reason: 'stock_not_found' };
      }
      throw error;
    }
  }

  private async restock(
    tx: Prisma.TransactionClient,
    params: {
      storeId: string;
      productId: string;
      delta: Prisma.Decimal;
      docId: string;
      docLineId: string;
      recordedById: string;
      clientCreatedAt: Date;
    },
  ) {
    const stock = await tx.productStoreStock.findUnique({
      where: {
        productId_storeId: {
          productId: params.productId,
          storeId: params.storeId,
        },
      },
    });
    if (!stock) {
      throw new Error('stock_not_found');
    }
    const nextQty = stock.qty.plus(params.delta);
    await tx.productStoreStock.update({
      where: {
        productId_storeId: {
          productId: params.productId,
          storeId: params.storeId,
        },
      },
      data: { qty: nextQty },
    });
    await tx.stockMovement.create({
      data: {
        id: randomUUID(),
        storeId: params.storeId,
        productId: params.productId,
        qtyDelta: params.delta,
        balanceAfter: nextQty,
        docType: StockDocType.sale_return,
        docId: params.docId,
        docLineId: params.docLineId,
        recordedById: params.recordedById,
        clientCreatedAt: params.clientCreatedAt,
      },
    });
  }
}
