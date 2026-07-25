import { Injectable } from '@nestjs/common';
import { Prisma, Role, StockDocType } from '@prisma/client';
import { randomUUID } from 'crypto';
import { AuthUser } from '../auth/jwt.strategy';
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
              create: dto.lines.map((l) => ({
                id: l.id ?? randomUUID(),
                productId: l.productId,
                qty: new Prisma.Decimal(l.qty),
                unitPrice: l.unitPrice,
                lineRefundVnd: l.lineRefundVnd,
              })),
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
