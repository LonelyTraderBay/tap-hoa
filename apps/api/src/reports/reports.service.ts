import {
  BadRequestException,
  ForbiddenException,
  Injectable,
} from '@nestjs/common';
import { Role } from '@prisma/client';
import { randomUUID } from 'crypto';
import ExcelJS from 'exceljs';
import { AuthUser } from '../auth/jwt.strategy';
import { periodYmFromDate } from '../ledger/journal-builders';
import { PrismaService } from '../prisma/prisma.service';

export type StoreDayReport = {
  storeId: string;
  revenueVnd: number;
  orderCount: number;
  cashVnd: number;
  transferVnd: number;
  debtVnd: number;
};

export type DayReportResponse = {
  byStore: StoreDayReport[];
  totalRevenueVnd: number;
};

export type TopSkuItem = {
  productId: string;
  sku: string;
  name: string;
  qty: number;
  revenueVnd: number;
  estimatedGrossVnd: number | null;
};

export type TopSkusResponse = {
  date: string;
  items: TopSkuItem[];
};

export type StockOnHandItem = {
  productId: string;
  sku: string;
  name: string;
  unit: string;
  qty: number;
  minQty: number;
  costVnd: number;
  estimatedValueVnd: number;
  belowMin: boolean;
};

export type StockOnHandResponse = {
  storeId: string;
  items: StockOnHandItem[];
  totalEstimatedValueVnd: number;
};

const ICT_OFFSET_HOURS = 7;

import { computeDebtAging } from './debt-aging';

@Injectable()
export class ReportsService {
  constructor(private readonly prisma: PrismaService) {}

  private assertStoreAccess(user: AuthUser, storeId: string) {
    if (user.role === Role.owner) {
      return;
    }
    if (!user.storeIds.includes(storeId)) {
      throw new ForbiddenException('No access to this store');
    }
  }

  private parseDateRange(date: string): { start: Date; end: Date } {
    const match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(date);
    if (!match) {
      throw new BadRequestException('date must be YYYY-MM-DD');
    }
    const year = Number(match[1]);
    const month = Number(match[2]);
    const day = Number(match[3]);
    const probe = new Date(Date.UTC(year, month - 1, day, 12, 0, 0, 0));
    if (
      probe.getUTCFullYear() !== year ||
      probe.getUTCMonth() !== month - 1 ||
      probe.getUTCDate() !== day
    ) {
      throw new BadRequestException('date must be YYYY-MM-DD');
    }
    const start = new Date(
      Date.UTC(year, month - 1, day, -ICT_OFFSET_HOURS, 0, 0, 0),
    );
    const end = new Date(
      Date.UTC(year, month - 1, day + 1, -ICT_OFFSET_HOURS, 0, 0, 0),
    );
    return { start, end };
  }

  private async resolveStoreIds(
    user: AuthUser,
    storeId?: string,
  ): Promise<string[]> {
    if (storeId) {
      this.assertStoreAccess(user, storeId);
      return [storeId];
    }
    if (user.role === Role.owner) {
      const stores = await this.prisma.store.findMany({
        where: { active: true },
        select: { id: true },
      });
      return stores.map((store) => store.id);
    }
    return user.storeIds;
  }

  async dayReport(
    user: AuthUser,
    date: string,
    storeId?: string,
  ): Promise<DayReportResponse> {
    const { start, end } = this.parseDateRange(date);
    const storeIds = await this.resolveStoreIds(user, storeId);

    if (storeIds.length === 0) {
      return { byStore: [], totalRevenueVnd: 0 };
    }

    const grouped = await this.prisma.sale.groupBy({
      by: ['storeId'],
      where: {
        storeId: { in: storeIds },
        clientCreatedAt: { gte: start, lt: end },
      },
      _sum: {
        totalVnd: true,
        cashAmount: true,
        transferAmount: true,
        debtAmount: true,
      },
      _count: { id: true },
    });

    const byStore: StoreDayReport[] = grouped.map((row) => ({
      storeId: row.storeId,
      revenueVnd: row._sum.totalVnd ?? 0,
      orderCount: row._count.id,
      cashVnd: row._sum.cashAmount ?? 0,
      transferVnd: row._sum.transferAmount ?? 0,
      debtVnd: row._sum.debtAmount ?? 0,
    }));

    byStore.sort((a, b) => a.storeId.localeCompare(b.storeId));

    const totalRevenueVnd = byStore.reduce(
      (sum, row) => sum + row.revenueVnd,
      0,
    );

    return { byStore, totalRevenueVnd };
  }

