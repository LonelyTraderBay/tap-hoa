import { Injectable, Logger } from '@nestjs/common';
import { Prisma, Role, TransferStatus } from '@prisma/client';
import { randomUUID } from 'crypto';
import { AuthUser } from '../auth/jwt.strategy';
import { hasLedgerPermission } from '../auth/permission-flags';
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
  buildStockTransferStoreJournals,
  buildStocktakeJournal,
  buildSupplierPaymentJournal,
  buildWastageJournal,
  computeSaleLineVatSnapshots,
  periodYmFromDate,
  splitInclusiveVat,
} from './journal-builders';
import { seedChartOfAccounts } from './seed-accounts';

@Injectable()
export class LedgerService {
  private readonly logger = new Logger(LedgerService.name);
  private accountsReady = false;
  private readonly defaultAuditActions = [
    'period_lock',
    'period_unlock',
    'journal_blocked_period_lock',
    'product_price_change',
    'user_create',
    'user_role_change',
    'user_password_reset',
  ];

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
    auditSourceType?: string;
    auditSourceId?: string;
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
        entityType: input.auditSourceType ?? input.sourceType,
        entityId: input.auditSourceId ?? input.sourceId,
        detail: { periodYm, storeId: input.storeId },
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
      include: { category: { select: { accountCode: true } } },
    });
    if (!row) return;
    const lines = buildCashVoucherJournal({
      direction: row.direction,
      channel: row.channel,
      amountVnd: row.amountVnd,
      categoryAccountCode: row.category?.accountCode ?? null,
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

  async postFromStockTransfer(stockTransferId: string, actorUserId?: string) {
    const row = await this.prisma.stockTransfer.findUnique({
      where: { id: stockTransferId },
      include: { lines: true },
    });
    if (!row || row.status !== TransferStatus.received) return;
    const { sourceLines, destinationLines } = buildStockTransferStoreJournals({
      lines: row.lines.map((line) => ({
        qty: Number(line.qty),
        unitCostVnd: line.unitCostVnd,
      })),
    });
    const postedAt = row.receivedAt ?? row.updatedAt;
    await this.postEntry({
      storeId: row.fromStoreId,
      sourceType: 'stock_transfer_out',
      sourceId: row.id,
      postedAt,
      memo: row.note ?? undefined,
      lines: sourceLines,
      actorUserId,
      auditSourceType: 'stock_transfer',
      auditSourceId: row.id,
    });
    await this.postEntry({
      storeId: row.toStoreId,
      sourceType: 'stock_transfer_in',
      sourceId: row.id,
      postedAt,
      memo: row.note ?? undefined,
      lines: destinationLines,
      actorUserId,
      auditSourceType: 'stock_transfer',
      auditSourceId: row.id,
    });
  }

  async postFromWastage(wastageId: string, actorUserId?: string) {
    const row = await this.prisma.wastageVoucher.findUnique({
      where: { id: wastageId },
      include: { lines: true },
    });
    if (!row) return;
    const costLines: { qty: number; avgCostVnd: number | null }[] = [];
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
        qty: Number(line.qty),
        avgCostVnd: stock?.avgCostVnd ?? null,
      });
    }
    const lines = buildWastageJournal({ lines: costLines });
    await this.postEntry({
      storeId: row.storeId,
      sourceType: 'wastage',
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
      ...this.ledgerStoreFilter(user, storeId),
    };
    return this.prisma.journalEntry.findMany({
      where,
      include: { lines: true },
      orderBy: { postedAt: 'asc' },
    });
  }

  async trialBalance(user: AuthUser, periodYm: string, storeId?: string) {
    this.assertLedgerAccess(user, storeId);
    if (!/^\d{4}-\d{2}$/.test(periodYm)) {
      throw new Error('invalid_period');
    }
    const entries = await this.prisma.journalEntry.findMany({
      where: {
        periodYm,
        ...this.ledgerStoreFilter(user, storeId),
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

  async accountLedger(
    user: AuthUser,
    accountCode: string,
    periodYm: string,
    storeId?: string,
  ) {
    this.assertLedgerAccess(user, storeId);
    if (!/^\d{4}-\d{2}$/.test(periodYm)) {
      throw new Error('invalid_period');
    }
    const account = await this.prisma.account.findUnique({
      where: { code: accountCode },
    });
    if (!account) {
      throw new Error('invalid_account');
    }
    const storeFilter = this.ledgerStoreFilter(user, storeId);

    const openingEntries = await this.prisma.journalEntry.findMany({
      where: {
        periodYm: { lt: periodYm },
        ...storeFilter,
      },
      include: {
        lines: { where: { accountCode } },
      },
    });
    const openingBalance = openingEntries.reduce(
      (sum, entry) =>
        sum +
        entry.lines.reduce(
          (lineSum, line) => lineSum + line.debitVnd - line.creditVnd,
          0,
        ),
      0,
    );

    const periodEntries = await this.prisma.journalEntry.findMany({
      where: {
        periodYm,
        ...storeFilter,
      },
      include: {
        lines: { where: { accountCode }, orderBy: { id: 'asc' } },
      },
      orderBy: [{ postedAt: 'asc' }, { id: 'asc' }],
    });

    let runningBalance = openingBalance;
    const lines = [];
    for (const entry of periodEntries) {
      for (const line of entry.lines) {
        const movement = line.debitVnd - line.creditVnd;
        runningBalance += movement;
        lines.push({
          journalEntryId: entry.id,
          journalLineId: line.id,
          postedAt: entry.postedAt,
          periodYm: entry.periodYm,
          storeId: entry.storeId,
          sourceType: entry.sourceType,
          sourceId: entry.sourceId,
          memo: entry.memo,
          debitVnd: line.debitVnd,
          creditVnd: line.creditVnd,
          movementVnd: movement,
          runningBalance,
        });
      }
    }

    return {
      periodYm,
      storeId: storeId ?? null,
      scope: storeId ? 'store' : 'aggregate',
      accountCode: account.code,
      accountName: account.name,
      accountType: account.type,
      openingBalance,
      lines,
      closingBalance: runningBalance,
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

  async unlockPeriod(user: AuthUser, periodYm: string, reason: string) {
    if (user.role !== Role.owner) {
      throw new Error('owner_required');
    }
    if (!/^\d{4}-\d{2}$/.test(periodYm)) {
      throw new Error('invalid_period');
    }
    const trimmedReason = reason.trim();
    if (trimmedReason.length < 3) {
      throw new Error('invalid_reason');
    }
    await this.prisma.periodLock.deleteMany({ where: { periodYm } });
    const replayed = await this.replayBlockedPeriodJournals(
      periodYm,
      user.userId,
    );
    await this.writeAudit({
      actorUserId: user.userId,
      action: 'period_unlock',
      entityType: 'period_lock',
      entityId: periodYm,
      detail: { reason: trimmedReason },
    });
    return { unlocked: true, periodYm, replayed };
  }

  private async replayBlockedPeriodJournals(
    periodYm: string,
    actorUserId?: string,
  ): Promise<number> {
    const rows = await this.prisma.auditLog.findMany({
      where: {
        action: 'journal_blocked_period_lock',
        detailJson: { contains: periodYm },
      },
      distinct: ['entityType', 'entityId'],
      select: { entityType: true, entityId: true, detailJson: true },
    });
    let replayed = 0;
    for (const row of rows) {
      if (
        !row.entityId ||
        !this.auditDetailMatchesPeriod(row.detailJson, periodYm)
      ) {
        continue;
      }
      try {
        const handled = await this.replayJournalSource(
          row.entityType,
          row.entityId,
          actorUserId,
        );
        if (handled) {
          replayed += 1;
        }
      } catch (e) {
        this.logger.error(
          `ledger replay failed ${row.entityType}/${row.entityId}: ${e}`,
        );
      }
    }
    return replayed;
  }

  private auditDetailMatchesPeriod(
    detailJson: string | null,
    periodYm: string,
  ): boolean {
    if (!detailJson) return false;
    try {
      const detail = JSON.parse(detailJson) as { periodYm?: unknown };
      return detail.periodYm === periodYm;
    } catch {
      return false;
    }
  }

  private async replayJournalSource(
    sourceType: string,
    sourceId: string,
    actorUserId?: string,
  ): Promise<boolean> {
    switch (sourceType) {
      case 'sale':
        await this.postFromSale(sourceId, actorUserId);
        return true;
      case 'debt_payment':
        await this.postFromDebtPayment(sourceId, actorUserId);
        return true;
      case 'cash_voucher':
        await this.postFromCashVoucher(sourceId, actorUserId);
        return true;
      case 'purchase_receipt':
        await this.postFromPurchaseReceipt(sourceId, actorUserId);
        return true;
      case 'supplier_payment':
        await this.postFromSupplierPayment(sourceId, actorUserId);
        return true;
      case 'supplier_return':
        await this.postFromSupplierReturn(sourceId, actorUserId);
        return true;
      case 'sale_return':
        await this.postFromSaleReturn(sourceId, actorUserId);
        return true;
      case 'stocktake':
        await this.postFromStocktake(sourceId, actorUserId);
        return true;
      case 'stock_transfer':
        await this.postFromStockTransfer(sourceId, actorUserId);
        return true;
      case 'wastage':
        await this.postFromWastage(sourceId, actorUserId);
        return true;
      default:
        return false;
    }
  }

  /**
   * Danh sách danh mục thu/chi kèm map TK hiện tại (P2.2) — dùng cho màn hình
   * cấu hình kế toán và picker khi tạo bút toán từ đối chiếu ngân hàng.
   */
  async listCashCategories(user: AuthUser) {
    this.assertLedgerAccess(user);
    return this.prisma.cashCategory.findMany({
      orderBy: { sortOrder: 'asc' },
      select: {
        id: true,
        code: true,
        name: true,
        direction: true,
        sortOrder: true,
        accountCode: true,
      },
    });
  }

  /**
   * Gán/gỡ TK cho một danh mục thu/chi (P2.2). Owner-only — cấu hình kế toán
   * áp dụng cho mọi bút toán tương lai của danh mục này, không phải điều
   * store_manager nên tự đổi. `accountCode: null` gỡ map, quay lại fallback
   * cứng cũ (711/642) trong `buildCashVoucherJournal`.
   */
  async setCashCategoryAccount(
    user: AuthUser,
    categoryId: string,
    accountCode: string | null,
  ) {
    if (user.role !== Role.owner) {
      throw new Error('owner_required');
    }
    const category = await this.prisma.cashCategory.findUnique({
      where: { id: categoryId },
    });
    if (!category) {
      throw new Error('category_not_found');
    }
    if (accountCode != null) {
      const account = await this.prisma.account.findUnique({
        where: { code: accountCode },
      });
      if (!account || !account.active) {
        throw new Error('account_not_found');
      }
    }
    return this.prisma.cashCategory.update({
      where: { id: categoryId },
      data: { accountCode },
      select: {
        id: true,
        code: true,
        name: true,
        direction: true,
        sortOrder: true,
        accountCode: true,
      },
    });
  }

  async listAudit(
    user: AuthUser,
    filters: {
      limit?: number;
      action?: string;
      entityType?: string;
      entityId?: string;
      storeId?: string;
    } = {},
  ) {
    this.assertLedgerAccess(user, filters.storeId);
    const limit = filters.limit ?? 50;
    const take = Math.min(Math.max(Math.trunc(limit) || 50, 1), 100);
    const where: Prisma.AuditLogWhereInput = {
      action: filters.action
        ? filters.action
        : { in: this.defaultAuditActions },
    };
    const auditStoreIds = this.ledgerAuditStoreIds(user, filters.storeId);
    if (auditStoreIds) {
      if (auditStoreIds.length === 0) {
        return [];
      }
      where.OR = auditStoreIds.map((storeId) => ({
        detailJson: { contains: this.auditStoreIdFragment(storeId) },
      }));
    }
    if (filters.entityType) {
      where.entityType = filters.entityType;
    }
    if (filters.entityId) {
      where.entityId = filters.entityId;
    }
    return this.prisma.auditLog.findMany({
      where,
      orderBy: { at: 'desc' },
      take,
    });
  }

  private ledgerAuditStoreIds(
    user: AuthUser,
    storeId?: string,
  ): string[] | null {
    if (storeId) {
      return [storeId];
    }
    if (user.role === Role.store_manager) {
      return user.storeIds;
    }
    return null;
  }

  private auditStoreIdFragment(storeId: string): string {
    return `"storeId":"${storeId}"`;
  }

  private assertLedgerAccess(user: AuthUser, storeId?: string) {
    if (user.role === Role.owner) return;
    if (!hasLedgerPermission(user)) {
      throw new Error('forbidden');
    }
    if (user.role === Role.store_manager) {
      if (storeId && !user.storeIds.includes(storeId)) {
        throw new Error('store_forbidden');
      }
      return;
    }
    throw new Error('forbidden');
  }

  private ledgerStoreFilter(
    user: AuthUser,
    storeId?: string,
  ): Prisma.JournalEntryWhereInput {
    if (storeId) {
      return { storeId };
    }
    if (user.role === Role.store_manager) {
      return {
        storeId:
          user.storeIds.length === 1 ? user.storeIds[0] : { in: user.storeIds },
      };
    }
    return {};
  }
}
