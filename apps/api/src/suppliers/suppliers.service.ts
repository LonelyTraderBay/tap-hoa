import {
  BadRequestException,
  ForbiddenException,
  Injectable,
} from '@nestjs/common';
import { CashChannel, Prisma, Role, StockDocType } from '@prisma/client';
import { randomUUID } from 'crypto';
import { AuthUser } from '../auth/jwt.strategy';
import { splitInclusiveVat } from '../ledger/journal-builders';
import { LedgerService } from '../ledger/ledger.service';
import { PrismaService } from '../prisma/prisma.service';

export type CreateSupplierReturnDto = {
  storeId: string;
  purchaseReceiptId: string;
  clientId?: string;
  note?: string;
  clientCreatedAt?: string;
  lines: {
    productId: string;
    qty: string | number;
    unitCostVnd: number;
    purchaseReceiptLineId?: string;
  }[];
};

@Injectable()
export class SuppliersService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly ledger: LedgerService,
  ) {}

  assertOwnerOrManager(user: AuthUser) {
    if (user.role !== Role.owner && user.role !== Role.store_manager) {
      throw new ForbiddenException('forbidden');
    }
  }

  assertStoreAccess(user: AuthUser, storeId: string) {
    if (user.role === Role.owner) return;
    if (!user.storeIds.includes(storeId)) {
      throw new ForbiddenException('store_forbidden');
    }
  }

  list() {
    return this.prisma.supplier.findMany({
      where: { active: true },
      orderBy: { name: 'asc' },
    });
  }

  create(body: { name: string; phone?: string; note?: string }) {
    return this.prisma.supplier.create({
      data: {
        id: randomUUID(),
        name: body.name.trim(),
        phone: body.phone ?? null,
        note: body.note ?? null,
      },
    });
  }

  bankAccounts() {
    return this.prisma.bankAccount.findMany({
      where: { active: true },
      orderBy: { name: 'asc' },
    });
  }

  createBank(body: { name: string; bankName?: string; accountNo?: string }) {
    return this.prisma.bankAccount.create({
      data: {
        id: randomUUID(),
        name: body.name.trim(),
        bankName: body.bankName ?? null,
        accountNo: body.accountNo ?? null,
      },
    });
  }

  payables(supplierId: string, storeId?: string) {
    return this.prisma.supplierPayable.findMany({
      where: {
        supplierId,
        balanceVnd: { gt: 0 },
        ...(storeId ? { storeId } : {}),
      },
      orderBy: { clientCreatedAt: 'asc' },
    });
  }

  /** Open receipts with remaining returnable qty per line. */
  async returnableReceipts(supplierId: string, storeId: string) {
    const receipts = await this.prisma.purchaseReceipt.findMany({
      where: { supplierId, storeId },
      include: {
        lines: { include: { product: { select: { id: true, sku: true, name: true } } } },
        payable: true,
      },
      orderBy: { clientCreatedAt: 'desc' },
    });
    const returns = await this.prisma.supplierReturn.findMany({
      where: { supplierId, storeId, purchaseReceiptId: { not: null } },
      include: { lines: true },
    });
    const returnedQty = new Map<string, number>();
    for (const r of returns) {
      for (const l of r.lines) {
        const key = `${r.purchaseReceiptId}:${l.productId}`;
        returnedQty.set(key, (returnedQty.get(key) ?? 0) + Number(l.qty));
      }
    }
    return receipts
      .map((receipt) => {
        const lines = receipt.lines
          .map((l) => {
            const already =
              returnedQty.get(`${receipt.id}:${l.productId}`) ?? 0;
            const remain = Number(l.qty) - already;
            return {
              id: l.id,
              productId: l.productId,
              sku: l.product.sku,
              name: l.product.name,
              qtyPurchased: Number(l.qty),
              qtyReturned: already,
              qtyReturnable: Math.max(0, remain),
              unitCostVnd: l.unitCostVnd,
              vatRateBps: l.vatRateBps,
              netVnd: l.netVnd,
              vatVnd: l.vatVnd,
            };
          })
          .filter((l) => l.qtyReturnable > 0);
        return {
          id: receipt.id,
          supplierName: receipt.supplierName,
          clientCreatedAt: receipt.clientCreatedAt,
          payableBalanceVnd: receipt.payable?.balanceVnd ?? 0,
          lines,
        };
      })
      .filter((r) => r.lines.length > 0);
  }

  async pay(
    user: AuthUser,
    supplierId: string,
    body: {
      storeId: string;
      amountVnd: number;
      channel?: 'cash' | 'transfer';
      bankAccountId?: string;
      note?: string;
      clientCreatedAt?: string;
    },
  ) {
    this.assertOwnerOrManager(user);
    this.assertStoreAccess(user, body.storeId);
    if (!body.amountVnd || body.amountVnd <= 0) {
      throw new BadRequestException('amountVnd required');
    }
    const supplier = await this.prisma.supplier.findUnique({
      where: { id: supplierId },
    });
    if (!supplier) throw new BadRequestException('supplier_not_found');
    const channel =
      body.channel === 'transfer' ? CashChannel.transfer : CashChannel.cash;
    const id = randomUUID();
    const at = body.clientCreatedAt
      ? new Date(body.clientCreatedAt)
      : new Date();

    await this.prisma.$transaction(async (tx) => {
      let remaining = body.amountVnd;
      const payables = await tx.supplierPayable.findMany({
        where: {
          supplierId,
          storeId: body.storeId,
          balanceVnd: { gt: 0 },
        },
        orderBy: { clientCreatedAt: 'asc' },
      });
      for (const p of payables) {
        if (remaining <= 0) break;
        const take = Math.min(remaining, p.balanceVnd);
        await tx.supplierPayable.update({
          where: { id: p.id },
          data: { balanceVnd: p.balanceVnd - take },
        });
        remaining -= take;
      }
      await tx.supplierPayment.create({
        data: {
          id,
          supplierId,
          storeId: body.storeId,
          amountVnd: body.amountVnd,
          channel,
          bankAccountId: body.bankAccountId ?? null,
          note: body.note ?? null,
          recordedById: user.userId,
          clientCreatedAt: at,
        },
      });
    });

    await this.ledger.safePost(
      () => this.ledger.postFromSupplierPayment(id, user.userId),
      {
        sourceType: 'supplier_payment',
        sourceId: id,
        actorUserId: user.userId,
      },
    );
    return { id };
  }

  async createReturn(
    user: AuthUser,
    supplierId: string,
    body: CreateSupplierReturnDto,
  ) {
    this.assertOwnerOrManager(user);
    this.assertStoreAccess(user, body.storeId);
    if (!body.purchaseReceiptId) {
      throw new BadRequestException('purchaseReceiptId_required');
    }
    if (!Array.isArray(body.lines) || body.lines.length === 0) {
      throw new BadRequestException('lines_required');
    }

    if (body.clientId) {
      const existing = await this.prisma.supplierReturn.findUnique({
        where: {
          storeId_clientId: {
            storeId: body.storeId,
            clientId: body.clientId,
          },
        },
      });
      if (existing) {
        return { id: existing.id, amountVnd: existing.amountVnd, idempotent: true };
      }
    }

    const receipt = await this.prisma.purchaseReceipt.findUnique({
      where: { id: body.purchaseReceiptId },
      include: { lines: true, payable: true },
    });
    if (!receipt || receipt.storeId !== body.storeId) {
      throw new BadRequestException('purchase_receipt_not_found');
    }
    if (receipt.supplierId !== supplierId) {
      throw new BadRequestException('receipt_supplier_mismatch');
    }

    const priorReturns = await this.prisma.supplierReturn.findMany({
      where: { purchaseReceiptId: receipt.id },
      include: { lines: true },
    });
    const returnedQty = new Map<string, number>();
    for (const r of priorReturns) {
      for (const l of r.lines) {
        returnedQty.set(
          l.productId,
          (returnedQty.get(l.productId) ?? 0) + Number(l.qty),
        );
      }
    }

    const store = await this.prisma.store.findUnique({
      where: { id: body.storeId },
      select: { vatEnabled: true, defaultVatRateBps: true },
    });
    const storeVat =
      store?.vatEnabled && store.defaultVatRateBps > 0
        ? store.defaultVatRateBps
        : null;

    const lines: {
      id: string;
      productId: string;
      qty: Prisma.Decimal;
      unitCostVnd: number;
      purchaseReceiptLineId: string | null;
      vatRateBps: number | null;
      netVnd: number | null;
      vatVnd: number | null;
    }[] = [];
    let amountVnd = 0;

    for (const line of body.lines) {
      if (!line.productId || line.unitCostVnd == null || line.unitCostVnd < 0) {
        throw new BadRequestException('invalid_line');
      }
      const qty = new Prisma.Decimal(String(line.qty ?? ''));
      if (qty.lte(0)) throw new BadRequestException('invalid_qty');

      const receiptLines = receipt.lines.filter(
        (l) => l.productId === line.productId,
      );
      if (receiptLines.length === 0) {
        throw new BadRequestException('product_not_on_receipt');
      }
      const receiptLine =
        (line.purchaseReceiptLineId
          ? receiptLines.find((l) => l.id === line.purchaseReceiptLineId)
          : null) ?? receiptLines[0];
      const purchased = receiptLines.reduce((s, l) => s + Number(l.qty), 0);
      const already = returnedQty.get(line.productId) ?? 0;
      if (Number(qty) > purchased - already + 1e-9) {
        throw new BadRequestException('return_qty_exceeds_receipt');
      }
      // Cost must not exceed original gross unit cost
      if (
        receiptLine.unitCostVnd != null &&
        line.unitCostVnd > receiptLine.unitCostVnd
      ) {
        throw new BadRequestException('return_cost_exceeds_receipt');
      }

      const gross = Math.round(Number(qty) * line.unitCostVnd);
      amountVnd += gross;
      const rate =
        receiptLine.vatRateBps ??
        (await this.prisma.product
          .findUnique({
            where: { id: line.productId },
            select: { vatRateBps: true },
          })
          .then((p) => p?.vatRateBps ?? storeVat));
      let netVnd: number | null = null;
      let vatVnd: number | null = null;
      if (rate != null && rate > 0) {
        const split = splitInclusiveVat(gross, rate);
        netVnd = split.netVnd;
        vatVnd = split.vatVnd;
      }
      returnedQty.set(line.productId, already + Number(qty));
      lines.push({
        id: randomUUID(),
        productId: line.productId,
        qty,
        unitCostVnd: line.unitCostVnd,
        purchaseReceiptLineId: receiptLine.id,
        vatRateBps: rate,
        netVnd,
        vatVnd,
      });
    }
    if (amountVnd <= 0) throw new BadRequestException('invalid_amount');

    const payable = receipt.payable;
    if (!payable) {
      throw new BadRequestException('ap_already_settled');
    }
    if (amountVnd > payable.balanceVnd) {
      throw new BadRequestException('ap_insufficient');
    }

    const id = randomUUID();
    const at = body.clientCreatedAt
      ? new Date(body.clientCreatedAt)
      : new Date();

    try {
      await this.prisma.$transaction(async (tx) => {
        await tx.supplierReturn.create({
          data: {
            id,
            storeId: body.storeId,
            supplierId,
            purchaseReceiptId: receipt.id,
            clientId: body.clientId ?? null,
            note: body.note ?? null,
            amountVnd,
            recordedById: user.userId,
            clientCreatedAt: at,
            lines: {
              create: lines.map((l) => ({
                id: l.id,
                productId: l.productId,
                qty: l.qty,
                unitCostVnd: l.unitCostVnd,
                purchaseReceiptLineId: l.purchaseReceiptLineId,
                vatRateBps: l.vatRateBps,
                netVnd: l.netVnd,
                vatVnd: l.vatVnd,
              })),
            },
          },
        });

        for (const line of lines) {
          const stock = await tx.productStoreStock.findUnique({
            where: {
              productId_storeId: {
                productId: line.productId,
                storeId: body.storeId,
              },
            },
          });
          if (!stock) throw new Error('stock_not_found');
          const nextQty = stock.qty.minus(line.qty);
          if (nextQty.lessThan(0)) throw new Error('insufficient_stock');
          await tx.productStoreStock.update({
            where: {
              productId_storeId: {
                productId: line.productId,
                storeId: body.storeId,
              },
            },
            data: { qty: nextQty },
          });
          await tx.stockMovement.create({
            data: {
              id: randomUUID(),
              storeId: body.storeId,
              productId: line.productId,
              qtyDelta: line.qty.negated(),
              balanceAfter: nextQty,
              docType: StockDocType.supplier_return,
              docId: id,
              docLineId: line.id,
              recordedById: user.userId,
              clientCreatedAt: at,
            },
          });
        }

        await tx.supplierPayable.update({
          where: { id: payable.id },
          data: { balanceVnd: payable.balanceVnd - amountVnd },
        });

        // Atomic journal inside same transaction
        const storeVatRate =
          store?.vatEnabled && store.defaultVatRateBps > 0
            ? store.defaultVatRateBps
            : null;
        const { buildPurchaseReturnJournal, periodYmFromDate, assertBalanced } =
          await import('../ledger/journal-builders');
        const journalLines = buildPurchaseReturnJournal({
          vatRateBps: storeVatRate,
          lines: lines.map((l) => ({
            qty: Number(l.qty),
            unitCostVnd: l.unitCostVnd,
            vatRateBps: l.vatRateBps ?? storeVatRate,
          })),
        });
        if (journalLines.length > 0) {
          assertBalanced(journalLines);
          const periodYm = periodYmFromDate(at);
          const locked = await tx.periodLock.findUnique({ where: { periodYm } });
          if (!locked) {
            const existing = await tx.journalEntry.findUnique({
              where: {
                sourceType_sourceId: {
                  sourceType: 'supplier_return',
                  sourceId: id,
                },
              },
            });
            if (!existing) {
              await tx.journalEntry.create({
                data: {
                  id: randomUUID(),
                  storeId: body.storeId,
                  periodYm,
                  sourceType: 'supplier_return',
                  sourceId: id,
                  postedAt: at,
                  memo: `Return to supplier ${supplierId}`,
                  lines: {
                    create: journalLines.map((l) => ({
                      id: randomUUID(),
                      accountCode: l.accountCode,
                      debitVnd: l.debitVnd,
                      creditVnd: l.creditVnd,
                    })),
                  },
                },
              });
            }
          }
        }
      });
    } catch (error) {
      if (error instanceof Error) {
        if (error.message === 'stock_not_found') {
          throw new BadRequestException('stock_not_found');
        }
        if (error.message === 'insufficient_stock') {
          throw new BadRequestException('insufficient_stock');
        }
        if (
          error instanceof Prisma.PrismaClientKnownRequestError &&
          error.code === 'P2002'
        ) {
          const again = body.clientId
            ? await this.prisma.supplierReturn.findUnique({
                where: {
                  storeId_clientId: {
                    storeId: body.storeId,
                    clientId: body.clientId,
                  },
                },
              })
            : null;
          if (again) {
            return { id: again.id, amountVnd: again.amountVnd, idempotent: true };
          }
        }
      }
      throw error;
    }

    // Fallback post if journal was skipped (period lock) — fail soft
    await this.ledger.safePost(
      () => this.ledger.postFromSupplierReturn(id, user.userId),
      {
        sourceType: 'supplier_return',
        sourceId: id,
        actorUserId: user.userId,
      },
    );

    return { id, amountVnd };
  }
}