  async topSkus(
    user: AuthUser,
    date: string,
    storeId?: string,
    limit?: number,
  ): Promise<TopSkusResponse> {
    const { start, end } = this.parseDateRange(date);
    const storeIds = await this.resolveStoreIds(user, storeId);
    const effectiveLimit = Math.min(Math.max(limit ?? 10, 1), 50);

    if (storeIds.length === 0) {
      return { date, items: [] };
    }

    const lines = await this.prisma.saleLine.findMany({
      where: {
        sale: {
          storeId: { in: storeIds },
          clientCreatedAt: { gte: start, lt: end },
        },
      },
      select: {
        productId: true,
        qty: true,
        lineTotal: true,
        unitCostVnd: true,
        sale: { select: { storeId: true } },
      },
    });

    type Agg = {
      productId: string;
      qty: number;
      revenueVnd: number;
      cogsVnd: number;
      hasCogs: boolean;
    };

    const byProduct = new Map<string, Agg>();

    for (const line of lines) {
      const qtyNum = Number(line.qty);
      let agg = byProduct.get(line.productId);
      if (!agg) {
        agg = {
          productId: line.productId,
          qty: 0,
          revenueVnd: 0,
          cogsVnd: 0,
          hasCogs: false,
        };
        byProduct.set(line.productId, agg);
      }
      agg.qty += qtyNum;
      agg.revenueVnd += line.lineTotal;
      if (line.unitCostVnd != null) {
        agg.cogsVnd += qtyNum * line.unitCostVnd;
        agg.hasCogs = true;
      }
    }

    if (byProduct.size === 0) {
      return { date, items: [] };
    }

    const productIds = [...byProduct.keys()];
    const products = await this.prisma.product.findMany({
      where: { id: { in: productIds } },
      select: { id: true, sku: true, name: true, costVnd: true },
    });
    const productById = new Map(products.map((product) => [product.id, product]));

    const stocks = await this.prisma.productStoreStock.findMany({
      where: {
        productId: { in: productIds },
        storeId: { in: storeIds },
      },
      select: { productId: true, avgCostVnd: true },
    });
    const avgByProduct = new Map<string, number>();
    for (const stock of stocks) {
      const prev = avgByProduct.get(stock.productId);
      if (prev == null || stock.avgCostVnd > 0) {
        avgByProduct.set(stock.productId, stock.avgCostVnd);
      }
    }

    const items: TopSkuItem[] = [...byProduct.values()]
      .map((agg) => {
        const product = productById.get(agg.productId);
        let estimatedGrossVnd: number | null = null;
        if (product) {
          if (agg.hasCogs) {
            estimatedGrossVnd = agg.revenueVnd - Math.round(agg.cogsVnd);
          } else {
            const unit =
              (avgByProduct.get(agg.productId) ?? 0) > 0
                ? avgByProduct.get(agg.productId)!
                : product.costVnd;
            estimatedGrossVnd = agg.revenueVnd - agg.qty * unit;
          }
        }
        return {
          productId: agg.productId,
          sku: product?.sku ?? '',
          name: product?.name ?? '',
          qty: agg.qty,
          revenueVnd: agg.revenueVnd,
          estimatedGrossVnd,
        };
      })
      .sort((a, b) => {
        if (b.qty !== a.qty) {
          return b.qty - a.qty;
        }
        return b.revenueVnd - a.revenueVnd;
      })
      .slice(0, effectiveLimit);

    return { date, items };
  }

