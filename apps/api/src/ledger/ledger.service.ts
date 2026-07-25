import { Injectable, Logger } from '@nestjs/common';
import { Prisma, Role } from '@prisma/client';
import { randomUUID } from 'crypto';
import { AuthUser } from '../auth/jwt.strategy';
import { PrismaService } from '../prisma/prisma.service';
import {
  JournalLineDraft,
  assertBalanced,
  buildCashVoucherJournal,
  buildDebtPaymentJournal,
  buildPurchaseJournal,
  buildPurchaseReturnJournal,
  buildSaleJournal,
  buildSaleReturnJournal,
  buildStocktakeJournal,
  buildSupplierPaymentJournal,
  computeSaleLineVatSnapshots,
  periodYmFromDate,
  splitInclusiveVat,
} from './journal-builders';
import { seedChartOfAccounts } from './seed-accounts';

@Injectable()
export class LedgerService {
  private readonly logger = new Logger(LedgerService.name);
  private accountsReady = false;

  constructor(private readonly prisma: PrismaService) {}

  async ensureAccounts(): Promise<void> {
    if (this.accountsReady) return;
    await seedChartOfAccounts(this.prisma);
    this.accountsReady = true;
  }

  private async writeAudit(input: {
    actorUserId?: string | null;
    action: string;
    entityType: string;
    entityId?: string | null;
    detail?: unknown;
  }) {
    await this.prisma.auditLog.create({
      data: {
        id: randomUUID(),
        actorUserId: input.actorUserId ?? null,
        action: input.action,
        entityType: input.entityType,
        entityId: input.entityId ?? null,
        detailJson: input.detail ? JSON.stringify(input.detail) : null,
      },
    });
  }

  private async postEntry(input: {
    storeId: string | null;
    sourceType: string;
    sourceId: string;
    postedAt: Date;
    memo?: string;
    lines: JournalLineDraft[];
    actorUserId?: string | null;
  }): Promise<'created' | 'exists' | 'skipped_empty' | 'period_locked'> {
    await this.ensureAccounts();
    if (input.lines.length === 0) {
      return 'skipped_empty';
    }
    assertBalanced(input.lines);

    const existing = await this.prisma.journalEntry.findUnique({
      where: {
        sourceType_sourceId: {
          sourceType: input.sourceType,
          sourceId: input.sourceId,
        },
      },
    });
    if (existing) {
      return 'exists';
    }

    const periodYm = periodYmFromDate(input.postedAt);
    const locked = await this.prisma.periodLock.findUnique({
      where: { periodYm },
    });
    if (locked) {
      await this.writeAudit({
        actorUserId: input.actorUserId,
        action: 'journal_blocked_period_lock',
        entityType: input.sourceType,
        entityId: input.sourceId,
        detail: { periodYm },
      });
      return 'period_locked';
    }

    await this.prisma.journalEntry.create({
      data: {
        id: randomUUID(),
        storeId: input.storeId,
        periodYm,
        sourceType: input.sourceType,
        sourceId: input.sourceId,
        postedAt: input.postedAt,
        memo: input.memo ?? null,
        lines: {
          create: input.lines.map((l) => ({
            id: randomUUID(),
            accountCode: l.accountCode,
            debitVnd: l.debitVnd,
            creditVnd: l.creditVnd,
          })),
        },
      },
    });
    return 'created';
  }

  /** Fail-soft wrapper used from sync hooks. */
  async safePost(
    fn: () => Promise<unknown>,
    meta: { sourceType: string; sourceId: string; actorUserId?: string },
  ): Promise<void> {
    try {
      await fn();
    } catch (e) {
      this.logger.error(
        `ledger post failed ${meta.sourceType}/${meta.sourceId}: ${e}`,
      );
      try {
        await this.writeAudit({
          actorUserId: meta.actorUserId,
          action: 'journal_post_failed',
          entityType: meta.sourceType,
          entityId: meta.sourceId,
          detail: { error: String(e) },
        });
      } catch {
        // ignore audit failure
      }
    }
  }

  private async storeVatRateBps(
    storeId: string,
  ): Promise<number | null> {
    const store = await this.prisma.store.findUnique({
      where: { id: storeId },
      select: { vatEnabled: true, defaultVatRateBps: true },
    });
    if (!store?.vatEnabled || store.defaultVatRateBps <= 0) {
      return null;
    }
    return store.defaultVatRateBps;
  }

