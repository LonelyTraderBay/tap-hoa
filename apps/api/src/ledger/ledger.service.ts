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
  buildSaleJournal,
  buildSupplierPaymentJournal,
  periodYmFromDate,
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

  async postFromSale(saleId: string, actorUserId?: string) {
    const sale = await this.prisma.sale.findUnique({
      where: { id: saleId },
      include: { lines: true },
    });
    if (!sale) return;
    const lines = buildSaleJournal({
      cashAmount: sale.cashAmount,
      transferAmount: sale.transferAmount,
      debtAmount: sale.debtAmount,
      totalVnd: sale.totalVnd,
      lines: sale.lines.map((l) => ({
        qty: Number(l.qty),
        unitCostVnd: l.unitCostVnd,
      })),
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
      include: { lines: true },
    });
    if (!row) return;
    const lines = buildPurchaseJournal({
      lines: row.lines.map((l) => ({
        qty: Number(l.qty),
        unitCostVnd: l.unitCostVnd,
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

  async trialBalance(user: AuthUser, periodYm: string) {
    this.assertLedgerAccess(user);
    if (!/^\d{4}-\d{2}$/.test(periodYm)) {
      throw new Error('invalid_period');
    }
    const entries = await this.prisma.journalEntry.findMany({
      where: { periodYm },
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