  async stockOnHand(
    user: AuthUser,
    storeId: string,
  ): Promise<StockOnHandResponse> {
    this.assertStoreAccess(user, storeId);
    const rows = await this.prisma.productStoreStock.findMany({
      where: { storeId, product: { active: true } },
      include: {
        product: {
          select: {
            id: true,
            sku: true,
            name: true,
            unit: true,
            costVnd: true,
          },
        },
      },
    });
    const items = rows.map((row) => {
      const qty = Number(row.qty);
      const minQty = Number(row.minQty);
      const unitCost =
        row.avgCostVnd > 0 ? row.avgCostVnd : row.product.costVnd;
      const estimatedValueVnd = Math.round(qty * unitCost);
      return {
        productId: row.productId,
        sku: row.product.sku,
        name: row.product.name,
        unit: row.product.unit,
        qty,
        minQty,
        costVnd: unitCost,
        estimatedValueVnd,
        belowMin: qty < minQty,
      };
    });
    items.sort((a, b) => {
      if (a.belowMin !== b.belowMin) {
        return a.belowMin ? -1 : 1;
      }
      return a.name.localeCompare(b.name, 'vi');
    });
    const totalEstimatedValueVnd = items.reduce(
      (sum, item) => sum + item.estimatedValueVnd,
      0,
    );
    return { storeId, items, totalEstimatedValueVnd };
  }

  async debtAging(user: AuthUser, storeId: string) {
    this.assertStoreAccess(user, storeId);
    const store = await this.prisma.store.findUnique({
      where: { id: storeId },
    });
    if (!store) {
      throw new BadRequestException('store not found');
    }
    const customers = await this.prisma.customer.findMany({
      where: { storeId, balanceVnd: { gt: 0 } },
      orderBy: { name: 'asc' },
    });
    const ledger = await this.prisma.debtLedgerEntry.findMany({
      where: { storeId },
      orderBy: { clientCreatedAt: 'asc' },
    });
    const asOf = new Date();
    return {
      storeId,
      debtOverdueDays: store.debtOverdueDays,
      customers: customers.map((c) => {
        const entries = ledger
          .filter((e) => e.customerId === c.id)
          .map((e) => ({
            type: e.type,
            amountVnd: e.amountVnd,
            clientCreatedAt: e.clientCreatedAt,
          }));
        const aging = computeDebtAging(entries, store.debtOverdueDays, asOf);
        return {
          customerId: c.id,
          name: c.name,
          phone: c.phone,
          balanceVnd: c.balanceVnd,
          oldestUnpaidAt: aging.oldestUnpaidAt?.toISOString() ?? null,
          daysOutstanding: aging.daysOutstanding,
          overdue: aging.overdue,
        };
      }),
    };
  }