  async postFromSale(saleId: string, actorUserId?: string) {
    const sale = await this.prisma.sale.findUnique({
      where: { id: saleId },
      include: {
        lines: { include: { product: { select: { vatRateBps: true } } } },
      },
    });
    if (!sale) return;
    const storeVat = await this.storeVatRateBps(sale.storeId);
    // Backfill snapshots when missing (legacy rows / race before sync wrote them)
    const needSnap = sale.lines.some((l) => l.netVnd == null || l.vatVnd == null);
    if (needSnap && storeVat != null) {
      const snaps = computeSaleLineVatSnapshots({
        lines: sale.lines.map((l) => ({
          lineTotal: l.lineTotal,
          vatRateBps: l.vatRateBps ?? l.product?.vatRateBps ?? storeVat,
        })),
        discountVnd: sale.discountVnd,
        storeVatRateBps: storeVat,
      });
      for (let i = 0; i < sale.lines.length; i++) {
        const snap = snaps[i];
        await this.prisma.saleLine.update({
          where: { id: sale.lines[i].id },
          data: {
            vatRateBps: snap.vatRateBps,
            netVnd: snap.netVnd,
            vatVnd: snap.vatVnd,
          },
        });
        sale.lines[i].vatRateBps = snap.vatRateBps;
        sale.lines[i].netVnd = snap.netVnd;
        sale.lines[i].vatVnd = snap.vatVnd;
      }
    }
    const lines = buildSaleJournal({
      cashAmount: sale.cashAmount,
      transferAmount: sale.transferAmount,
      debtAmount: sale.debtAmount,
      totalVnd: sale.totalVnd,
      discountVnd: sale.discountVnd,
      lines: sale.lines.map((l) => ({
        qty: Number(l.qty),
        unitCostVnd: l.unitCostVnd,
        lineTotal: l.lineTotal,
        vatRateBps: l.vatRateBps ?? l.product?.vatRateBps ?? storeVat,
        netVnd: l.netVnd,
        vatVnd: l.vatVnd,
      })),
      vatRateBps: storeVat,
    });
    await this.postEntry({
      storeId: sale.storeId,
      sourceType: 'sale',
      sourceId: sale.id,
      postedAt: sale.clientCreatedAt,
      memo: `Sale ${sale.id}`,
      lines,
      actorUserId,
    });
  }

  async postFromDebtPayment(entryId: string, actorUserId?: string) {
    const row = await this.prisma.debtLedgerEntry.findUnique({
      where: { id: entryId },
    });
    if (!row || row.type !== 'payment') return;
    const lines = buildDebtPaymentJournal({
      amountVnd: row.amountVnd,
      paymentMethod: row.paymentMethod ?? 'cash',
    });
    await this.postEntry({
      storeId: row.storeId,
      sourceType: 'debt_payment',
      sourceId: row.id,
      postedAt: row.clientCreatedAt,
      lines,
      actorUserId,
    });
  }

  async postFromCashVoucher(voucherId: string, actorUserId?: string) {
    const row = await this.prisma.cashVoucher.findUnique({
      where: { id: voucherId },
    });
    if (!row) return;
    const lines = buildCashVoucherJournal({
      direction: row.direction,
      channel: row.channel,
      amountVnd: row.amountVnd,
    });
    await this.postEntry({
      storeId: row.storeId,
      sourceType: 'cash_voucher',
      sourceId: row.id,
      postedAt: row.clientCreatedAt,
      lines,
      actorUserId,
    });
  }

  async postFromPurchaseReceipt(receiptId: string, actorUserId?: string) {
    const row = await this.prisma.purchaseReceipt.findUnique({
      where: { id: receiptId },
      include: {
        lines: { include: { product: { select: { vatRateBps: true } } } },
      },
    });
    if (!row) return;
    const storeVat = await this.storeVatRateBps(row.storeId);
    for (const l of row.lines) {
      if (l.netVnd != null && l.vatVnd != null) continue;
      if (l.unitCostVnd == null || l.unitCostVnd <= 0) continue;
      const rate = l.vatRateBps ?? l.product.vatRateBps ?? storeVat;
      const gross = Math.round(Number(l.qty) * l.unitCostVnd);
      if (rate != null && rate > 0) {
        const { netVnd, vatVnd } = splitInclusiveVat(gross, rate);
        await this.prisma.purchaseReceiptLine.update({
          where: { id: l.id },
          data: { vatRateBps: rate, netVnd, vatVnd },
        });
        l.vatRateBps = rate;
        l.netVnd = netVnd;
        l.vatVnd = vatVnd;
      }
    }
    const lines = buildPurchaseJournal({
      vatRateBps: storeVat,
      lines: row.lines.map((l) => ({
        qty: Number(l.qty),
        unitCostVnd: l.unitCostVnd,
        vatRateBps: l.vatRateBps ?? l.product.vatRateBps ?? storeVat,
      })),
    });
    await this.postEntry({
      storeId: row.storeId,
      sourceType: 'purchase_receipt',
      sourceId: row.id,
      postedAt: row.clientCreatedAt,
      memo: row.supplierName,
      lines,
      actorUserId,
    });
  }

  async postFromSupplierPayment(paymentId: string, actorUserId?: string) {
    const row = await this.prisma.supplierPayment.findUnique({
      where: { id: paymentId },
    });
    if (!row) return;
    const lines = buildSupplierPaymentJournal({
      amountVnd: row.amountVnd,
      channel: row.channel,
    });
    await this.postEntry({
      storeId: row.storeId,
      sourceType: 'supplier_payment',
      sourceId: row.id,
      postedAt: row.clientCreatedAt,
      lines,
      actorUserId,
    });
  }

  async postFromSupplierReturn(returnId: string, actorUserId?: string) {
    const row = await this.prisma.supplierReturn.findUnique({
      where: { id: returnId },
      include: {
        lines: { include: { product: { select: { vatRateBps: true } } } },
      },
    });
    if (!row) return;
    const storeVat = await this.storeVatRateBps(row.storeId);
    const lines = buildPurchaseReturnJournal({
      vatRateBps: storeVat,
      lines: row.lines.map((l) => ({
        qty: Number(l.qty),
        unitCostVnd: l.unitCostVnd,
        vatRateBps: l.vatRateBps ?? l.product.vatRateBps ?? storeVat,
      })),
    });
    await this.postEntry({
      storeId: row.storeId,
      sourceType: 'supplier_return',
      sourceId: row.id,
      postedAt: row.clientCreatedAt,
      memo: `Return to supplier ${row.supplierId}`,
      lines,
      actorUserId,
    });
  }

  async postFromSaleReturn(returnId: string, actorUserId?: string) {
    const row = await this.prisma.saleReturn.findUnique({
      where: { id: returnId },
      include: {
        lines: true,
        originalSale: {
          include: {
            lines: { include: { product: { select: { vatRateBps: true } } } },
          },
        },
      },
    });
    if (!row) return;
    const origByProduct = new Map(
      row.originalSale.lines.map((l) => [l.productId, l] as const),
    );
    const storeVat = await this.storeVatRateBps(row.storeId);
    const lines = buildSaleReturnJournal({
      cashRefundVnd: row.cashRefundVnd,
      transferRefundVnd: row.transferRefundVnd,
      debtCreditVnd: row.debtCreditVnd,
      totalRefundVnd: row.totalRefundVnd,
      lines: row.lines.map((l) => {
        const orig = origByProduct.get(l.productId);
        const qty = Number(l.qty);
        const origQty = orig ? Number(orig.qty) : 0;
        const ratio =
          origQty > 0 ? Math.min(1, qty / origQty) : 1;
        return {
          qty,
          unitCostVnd: orig?.unitCostVnd ?? null,
          lineTotal: l.lineRefundVnd,
          vatRateBps:
            l.vatRateBps ??
            orig?.vatRateBps ??
            orig?.product?.vatRateBps ??
            storeVat,
          netVnd:
            l.netVnd ??
            (orig?.netVnd != null
              ? Math.round(orig.netVnd * ratio)
              : null),
          vatVnd:
            l.vatVnd ??
            (orig?.vatVnd != null
              ? Math.round(orig.vatVnd * ratio)
              : null),
        };
      }),
      vatRateBps: storeVat,
    });
    await this.postEntry({
      storeId: row.storeId,
      sourceType: 'sale_return',
      sourceId: row.id,
      postedAt: row.clientCreatedAt,
      memo: `Return of ${row.originalSaleId}`,
      lines,
      actorUserId,
    });
  }