  async periodTrialBalance(user: AuthUser, periodYm: string) {
    if (user.role !== Role.owner && user.role !== Role.store_manager) {
      throw new ForbiddenException('forbidden');
    }
    if (!/^\d{4}-\d{2}$/.test(periodYm)) {
      throw new BadRequestException('periodYm must be YYYY-MM');
    }
    const entries = await this.prisma.journalEntry.findMany({
      where: { periodYm },
      include: { lines: true },
    });
    const byCode = new Map<string, { debitVnd: number; creditVnd: number }>();
    for (const e of entries) {
      for (const l of e.lines) {
        const cur = byCode.get(l.accountCode) ?? { debitVnd: 0, creditVnd: 0 };
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

  async periodPnl(user: AuthUser, periodYm: string) {
    const tb = await this.periodTrialBalance(user, periodYm);
    const pick = (code: string) =>
      tb.rows.find((r) => r.accountCode === code)?.balanceVnd ?? 0;
    // Revenue credits → negative balance in Dr-Cr convention; flip for PnL
    const revenue511 = -pick('511');
    const otherIncome711 = -pick('711');
    const cogs632 = pick('632');
    const expense642 = pick('642');
    const revenue = revenue511 + otherIncome711;
    const gross = revenue - cogs632;
    const net = gross - expense642;
    return {
      periodYm,
      revenueVnd: revenue,
      cogsVnd: cogs632,
      grossProfitVnd: gross,
      operatingExpenseVnd: expense642,
      netIncomeVnd: net,
    };
  }

  async vatSummary(user: AuthUser, periodYm: string) {
    const tb = await this.periodTrialBalance(user, periodYm);
    const row = (code: string) =>
      tb.rows.find((r) => r.accountCode === code) ?? {
        debitVnd: 0,
        creditVnd: 0,
      };
    const outputVatVnd = row('3331').creditVnd;
    const inputVatVnd = row('1331').debitVnd;
    const revenueBaseVnd = row('511').creditVnd;
    return {
      periodYm,
      outputVatVnd,
      inputVatVnd,
      netVatVnd: outputVatVnd - inputVatVnd,
      revenueBaseVnd,
    };
  }

  async periodExportCsv(user: AuthUser, periodYm: string): Promise<string> {
    const tb = await this.periodTrialBalance(user, periodYm);
    const pnl = await this.periodPnl(user, periodYm);
    const vat = await this.vatSummary(user, periodYm);
    const lines = [
      'section,accountCode,name,debitVnd,creditVnd,balanceVnd',
      ...tb.rows.map(
        (r) =>
          `trial_balance,${r.accountCode},"${r.name}",${r.debitVnd},${r.creditVnd},${r.balanceVnd}`,
      ),
      `pnl,revenue,,${pnl.revenueVnd},,`,
      `pnl,cogs,,${pnl.cogsVnd},,`,
      `pnl,gross_profit,,${pnl.grossProfitVnd},,`,
      `pnl,opex,,${pnl.operatingExpenseVnd},,`,
      `pnl,net_income,,${pnl.netIncomeVnd},,`,
      `vat,output,,${vat.outputVatVnd},,`,
      `vat,input,,${vat.inputVatVnd},,`,
      `vat,net,,${vat.netVatVnd},,`,
      `vat,revenue_base,,${vat.revenueBaseVnd},,`,
    ];
    return lines.join('\n');
  }

  async periodExportXlsx(user: AuthUser, periodYm: string): Promise<Buffer> {
    const tb = await this.periodTrialBalance(user, periodYm);
    const pnl = await this.periodPnl(user, periodYm);
    const vat = await this.vatSummary(user, periodYm);
    const wb = new ExcelJS.Workbook();
    wb.creator = 'tap-hoa';
    const tbSheet = wb.addWorksheet('trial_balance');
    tbSheet.addRow([
      'accountCode',
      'name',
      'type',
      'debitVnd',
      'creditVnd',
      'balanceVnd',
    ]);
    for (const r of tb.rows) {
      tbSheet.addRow([
        r.accountCode,
        r.name,
        r.type,
        r.debitVnd,
        r.creditVnd,
        r.balanceVnd,
      ]);
    }
    const pnlSheet = wb.addWorksheet('pnl');
    pnlSheet.addRow(['metric', 'vnd']);
    pnlSheet.addRow(['revenueVnd', pnl.revenueVnd]);
    pnlSheet.addRow(['cogsVnd', pnl.cogsVnd]);
    pnlSheet.addRow(['grossProfitVnd', pnl.grossProfitVnd]);
    pnlSheet.addRow(['operatingExpenseVnd', pnl.operatingExpenseVnd]);
    pnlSheet.addRow(['netIncomeVnd', pnl.netIncomeVnd]);
    const vatSheet = wb.addWorksheet('vat');
    vatSheet.addRow(['metric', 'vnd']);
    vatSheet.addRow(['outputVatVnd', vat.outputVatVnd]);
    vatSheet.addRow(['inputVatVnd', vat.inputVatVnd]);
    vatSheet.addRow(['netVatVnd', vat.netVatVnd]);
    vatSheet.addRow(['revenueBaseVnd', vat.revenueBaseVnd]);
    const buf = await wb.xlsx.writeBuffer();
    return Buffer.from(buf);
  }

  async cashFundSummary(
    user: AuthUser,
    storeId: string,
    from: string,
    to: string,
  ) {
    this.assertStoreAccess(user, storeId);
    const fromDate = new Date(from);
    const toDate = new Date(to);
    if (Number.isNaN(fromDate.getTime()) || Number.isNaN(toDate.getTime())) {
      throw new BadRequestException('invalid from/to');
    }
    const vouchers = await this.prisma.cashVoucher.findMany({
      where: {
        storeId,
        clientCreatedAt: { gte: fromDate, lte: toDate },
      },
    });
    const sales = await this.prisma.sale.findMany({
      where: {
        storeId,
        clientCreatedAt: { gte: fromDate, lte: toDate },
      },
    });
    let voucherIn = 0;
    let voucherOut = 0;
    for (const v of vouchers) {
      if (v.direction === 'in') voucherIn += v.amountVnd;
      else voucherOut += v.amountVnd;
    }
    const saleCash = sales.reduce((s, x) => s + x.cashAmount, 0);
    const saleTransfer = sales.reduce((s, x) => s + x.transferAmount, 0);
    return {
      storeId,
      from,
      to,
      saleCashVnd: saleCash,
      saleTransferVnd: saleTransfer,
      voucherInVnd: voucherIn,
      voucherOutVnd: voucherOut,
      netCashVnd: saleCash + voucherIn - voucherOut,
    };
  }

  /**
   * Import CSV lines: date,amountVnd,memo (header optional).
   * date = YYYY-MM-DD; amount positive = store inbound transfer.
   */
  async importBankStatement(
    user: AuthUser,
    storeId: string,
    periodYm: string,
    csv: string,
    bankAccountId?: string,
  ) {
    this.assertStoreAccess(user, storeId);
    if (user.role !== Role.owner && user.role !== Role.store_manager) {
      throw new ForbiddenException('forbidden');
    }
    if (!/^\d{4}-\d{2}$/.test(periodYm)) {
      throw new BadRequestException('periodYm must be YYYY-MM');
    }
    const lock = await this.prisma.bankReconLock.findUnique({
      where: { storeId_periodYm: { storeId, periodYm } },
    });
    if (lock) {
      throw new BadRequestException('bank_recon_locked');
    }
    const lines: {
      id: string;
      storeId: string;
      bankAccountId: string | null;
      periodYm: string;
      bookedAt: Date;
      amountVnd: number;
      memo: string | null;
    }[] = [];
    for (const raw of csv.split(/\r?\n/)) {
      const row = raw.trim();
      if (!row || /^date[,;]/i.test(row)) continue;
      const parts = row.split(/[,;]/).map((p) => p.trim());
      if (parts.length < 2) continue;
      const bookedAt = new Date(`${parts[0]}T12:00:00.000Z`);
      const amountVnd = Number(parts[1]);
      if (Number.isNaN(bookedAt.getTime()) || !Number.isSafeInteger(amountVnd)) {
        continue;
      }
      if (periodYmFromDate(bookedAt) !== periodYm) {
        continue;
      }
      lines.push({
        id: randomUUID(),
        storeId,
        bankAccountId: bankAccountId ?? null,
        periodYm,
        bookedAt,
        amountVnd,
        memo: parts[2] || null,
      });
    }
    if (lines.length === 0) {
      throw new BadRequestException('no_valid_statement_lines');
    }
    await this.prisma.bankStatementLine.createMany({ data: lines });
    return { imported: lines.length, periodYm };
  }

  async bankReconSummary(user: AuthUser, storeId: string, periodYm: string) {
    this.assertStoreAccess(user, storeId);
    if (user.role !== Role.owner && user.role !== Role.store_manager) {
      throw new ForbiddenException('forbidden');
    }
    if (!/^\d{4}-\d{2}$/.test(periodYm)) {
      throw new BadRequestException('periodYm must be YYYY-MM');
    }
    const [y, m] = periodYm.split('-').map(Number);
    const from = new Date(Date.UTC(y, m - 1, 1) - 7 * 3600_000);
    const to = new Date(Date.UTC(y, m, 1) - 7 * 3600_000 - 1);

    const sales = await this.prisma.sale.findMany({
      where: {
        storeId,
        clientCreatedAt: { gte: from, lte: to },
        transferAmount: { gt: 0 },
      },
    });
    const vouchers = await this.prisma.cashVoucher.findMany({
      where: {
        storeId,
        channel: 'transfer',
        clientCreatedAt: { gte: from, lte: to },
      },
    });
    const supplierPays = await this.prisma.supplierPayment.findMany({
      where: {
        storeId,
        channel: 'transfer',
        clientCreatedAt: { gte: from, lte: to },
      },
    });
    const statements = await this.prisma.bankStatementLine.findMany({
      where: { storeId, periodYm },
      orderBy: { bookedAt: 'asc' },
    });
    const lock = await this.prisma.bankReconLock.findUnique({
      where: { storeId_periodYm: { storeId, periodYm } },
    });

    type BookLine = {
      ref: string;
      kind: string;
      amountVnd: number;
      at: string;
    };
    const book: BookLine[] = [
      ...sales.map((s) => ({
        ref: `sale:${s.id}`,
        kind: 'sale_transfer',
        amountVnd: s.transferAmount,
        at: s.clientCreatedAt.toISOString(),
      })),
      ...vouchers.map((v) => ({
        ref: `voucher:${v.id}`,
        kind: `voucher_${v.direction}`,
        amountVnd: v.direction === 'in' ? v.amountVnd : -v.amountVnd,
        at: v.clientCreatedAt.toISOString(),
      })),
      ...supplierPays.map((p) => ({
        ref: `supplier_pay:${p.id}`,
        kind: 'supplier_payment',
        amountVnd: -p.amountVnd,
        at: p.clientCreatedAt.toISOString(),
      })),
    ];

    const bookTotal = book.reduce((s, b) => s + b.amountVnd, 0);
    const statementTotal = statements.reduce((s, l) => s + l.amountVnd, 0);

    const unmatchedBook = [...book];
    const matched: {
      statementId: string;
      bookRef: string;
      amountVnd: number;
    }[] = [];
    for (const st of statements) {
      const idx = unmatchedBook.findIndex((b) => b.amountVnd === st.amountVnd);
      if (idx >= 0) {
        const [b] = unmatchedBook.splice(idx, 1);
        matched.push({
          statementId: st.id,
          bookRef: b.ref,
          amountVnd: st.amountVnd,
        });
        if (!st.matchedRef) {
          await this.prisma.bankStatementLine.update({
            where: { id: st.id },
            data: { matchedRef: b.ref },
          });
        }
      }
    }

    return {
      storeId,
      periodYm,
      locked: !!lock,
      bookTotalVnd: bookTotal,
      statementTotalVnd: statementTotal,
      varianceVnd: statementTotal - bookTotal,
      matchedCount: matched.length,
      unmatchedBookCount: unmatchedBook.length,
      unmatchedStatementCount: statements.length - matched.length,
      book,
      statements,
      matched,
      unmatchedBook,
    };
  }

  async lockBankRecon(user: AuthUser, storeId: string, periodYm: string) {
    this.assertStoreAccess(user, storeId);
    if (user.role !== Role.owner && user.role !== Role.store_manager) {
      throw new ForbiddenException('forbidden');
    }
    if (!/^\d{4}-\d{2}$/.test(periodYm)) {
      throw new BadRequestException('periodYm must be YYYY-MM');
    }
    return this.prisma.bankReconLock.upsert({
      where: { storeId_periodYm: { storeId, periodYm } },
      create: {
        id: randomUUID(),
        storeId,
        periodYm,
        lockedById: user.userId,
      },
      update: {},
    });
  }
}