  async postFromStocktake(stocktakeId: string, actorUserId?: string) {
    const row = await this.prisma.stocktake.findUnique({
      where: { id: stocktakeId },
      include: { lines: true },
    });
    if (!row) return;
    const costLines: { varianceQty: number; avgCostVnd: number | null }[] = [];
    for (const line of row.lines) {
      const stock = await this.prisma.productStoreStock.findUnique({
        where: {
          productId_storeId: {
            productId: line.productId,
            storeId: row.storeId,
          },
        },
      });
      costLines.push({
        varianceQty: Number(line.varianceQty),
        avgCostVnd: stock?.avgCostVnd ?? null,
      });
    }
    const lines = buildStocktakeJournal({ lines: costLines });
    await this.postEntry({
      storeId: row.storeId,
      sourceType: 'stocktake',
      sourceId: row.id,
      postedAt: row.clientCreatedAt,
      memo: row.note ?? undefined,
      lines,
      actorUserId,
    });
  }

  async listJournal(
    user: AuthUser,
    from: string,
    to: string,
    storeId?: string,
  ) {
    this.assertLedgerAccess(user, storeId);
    const fromDate = new Date(from);
    const toDate = new Date(to);
    if (Number.isNaN(fromDate.getTime()) || Number.isNaN(toDate.getTime())) {
      throw new Error('invalid_date');
    }
    const where: Prisma.JournalEntryWhereInput = {
      postedAt: { gte: fromDate, lte: toDate },
    };
    if (storeId) {
      where.storeId = storeId;
    }
    return this.prisma.journalEntry.findMany({
      where,
      include: { lines: true },
      orderBy: { postedAt: 'asc' },
    });
  }

  async trialBalance(user: AuthUser, periodYm: string, storeId?: string) {
    this.assertLedgerAccess(user);
    if (!/^\d{4}-\d{2}$/.test(periodYm)) {
      throw new Error('invalid_period');
    }
    if (storeId && user.role !== Role.owner && !user.storeIds.includes(storeId)) {
      throw new Error('store_forbidden');
    }
    const entries = await this.prisma.journalEntry.findMany({
      where: {
        periodYm,
        ...(storeId ? { storeId } : {}),
      },
      include: { lines: true },
    });
    const byCode = new Map<string, { debitVnd: number; creditVnd: number }>();
    for (const e of entries) {
      for (const l of e.lines) {
        const cur = byCode.get(l.accountCode) ?? {
          debitVnd: 0,
          creditVnd: 0,
        };
        cur.debitVnd += l.debitVnd;
        cur.creditVnd += l.creditVnd;
        byCode.set(l.accountCode, cur);
      }
    }
    const accounts = await this.prisma.account.findMany({
      orderBy: { code: 'asc' },
    });
    return {
      periodYm,
      storeId: storeId ?? null,
      scope: storeId ? 'store' : 'aggregate',
      rows: accounts.map((a) => {
        const t = byCode.get(a.code) ?? { debitVnd: 0, creditVnd: 0 };
        return {
          accountCode: a.code,
          name: a.name,
          type: a.type,
          debitVnd: t.debitVnd,
          creditVnd: t.creditVnd,
          balanceVnd: t.debitVnd - t.creditVnd,
        };
      }),
    };
  }

  async listPeriodLocks(user: AuthUser) {
    this.assertLedgerAccess(user);
    return this.prisma.periodLock.findMany({ orderBy: { periodYm: 'desc' } });
  }

  async lockPeriod(user: AuthUser, periodYm: string) {
    if (user.role !== Role.owner) {
      throw new Error('owner_required');
    }
    if (!/^\d{4}-\d{2}$/.test(periodYm)) {
      throw new Error('invalid_period');
    }
    const lock = await this.prisma.periodLock.upsert({
      where: { periodYm },
      update: {},
      create: { periodYm, lockedById: user.userId },
    });
    await this.writeAudit({
      actorUserId: user.userId,
      action: 'period_lock',
      entityType: 'period_lock',
      entityId: periodYm,
    });
    return lock;
  }

  private assertLedgerAccess(user: AuthUser, storeId?: string) {
    if (user.role === Role.owner) return;
    if (user.role === Role.store_manager) {
      if (storeId && !user.storeIds.includes(storeId)) {
        throw new Error('store_forbidden');
      }
      return;
    }
    throw new Error('forbidden');
  }
}
