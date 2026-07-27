import {
  BadRequestException,
  ForbiddenException,
  Injectable,
} from '@nestjs/common';
import { Role } from '@prisma/client';
import { createHash, randomUUID } from 'crypto';
import ExcelJS from 'exceljs';
import { existsSync } from 'fs';
import { join } from 'path';
import PDFDocument from 'pdfkit';
import { AuthUser } from '../auth/jwt.strategy';
import { periodYmFromDate } from '../ledger/journal-builders';
import { PrismaService } from '../prisma/prisma.service';
import { computeCashFundTotals, sumLedgerMovement } from './cash-fund';

/** TK tiền mặt — nguồn sự thật của sổ quỹ. */
const CASH_ACCOUNT_CODE = '111';

export type StoreDayReport = {
  storeId: string;
  revenueVnd: number;
  orderCount: number;
  cashVnd: number;
  transferVnd: number;
  debtVnd: number;
};

export type ShiftDayReport = StoreDayReport & {
  shiftId: string;
};

export type DayReportResponse = {
  byStore: StoreDayReport[];
  byShift: ShiftDayReport[];
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
const PERIOD_PDF_FONT_NAME = 'NotoSans';
const PERIOD_PDF_FONT_FILE = 'NotoSans-Regular.ttf';

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
      return { byStore: [], byShift: [], totalRevenueVnd: 0 };
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
    const groupedByShift = await this.prisma.sale.groupBy({
      by: ['storeId', 'shiftId'],
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
    const byShift: ShiftDayReport[] = groupedByShift.map((row) => ({
      storeId: row.storeId,
      shiftId: row.shiftId,
      revenueVnd: row._sum.totalVnd ?? 0,
      orderCount: row._count.id,
      cashVnd: row._sum.cashAmount ?? 0,
      transferVnd: row._sum.transferAmount ?? 0,
      debtVnd: row._sum.debtAmount ?? 0,
    }));
    byShift.sort((a, b) => {
      const byStoreId = a.storeId.localeCompare(b.storeId);
      return byStoreId !== 0 ? byStoreId : a.shiftId.localeCompare(b.shiftId);
    });

    const totalRevenueVnd = byStore.reduce(
      (sum, row) => sum + row.revenueVnd,
      0,
    );

    return { byStore, byShift, totalRevenueVnd };
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

  private async resolveDebtAgingStoreFilter(
    user: AuthUser,
    storeId?: string,
  ): Promise<{ storeIds: string[]; scope: 'store' | 'aggregate' }> {
    if (!storeId && user.role !== Role.owner && user.role !== Role.store_manager) {
      throw new ForbiddenException('forbidden');
    }
    const storeIds = await this.resolveStoreIds(user, storeId);
    return { storeIds, scope: storeId ? 'store' : 'aggregate' };
  }

  async debtAging(user: AuthUser, storeId?: string) {
    const { storeIds, scope } = await this.resolveDebtAgingStoreFilter(
      user,
      storeId,
    );
    const stores = await this.prisma.store.findMany({
      where: { id: { in: storeIds } },
      orderBy: { id: 'asc' },
    });
    if (storeId && stores.length === 0) {
      throw new BadRequestException('store not found');
    }
    const effectiveStoreIds = stores.map((store) => store.id);
    const storeById = new Map(stores.map((store) => [store.id, store]));
    if (effectiveStoreIds.length === 0) {
      return {
        storeId: storeId ?? null,
        scope,
        storeIds: [],
        debtOverdueDays: null,
        customers: [],
      };
    }
    const customers = await this.prisma.customer.findMany({
      where: { storeId: { in: effectiveStoreIds }, balanceVnd: { gt: 0 } },
      orderBy: [{ storeId: 'asc' }, { name: 'asc' }],
    });
    const customerIds = customers.map((customer) => customer.id);
    const ledger = await this.prisma.debtLedgerEntry.findMany({
      where: {
        storeId: { in: effectiveStoreIds },
        customerId: { in: customerIds },
      },
      orderBy: { clientCreatedAt: 'asc' },
    });
    const asOf = new Date();
    const ledgerByCustomer = new Map<
      string,
      Array<{
        type: string;
        amountVnd: number;
        clientCreatedAt: Date;
      }>
    >();
    for (const entry of ledger) {
      const entries = ledgerByCustomer.get(entry.customerId) ?? [];
      entries.push({
        type: entry.type,
        amountVnd: entry.amountVnd,
        clientCreatedAt: entry.clientCreatedAt,
      });
      ledgerByCustomer.set(entry.customerId, entries);
    }
    return {
      storeId: storeId ?? null,
      scope,
      storeIds: effectiveStoreIds,
      debtOverdueDays: storeId
        ? (storeById.get(storeId)?.debtOverdueDays ?? null)
        : null,
      customers: customers.map((c) => {
        const debtOverdueDays = storeById.get(c.storeId)?.debtOverdueDays ?? 30;
        const entries = ledgerByCustomer.get(c.id) ?? [];
        const aging = computeDebtAging(entries, debtOverdueDays, asOf);
        return {
          customerId: c.id,
          storeId: c.storeId,
          name: c.name,
          phone: c.phone,
          balanceVnd: c.balanceVnd,
          debtOverdueDays,
          oldestUnpaidAt: aging.oldestUnpaidAt?.toISOString() ?? null,
          daysOutstanding: aging.daysOutstanding,
          overdue: aging.overdue,
        };
      }),
    };
  }

  private async resolvePeriodStoreFilter(
    user: AuthUser,
    storeId?: string,
  ): Promise<{ storeIds: string[]; scope: 'store' | 'aggregate' }> {
    if (user.role !== Role.owner && user.role !== Role.store_manager) {
      throw new ForbiddenException('forbidden');
    }
    const storeIds = await this.resolveStoreIds(user, storeId);
    return { storeIds, scope: storeId ? 'store' : 'aggregate' };
  }

  async periodTrialBalance(
    user: AuthUser,
    periodYm: string,
    storeId?: string,
  ) {
    if (!/^\d{4}-\d{2}$/.test(periodYm)) {
      throw new BadRequestException('periodYm must be YYYY-MM');
    }
    const { storeIds, scope } = await this.resolvePeriodStoreFilter(
      user,
      storeId,
    );
    const entries = await this.prisma.journalEntry.findMany({
      where: {
        periodYm,
        storeId:
          storeIds.length === 1 ? storeIds[0] : { in: storeIds },
      },
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
      storeId: storeId ?? null,
      scope,
      storeIds,
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

  async periodPnl(user: AuthUser, periodYm: string, storeId?: string) {
    const tb = await this.periodTrialBalance(user, periodYm, storeId);
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
      storeId: tb.storeId,
      scope: tb.scope,
      revenueVnd: revenue,
      cogsVnd: cogs632,
      grossProfitVnd: gross,
      operatingExpenseVnd: expense642,
      netIncomeVnd: net,
    };
  }

  async vatSummary(user: AuthUser, periodYm: string, storeId?: string) {
    const tb = await this.periodTrialBalance(user, periodYm, storeId);
    const row = (code: string) =>
      tb.rows.find((r) => r.accountCode === code) ?? {
        debitVnd: 0,
        creditVnd: 0,
      };
    // Net movement: returns reverse VAT/revenue
    const outputVatVnd = row('3331').creditVnd - row('3331').debitVnd;
    const inputVatVnd = row('1331').debitVnd - row('1331').creditVnd;
    const revenueBaseVnd = row('511').creditVnd - row('511').debitVnd;
    return {
      periodYm,
      storeId: tb.storeId,
      scope: tb.scope,
      outputVatVnd,
      inputVatVnd,
      netVatVnd: outputVatVnd - inputVatVnd,
      revenueBaseVnd,
    };
  }

  private csvEscape(value: string | number | null): string {
    const s = String(value);
    if (/[",\n\r]/.test(s)) {
      return `"${s.replace(/"/g, '""')}"`;
    }
    return s;
  }

  async arExportCsv(user: AuthUser, storeId?: string) {
    const aging = await this.debtAging(user, storeId);
    const lines = [
      'storeId,customerId,name,phone,balanceVnd,debtOverdueDays,oldestUnpaidAt,daysOutstanding,overdue',
      ...aging.customers.map((customer) =>
        [
          this.csvEscape(customer.storeId),
          this.csvEscape(customer.customerId),
          this.csvEscape(customer.name),
          this.csvEscape(customer.phone ?? ''),
          customer.balanceVnd,
          customer.debtOverdueDays,
          this.csvEscape(customer.oldestUnpaidAt ?? ''),
          customer.daysOutstanding,
          customer.overdue ? 'true' : 'false',
        ].join(','),
      ),
    ];
    return {
      storeId: aging.storeId,
      scope: aging.scope,
      storeIds: aging.storeIds,
      csv: lines.join('\n'),
    };
  }

  async periodExportCsv(
    user: AuthUser,
    periodYm: string,
    storeId?: string,
  ): Promise<string> {
    const tb = await this.periodTrialBalance(user, periodYm, storeId);
    const pnl = await this.periodPnl(user, periodYm, storeId);
    const vat = await this.vatSummary(user, periodYm, storeId);
    const lines = [
      'section,accountCode,name,debitVnd,creditVnd,balanceVnd',
      ...tb.rows.map(
        (r) =>
          [
            'trial_balance',
            r.accountCode,
            this.csvEscape(r.name),
            r.debitVnd,
            r.creditVnd,
            r.balanceVnd,
          ].join(','),
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
      `meta,scope,${this.csvEscape(tb.scope)},,,`,
      `meta,storeId,${this.csvEscape(tb.storeId ?? 'all')},,,`,
    ];
    return lines.join('\n');
  }

  async periodExportXlsx(
    user: AuthUser,
    periodYm: string,
    storeId?: string,
  ): Promise<Buffer> {
    const tb = await this.periodTrialBalance(user, periodYm, storeId);
    const pnl = await this.periodPnl(user, periodYm, storeId);
    const vat = await this.vatSummary(user, periodYm, storeId);
    const wb = new ExcelJS.Workbook();
    wb.creator = 'tap-hoa';
    const moneyCols = new Set(['debitVnd', 'creditVnd', 'balanceVnd', 'vnd']);
    const formatMoneySheet = (sheet: ExcelJS.Worksheet, headerRow: number) => {
      sheet.views = [{ state: 'frozen', ySplit: headerRow }];
      sheet.getRow(headerRow).font = { bold: true };
      sheet.columns.forEach((col) => {
        const key = String(col.values?.[headerRow] ?? '').toLowerCase();
        if (moneyCols.has(key) || key === 'vnd') {
          col.numFmt = '#,##0';
        }
      });
    };
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
    formatMoneySheet(tbSheet, 1);
    const pnlSheet = wb.addWorksheet('pnl');
    pnlSheet.addRow(['metric', 'vnd']);
    pnlSheet.addRow(['revenueVnd', pnl.revenueVnd]);
    pnlSheet.addRow(['cogsVnd', pnl.cogsVnd]);
    pnlSheet.addRow(['grossProfitVnd', pnl.grossProfitVnd]);
    pnlSheet.addRow(['operatingExpenseVnd', pnl.operatingExpenseVnd]);
    pnlSheet.addRow(['netIncomeVnd', pnl.netIncomeVnd]);
    formatMoneySheet(pnlSheet, 1);
    const vatSheet = wb.addWorksheet('vat');
    vatSheet.addRow(['metric', 'vnd']);
    vatSheet.addRow(['outputVatVnd', vat.outputVatVnd]);
    vatSheet.addRow(['inputVatVnd', vat.inputVatVnd]);
    vatSheet.addRow(['netVatVnd', vat.netVatVnd]);
    vatSheet.addRow(['revenueBaseVnd', vat.revenueBaseVnd]);
    vatSheet.addRow(['scope', tb.scope]);
    vatSheet.addRow(['storeId', tb.storeId ?? 'all']);
    formatMoneySheet(vatSheet, 1);
    const buf = await wb.xlsx.writeBuffer();
    return Buffer.from(buf);
  }

  private formatVnd(n: number): string {
    return new Intl.NumberFormat('vi-VN').format(n) + ' đ';
  }

  private resolvePeriodPdfFontPath(): string | null {
    const candidates = [
      join(process.cwd(), 'assets', 'fonts', PERIOD_PDF_FONT_FILE),
      join(__dirname, '..', '..', 'assets', 'fonts', PERIOD_PDF_FONT_FILE),
      join(__dirname, '..', '..', '..', 'assets', 'fonts', PERIOD_PDF_FONT_FILE),
    ];

    return candidates.find((candidate) => existsSync(candidate)) ?? null;
  }

  private usePeriodPdfFont(doc: PDFKit.PDFDocument): void {
    const fontPath = this.resolvePeriodPdfFontPath();
    if (!fontPath) {
      doc.font('Helvetica');
      return;
    }

    doc.registerFont(PERIOD_PDF_FONT_NAME, fontPath);
    doc.font(PERIOD_PDF_FONT_NAME);
  }

  async periodExportPdf(
    user: AuthUser,
    periodYm: string,
    storeId?: string,
  ): Promise<Buffer> {
    const tb = await this.periodTrialBalance(user, periodYm, storeId);
    const pnl = await this.periodPnl(user, periodYm, storeId);
    const vat = await this.vatSummary(user, periodYm, storeId);
    let storeName = 'Tất cả cửa hàng';
    if (storeId) {
      const store = await this.prisma.store.findUnique({
        where: { id: storeId },
        select: { name: true, code: true },
      });
      storeName = store ? `${store.code} — ${store.name}` : storeId;
    }
    const createdAt = new Date().toISOString();
    return new Promise((resolve, reject) => {
      const doc = new PDFDocument({ margin: 48, size: 'A4' });
      const chunks: Buffer[] = [];
      doc.on('data', (c) => chunks.push(Buffer.from(c)));
      doc.on('end', () => resolve(Buffer.concat(chunks)));
      doc.on('error', reject);
      this.usePeriodPdfFont(doc);
      doc.fontSize(16).text(`Báo cáo kỳ ${periodYm}`, { underline: true });
      doc.fontSize(10).text(`Cửa hàng: ${storeName} (${tb.scope})`);
      doc.text(`Ngày tạo: ${createdAt}`);
      doc.moveDown();
      doc.fontSize(12).text('Kết quả kinh doanh');
      doc.text(`Doanh thu: ${this.formatVnd(pnl.revenueVnd)}`);
      doc.text(`Giá vốn: ${this.formatVnd(pnl.cogsVnd)}`);
      doc.text(`Lãi gộp: ${this.formatVnd(pnl.grossProfitVnd)}`);
      doc.text(`Chi phí: ${this.formatVnd(pnl.operatingExpenseVnd)}`);
      doc.text(`Lãi ròng: ${this.formatVnd(pnl.netIncomeVnd)}`);
      doc.moveDown();
      doc.text('VAT / GTGT (ròng)');
      doc.text(`Đầu ra (3331): ${this.formatVnd(vat.outputVatVnd)}`);
      doc.text(`Đầu vào (1331): ${this.formatVnd(vat.inputVatVnd)}`);
      doc.text(`Phải nộp: ${this.formatVnd(vat.netVatVnd)}`);
      doc.text(`Doanh thu chịu thuế: ${this.formatVnd(vat.revenueBaseVnd)}`);
      doc.moveDown();
      doc.text('Cân đối phát sinh (tóm tắt)');
      for (const r of tb.rows) {
        if (r.debitVnd === 0 && r.creditVnd === 0) continue;
        if (doc.y > 720) doc.addPage();
        doc
          .fontSize(10)
          .text(
            `${r.accountCode} ${r.name}: Nợ ${this.formatVnd(r.debitVnd)} / Có ${this.formatVnd(r.creditVnd)}`,
          );
      }
      doc.end();
    });
  }

  /** Helper CSV for accountant GTGT worksheet — not CQT submission. */
  async vatDeclarationAssist(
    user: AuthUser,
    periodYm: string,
    storeId?: string,
  ): Promise<string> {
    const vat = await this.vatSummary(user, periodYm, storeId);
    const lines = [
      'field,valueVnd,note',
      `periodYm,${this.csvEscape(periodYm)},ky ke toan ICT`,
      `storeId,${this.csvEscape(vat.storeId ?? 'all')},${vat.scope}`,
      `revenueBaseVnd,${vat.revenueBaseVnd},Co 511 net (Cr-Dr)`,
      `outputVatVnd,${vat.outputVatVnd},3331 Cr-Dr — GTGT dau ra rong`,
      `inputVatVnd,${vat.inputVatVnd},1331 Dr-Cr — GTGT dau vao rong`,
      `netVatVnd,${vat.netVatVnd},output - input (ho tro ke khai; khong nop CQT)`,
    ];
    return lines.join('\n');
  }

  /**
   * Sổ quỹ tiền mặt theo chứng từ, đối chiếu thẳng với TK 111 trong sổ cái.
   *
   * Danh sách chứng từ dưới đây phải phủ hết mọi builder chạm 111 — xem
   * `reports/cash-fund.ts`. `ledgerNetCashVnd` là phát sinh ròng TK 111 thật
   * trong sổ cái; `ledgerDiffVnd` ≠ 0 nghĩa là có chứng từ chưa lên sổ
   * (bị khoá kỳ, post journal lỗi) — cần rà lại, không được lặng lẽ bỏ qua.
   */
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
    const range = { gte: fromDate, lte: toDate };
    const [
      sales,
      saleReturns,
      vouchers,
      debtPayments,
      supplierPayments,
      ledgerCashLines,
    ] = await Promise.all([
      this.prisma.sale.findMany({
        where: { storeId, clientCreatedAt: range },
        select: { cashAmount: true, transferAmount: true },
      }),
      this.prisma.saleReturn.findMany({
        where: { storeId, clientCreatedAt: range },
        select: { cashRefundVnd: true, transferRefundVnd: true },
      }),
      this.prisma.cashVoucher.findMany({
        where: { storeId, clientCreatedAt: range },
        select: { direction: true, channel: true, amountVnd: true },
      }),
      this.prisma.debtLedgerEntry.findMany({
        where: { storeId, type: 'payment', clientCreatedAt: range },
        select: { paymentMethod: true, amountVnd: true },
      }),
      this.prisma.supplierPayment.findMany({
        where: { storeId, clientCreatedAt: range },
        select: { channel: true, amountVnd: true },
      }),
      this.prisma.journalLine.findMany({
        where: {
          accountCode: CASH_ACCOUNT_CODE,
          entry: { storeId, postedAt: range },
        },
        select: { debitVnd: true, creditVnd: true },
      }),
    ]);

    const totals = computeCashFundTotals({
      sales,
      saleReturns,
      vouchers,
      debtPayments,
      supplierPayments,
    });
    const ledgerNetCashVnd = sumLedgerMovement(ledgerCashLines);
    return {
      storeId,
      from,
      to,
      ...totals,
      ledgerAccountCode: CASH_ACCOUNT_CODE,
      ledgerNetCashVnd,
      ledgerDiffVnd: totals.netCashVnd - ledgerNetCashVnd,
    };
  }

  /** RFC4180-ish CSV parse with quoted fields. */
  private parseCsvRows(csv: string): string[][] {
    const rows: string[][] = [];
    let row: string[] = [];
    let field = '';
    let inQuotes = false;
    for (let i = 0; i < csv.length; i++) {
      const ch = csv[i];
      if (inQuotes) {
        if (ch === '"') {
          if (csv[i + 1] === '"') {
            field += '"';
            i++;
          } else {
            inQuotes = false;
          }
        } else {
          field += ch;
        }
        continue;
      }
      if (ch === '"') {
        inQuotes = true;
        continue;
      }
      if (ch === ',' || ch === ';') {
        row.push(field.trim());
        field = '';
        continue;
      }
      if (ch === '\n') {
        row.push(field.trim());
        field = '';
        if (row.some((c) => c.length > 0)) rows.push(row);
        row = [];
        continue;
      }
      if (ch === '\r') continue;
      field += ch;
    }
    row.push(field.trim());
    if (row.some((c) => c.length > 0)) rows.push(row);
    return rows;
  }

  private statementFingerprint(input: {
    storeId: string;
    periodYm: string;
    bookedAt: Date;
    amountVnd: number;
    memo: string | null;
  }): string {
    const raw = [
      input.storeId,
      input.periodYm,
      input.bookedAt.toISOString(),
      String(input.amountVnd),
      input.memo ?? '',
    ].join('|');
    return createHash('sha256').update(raw).digest('hex');
  }

  private apStatementFingerprint(input: {
    storeId: string;
    supplierId: string;
    periodYm: string;
    bookedAt: Date;
    amountVnd: number;
    memo: string | null;
  }): string {
    const raw = [
      input.storeId,
      input.supplierId,
      input.periodYm,
      input.bookedAt.toISOString(),
      String(input.amountVnd),
      input.memo ?? '',
    ].join('|');
    return createHash('sha256').update(raw).digest('hex');
  }

  /**
   * Import CSV lines: date,amountVnd,memo (header optional).
   * date = YYYY-MM-DD; amount positive = store inbound transfer.
   * Idempotent via fingerprint unique constraint.
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
    if (csv.length > 2_000_000) {
      throw new BadRequestException('csv_too_large');
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
      fingerprint: string;
    }[] = [];
    const seen = new Set<string>();
    for (const parts of this.parseCsvRows(csv)) {
      if (parts.length < 2) continue;
      if (/^date$/i.test(parts[0])) continue;
      const bookedAt = new Date(`${parts[0]}T12:00:00.000Z`);
      const amountVnd = Number(parts[1]);
      if (Number.isNaN(bookedAt.getTime()) || !Number.isSafeInteger(amountVnd)) {
        continue;
      }
      if (periodYmFromDate(bookedAt) !== periodYm) {
        continue;
      }
      const memo = parts[2] || null;
      const fingerprint = this.statementFingerprint({
        storeId,
        periodYm,
        bookedAt,
        amountVnd,
        memo,
      });
      if (seen.has(fingerprint)) continue;
      seen.add(fingerprint);
      lines.push({
        id: randomUUID(),
        storeId,
        bankAccountId: bankAccountId ?? null,
        periodYm,
        bookedAt,
        amountVnd,
        memo,
        fingerprint,
      });
    }
    if (lines.length === 0) {
      throw new BadRequestException('no_valid_statement_lines');
    }
    const result = await this.prisma.bankStatementLine.createMany({
      data: lines,
      skipDuplicates: true,
    });
    return {
      imported: result.count,
      skippedDuplicates: lines.length - result.count,
      periodYm,
    };
  }

  private async loadBankBook(
    storeId: string,
    periodYm: string,
  ): Promise<
    { ref: string; kind: string; amountVnd: number; at: string; memo: string }[]
  > {
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
    return [
      ...sales.map((s) => ({
        ref: `sale:${s.id}`,
        kind: 'sale_transfer',
        amountVnd: s.transferAmount,
        at: s.clientCreatedAt.toISOString(),
        memo: s.id.slice(0, 8),
      })),
      ...vouchers.map((v) => ({
        ref: `voucher:${v.id}`,
        kind: `voucher_${v.direction}`,
        amountVnd: v.direction === 'in' ? v.amountVnd : -v.amountVnd,
        at: v.clientCreatedAt.toISOString(),
        memo: v.note ?? v.id.slice(0, 8),
      })),
      ...supplierPays.map((p) => ({
        ref: `supplier_pay:${p.id}`,
        kind: 'supplier_payment',
        amountVnd: -p.amountVnd,
        at: p.clientCreatedAt.toISOString(),
        memo: p.note ?? p.id.slice(0, 8),
      })),
    ];
  }

  /**
   * Score book↔statement candidates: amount exact + date window + memo overlap.
   * Higher is better; < 0 means reject.
   */
  private matchScore(
    st: { amountVnd: number; bookedAt: Date; memo: string | null },
    book: { amountVnd: number; at: string; memo: string; ref: string },
  ): number {
    if (st.amountVnd !== book.amountVnd) return -1;
    const bookAt = new Date(book.at).getTime();
    const stAt = st.bookedAt.getTime();
    const dayMs = 86_400_000;
    const days = Math.abs(stAt - bookAt) / dayMs;
    // Same calendar period is already enforced by loaders; allow full-month window.
    if (days > 40) return -1;
    let score = 100 - Math.min(days, 30) * 2;
    const memo = (st.memo ?? '').toLowerCase();
    if (memo && book.memo && memo.includes(book.memo.toLowerCase())) {
      score += 30;
    }
    if (memo && book.ref && memo.includes(book.ref.split(':')[1]?.slice(0, 8))) {
      score += 20;
    }
    return score;
  }

  private computeMatches(
    statements: {
      id: string;
      amountVnd: number;
      bookedAt: Date;
      memo: string | null;
      matchedRef: string | null;
    }[],
    book: { ref: string; kind: string; amountVnd: number; at: string; memo: string }[],
  ) {
    const unmatchedBook = [...book];
    const matched: {
      statementId: string;
      bookRef: string;
      amountVnd: number;
      suggested: boolean;
    }[] = [];
    // Honor persisted matches first
    for (const st of statements) {
      if (!st.matchedRef) continue;
      const idx = unmatchedBook.findIndex((b) => b.ref === st.matchedRef);
      if (idx >= 0) {
        const [b] = unmatchedBook.splice(idx, 1);
        matched.push({
          statementId: st.id,
          bookRef: b.ref,
          amountVnd: st.amountVnd,
          suggested: false,
        });
      }
    }
    // Suggest remaining by score
    const unmatchedSt = statements.filter(
      (s) => !matched.some((m) => m.statementId === s.id),
    );
    for (const st of unmatchedSt) {
      let bestIdx = -1;
      let bestScore = -1;
      for (let i = 0; i < unmatchedBook.length; i++) {
        const score = this.matchScore(st, unmatchedBook[i]);
        if (score > bestScore) {
          bestScore = score;
          bestIdx = i;
        }
      }
      if (bestIdx >= 0 && bestScore >= 50) {
        const [b] = unmatchedBook.splice(bestIdx, 1);
        matched.push({
          statementId: st.id,
          bookRef: b.ref,
          amountVnd: st.amountVnd,
          suggested: true,
        });
      }
    }
    return { matched, unmatchedBook };
  }

  /** Read-only summary — never mutates matchedRef. */
  async bankReconSummary(user: AuthUser, storeId: string, periodYm: string) {
    this.assertStoreAccess(user, storeId);
    if (user.role !== Role.owner && user.role !== Role.store_manager) {
      throw new ForbiddenException('forbidden');
    }
    if (!/^\d{4}-\d{2}$/.test(periodYm)) {
      throw new BadRequestException('periodYm must be YYYY-MM');
    }
    const book = await this.loadBankBook(storeId, periodYm);
    const statements = await this.prisma.bankStatementLine.findMany({
      where: { storeId, periodYm },
      orderBy: { bookedAt: 'asc' },
    });
    const lock = await this.prisma.bankReconLock.findUnique({
      where: { storeId_periodYm: { storeId, periodYm } },
    });
    const bookTotal = book.reduce((s, b) => s + b.amountVnd, 0);
    const statementTotal = statements.reduce((s, l) => s + l.amountVnd, 0);
    const { matched, unmatchedBook } = this.computeMatches(statements, book);
    const persistedMatched = matched.filter((m) => !m.suggested);
    const unmatchedStatementCount =
      statements.length - persistedMatched.length;

    return {
      storeId,
      periodYm,
      locked: !!lock,
      bookTotalVnd: bookTotal,
      statementTotalVnd: statementTotal,
      varianceVnd: statementTotal - bookTotal,
      matchedCount: persistedMatched.length,
      suggestedMatchCount: matched.filter((m) => m.suggested).length,
      unmatchedBookCount: unmatchedBook.length,
      unmatchedStatementCount,
      book,
      statements,
      matched,
      unmatchedBook,
    };
  }

  async matchBankLine(
    user: AuthUser,
    input: {
      storeId: string;
      periodYm: string;
      statementId: string;
      bookRef: string;
      matchVersion?: number;
    },
  ) {
    this.assertStoreAccess(user, input.storeId);
    if (user.role !== Role.owner && user.role !== Role.store_manager) {
      throw new ForbiddenException('forbidden');
    }
    const lock = await this.prisma.bankReconLock.findUnique({
      where: {
        storeId_periodYm: {
          storeId: input.storeId,
          periodYm: input.periodYm,
        },
      },
    });
    if (lock) throw new BadRequestException('bank_recon_locked');
    const st = await this.prisma.bankStatementLine.findUnique({
      where: { id: input.statementId },
    });
    if (!st || st.storeId !== input.storeId || st.periodYm !== input.periodYm) {
      throw new BadRequestException('statement_not_found');
    }
    if (
      input.matchVersion != null &&
      st.matchVersion !== input.matchVersion
    ) {
      throw new BadRequestException('match_version_conflict');
    }
    const book = await this.loadBankBook(input.storeId, input.periodYm);
    const bookLine = book.find((b) => b.ref === input.bookRef);
    if (!bookLine) throw new BadRequestException('book_ref_not_found');
    if (bookLine.amountVnd !== st.amountVnd) {
      throw new BadRequestException('amount_mismatch');
    }
    const taken = await this.prisma.bankStatementLine.findFirst({
      where: {
        storeId: input.storeId,
        periodYm: input.periodYm,
        matchedRef: input.bookRef,
        NOT: { id: st.id },
      },
    });
    if (taken) throw new BadRequestException('book_ref_already_matched');
    return this.prisma.bankStatementLine.update({
      where: { id: st.id },
      data: {
        matchedRef: input.bookRef,
        matchVersion: { increment: 1 },
      },
    });
  }

  async unmatchBankLine(
    user: AuthUser,
    input: {
      storeId: string;
      periodYm: string;
      statementId: string;
      matchVersion?: number;
    },
  ) {
    this.assertStoreAccess(user, input.storeId);
    if (user.role !== Role.owner && user.role !== Role.store_manager) {
      throw new ForbiddenException('forbidden');
    }
    const lock = await this.prisma.bankReconLock.findUnique({
      where: {
        storeId_periodYm: {
          storeId: input.storeId,
          periodYm: input.periodYm,
        },
      },
    });
    if (lock) throw new BadRequestException('bank_recon_locked');
    const st = await this.prisma.bankStatementLine.findUnique({
      where: { id: input.statementId },
    });
    if (!st || st.storeId !== input.storeId || st.periodYm !== input.periodYm) {
      throw new BadRequestException('statement_not_found');
    }
    if (
      input.matchVersion != null &&
      st.matchVersion !== input.matchVersion
    ) {
      throw new BadRequestException('match_version_conflict');
    }
    return this.prisma.bankStatementLine.update({
      where: { id: st.id },
      data: { matchedRef: null, matchVersion: { increment: 1 } },
    });
  }

  /** Persist high-confidence suggested matches. */
  async autoMatchBankRecon(
    user: AuthUser,
    storeId: string,
    periodYm: string,
  ) {
    const summary = await this.bankReconSummary(user, storeId, periodYm);
    if (summary.locked) throw new BadRequestException('bank_recon_locked');
    let applied = 0;
    for (const m of summary.matched) {
      if (!m.suggested) continue;
      await this.matchBankLine(user, {
        storeId,
        periodYm,
        statementId: m.statementId,
        bookRef: m.bookRef,
      });
      applied += 1;
    }
    return { applied };
  }

  async lockBankRecon(user: AuthUser, storeId: string, periodYm: string) {
    this.assertStoreAccess(user, storeId);
    if (user.role !== Role.owner && user.role !== Role.store_manager) {
      throw new ForbiddenException('forbidden');
    }
    if (!/^\d{4}-\d{2}$/.test(periodYm)) {
      throw new BadRequestException('periodYm must be YYYY-MM');
    }
    const summary = await this.bankReconSummary(user, storeId, periodYm);
    if (summary.varianceVnd !== 0) {
      throw new BadRequestException('bank_recon_variance_nonzero');
    }
    if (
      summary.unmatchedStatementCount > 0 ||
      summary.unmatchedBookCount > 0
    ) {
      // Allow lock if suggestions cover everything — auto-apply first
      if (
        summary.suggestedMatchCount > 0 &&
        summary.matchedCount + summary.suggestedMatchCount ===
          summary.statements.length &&
        summary.unmatchedBookCount === 0
      ) {
        await this.autoMatchBankRecon(user, storeId, periodYm);
        const again = await this.bankReconSummary(user, storeId, periodYm);
        if (
          again.unmatchedStatementCount > 0 ||
          again.unmatchedBookCount > 0 ||
          again.varianceVnd !== 0
        ) {
          throw new BadRequestException('bank_recon_unmatched_remaining');
        }
      } else {
        throw new BadRequestException('bank_recon_unmatched_remaining');
      }
    }
    const lock = await this.prisma.bankReconLock.upsert({
      where: { storeId_periodYm: { storeId, periodYm } },
      create: {
        id: randomUUID(),
        storeId,
        periodYm,
        lockedById: user.userId,
      },
      update: {},
    });
    await this.prisma.auditLog.create({
      data: {
        id: randomUUID(),
        actorUserId: user.userId,
        action: 'bank_recon_locked',
        entityType: 'bank_recon',
        entityId: `${storeId}:${periodYm}`,
        detailJson: JSON.stringify({
          varianceVnd: summary.varianceVnd,
          matchedCount: summary.matchedCount,
        }),
      },
    });
    return lock;
  }

  /**
   * Import CSV supplier AP statement lines: date,amountVnd,memo (header optional).
   * Positive amounts are new payable lines; negative amounts are supplier payments.
   */
  async importApStatement(
    user: AuthUser,
    storeId: string,
    supplierId: string,
    periodYm: string,
    csv: string,
  ) {
    this.assertStoreAccess(user, storeId);
    if (user.role !== Role.owner && user.role !== Role.store_manager) {
      throw new ForbiddenException('forbidden');
    }
    if (!/^\d{4}-\d{2}$/.test(periodYm)) {
      throw new BadRequestException('periodYm must be YYYY-MM');
    }
    if (csv.length > 2_000_000) {
      throw new BadRequestException('csv_too_large');
    }
    const supplier = await this.prisma.supplier.findUnique({
      where: { id: supplierId },
    });
    if (!supplier || !supplier.active) {
      throw new BadRequestException('supplier_not_found');
    }
    const lock = await this.prisma.apReconLock.findUnique({
      where: { storeId_supplierId_periodYm: { storeId, supplierId, periodYm } },
    });
    if (lock) {
      throw new BadRequestException('ap_recon_locked');
    }
    const lines: {
      id: string;
      storeId: string;
      supplierId: string;
      periodYm: string;
      bookedAt: Date;
      amountVnd: number;
      memo: string | null;
      fingerprint: string;
    }[] = [];
    const seen = new Set<string>();
    for (const parts of this.parseCsvRows(csv)) {
      if (parts.length < 2) continue;
      if (/^date$/i.test(parts[0])) continue;
      const bookedAt = new Date(`${parts[0]}T12:00:00.000Z`);
      const amountVnd = Number(parts[1]);
      if (Number.isNaN(bookedAt.getTime()) || !Number.isSafeInteger(amountVnd)) {
        continue;
      }
      if (amountVnd === 0 || periodYmFromDate(bookedAt) !== periodYm) {
        continue;
      }
      const memo = parts[2] || null;
      const fingerprint = this.apStatementFingerprint({
        storeId,
        supplierId,
        periodYm,
        bookedAt,
        amountVnd,
        memo,
      });
      if (seen.has(fingerprint)) continue;
      seen.add(fingerprint);
      lines.push({
        id: randomUUID(),
        storeId,
        supplierId,
        periodYm,
        bookedAt,
        amountVnd,
        memo,
        fingerprint,
      });
    }
    if (lines.length === 0) {
      throw new BadRequestException('no_valid_statement_lines');
    }
    const result = await this.prisma.apStatementLine.createMany({
      data: lines,
      skipDuplicates: true,
    });
    return {
      imported: result.count,
      skippedDuplicates: lines.length - result.count,
      periodYm,
      supplierId,
    };
  }

  private async loadApBook(
    storeId: string,
    supplierId: string,
    periodYm: string,
  ): Promise<
    { ref: string; kind: string; amountVnd: number; at: string; memo: string }[]
  > {
    const [y, m] = periodYm.split('-').map(Number);
    const from = new Date(Date.UTC(y, m - 1, 1) - 7 * 3600_000);
    const to = new Date(Date.UTC(y, m, 1) - 7 * 3600_000 - 1);
    const [payables, payments] = await Promise.all([
      this.prisma.supplierPayable.findMany({
        where: {
          storeId,
          supplierId,
          clientCreatedAt: { gte: from, lte: to },
        },
      }),
      this.prisma.supplierPayment.findMany({
        where: {
          storeId,
          supplierId,
          clientCreatedAt: { gte: from, lte: to },
        },
      }),
    ]);
    return [
      ...payables.map((p) => ({
        ref: `supplier_payable:${p.id}`,
        kind: 'supplier_payable',
        amountVnd: p.amountVnd,
        at: p.clientCreatedAt.toISOString(),
        memo: p.purchaseReceiptId ?? p.id.slice(0, 8),
      })),
      ...payments.map((p) => ({
        ref: `supplier_pay:${p.id}`,
        kind: `supplier_payment_${p.channel}`,
        amountVnd: -p.amountVnd,
        at: p.clientCreatedAt.toISOString(),
        memo: p.note ?? p.id.slice(0, 8),
      })),
    ];
  }

  /** Read-only AP recon summary — never mutates matchedRef. */
  async apReconSummary(
    user: AuthUser,
    storeId: string,
    supplierId: string,
    periodYm: string,
  ) {
    this.assertStoreAccess(user, storeId);
    if (user.role !== Role.owner && user.role !== Role.store_manager) {
      throw new ForbiddenException('forbidden');
    }
    if (!/^\d{4}-\d{2}$/.test(periodYm)) {
      throw new BadRequestException('periodYm must be YYYY-MM');
    }
    const supplier = await this.prisma.supplier.findUnique({
      where: { id: supplierId },
    });
    if (!supplier || !supplier.active) {
      throw new BadRequestException('supplier_not_found');
    }
    const book = await this.loadApBook(storeId, supplierId, periodYm);
    const statements = await this.prisma.apStatementLine.findMany({
      where: { storeId, supplierId, periodYm },
      orderBy: { bookedAt: 'asc' },
    });
    const lock = await this.prisma.apReconLock.findUnique({
      where: { storeId_supplierId_periodYm: { storeId, supplierId, periodYm } },
    });
    const bookTotal = book.reduce((s, b) => s + b.amountVnd, 0);
    const statementTotal = statements.reduce((s, l) => s + l.amountVnd, 0);
    const { matched, unmatchedBook } = this.computeMatches(statements, book);
    const persistedMatched = matched.filter((m) => !m.suggested);
    const unmatchedStatementCount =
      statements.length - persistedMatched.length;

    return {
      storeId,
      supplierId,
      supplierName: supplier.name,
      periodYm,
      locked: !!lock,
      bookTotalVnd: bookTotal,
      statementTotalVnd: statementTotal,
      varianceVnd: statementTotal - bookTotal,
      matchedCount: persistedMatched.length,
      suggestedMatchCount: matched.filter((m) => m.suggested).length,
      unmatchedBookCount: unmatchedBook.length,
      unmatchedStatementCount,
      book,
      statements,
      matched,
      unmatchedBook,
    };
  }

  async matchApLine(
    user: AuthUser,
    input: {
      storeId: string;
      supplierId: string;
      periodYm: string;
      statementId: string;
      bookRef: string;
      matchVersion?: number;
    },
  ) {
    this.assertStoreAccess(user, input.storeId);
    if (user.role !== Role.owner && user.role !== Role.store_manager) {
      throw new ForbiddenException('forbidden');
    }
    const lock = await this.prisma.apReconLock.findUnique({
      where: {
        storeId_supplierId_periodYm: {
          storeId: input.storeId,
          supplierId: input.supplierId,
          periodYm: input.periodYm,
        },
      },
    });
    if (lock) throw new BadRequestException('ap_recon_locked');
    const st = await this.prisma.apStatementLine.findUnique({
      where: { id: input.statementId },
    });
    if (
      !st ||
      st.storeId !== input.storeId ||
      st.supplierId !== input.supplierId ||
      st.periodYm !== input.periodYm
    ) {
      throw new BadRequestException('statement_not_found');
    }
    if (
      input.matchVersion != null &&
      st.matchVersion !== input.matchVersion
    ) {
      throw new BadRequestException('match_version_conflict');
    }
    const book = await this.loadApBook(
      input.storeId,
      input.supplierId,
      input.periodYm,
    );
    const bookLine = book.find((b) => b.ref === input.bookRef);
    if (!bookLine) throw new BadRequestException('book_ref_not_found');
    if (bookLine.amountVnd !== st.amountVnd) {
      throw new BadRequestException('amount_mismatch');
    }
    const taken = await this.prisma.apStatementLine.findFirst({
      where: {
        storeId: input.storeId,
        supplierId: input.supplierId,
        periodYm: input.periodYm,
        matchedRef: input.bookRef,
        NOT: { id: st.id },
      },
    });
    if (taken) throw new BadRequestException('book_ref_already_matched');
    return this.prisma.apStatementLine.update({
      where: { id: st.id },
      data: {
        matchedRef: input.bookRef,
        matchVersion: { increment: 1 },
      },
    });
  }

  async unmatchApLine(
    user: AuthUser,
    input: {
      storeId: string;
      supplierId: string;
      periodYm: string;
      statementId: string;
      matchVersion?: number;
    },
  ) {
    this.assertStoreAccess(user, input.storeId);
    if (user.role !== Role.owner && user.role !== Role.store_manager) {
      throw new ForbiddenException('forbidden');
    }
    const lock = await this.prisma.apReconLock.findUnique({
      where: {
        storeId_supplierId_periodYm: {
          storeId: input.storeId,
          supplierId: input.supplierId,
          periodYm: input.periodYm,
        },
      },
    });
    if (lock) throw new BadRequestException('ap_recon_locked');
    const st = await this.prisma.apStatementLine.findUnique({
      where: { id: input.statementId },
    });
    if (
      !st ||
      st.storeId !== input.storeId ||
      st.supplierId !== input.supplierId ||
      st.periodYm !== input.periodYm
    ) {
      throw new BadRequestException('statement_not_found');
    }
    if (
      input.matchVersion != null &&
      st.matchVersion !== input.matchVersion
    ) {
      throw new BadRequestException('match_version_conflict');
    }
    return this.prisma.apStatementLine.update({
      where: { id: st.id },
      data: { matchedRef: null, matchVersion: { increment: 1 } },
    });
  }

  /** Persist high-confidence AP suggested matches. */
  async autoMatchApRecon(
    user: AuthUser,
    storeId: string,
    supplierId: string,
    periodYm: string,
  ) {
    const summary = await this.apReconSummary(user, storeId, supplierId, periodYm);
    if (summary.locked) throw new BadRequestException('ap_recon_locked');
    let applied = 0;
    for (const m of summary.matched) {
      if (!m.suggested) continue;
      await this.matchApLine(user, {
        storeId,
        supplierId,
        periodYm,
        statementId: m.statementId,
        bookRef: m.bookRef,
      });
      applied += 1;
    }
    return { applied };
  }

  async lockApRecon(
    user: AuthUser,
    storeId: string,
    supplierId: string,
    periodYm: string,
  ) {
    this.assertStoreAccess(user, storeId);
    if (user.role !== Role.owner && user.role !== Role.store_manager) {
      throw new ForbiddenException('forbidden');
    }
    if (!/^\d{4}-\d{2}$/.test(periodYm)) {
      throw new BadRequestException('periodYm must be YYYY-MM');
    }
    const summary = await this.apReconSummary(user, storeId, supplierId, periodYm);
    if (summary.varianceVnd !== 0) {
      throw new BadRequestException('ap_recon_variance_nonzero');
    }
    if (
      summary.unmatchedStatementCount > 0 ||
      summary.unmatchedBookCount > 0
    ) {
      if (
        summary.suggestedMatchCount > 0 &&
        summary.matchedCount + summary.suggestedMatchCount ===
          summary.statements.length &&
        summary.unmatchedBookCount === 0
      ) {
        await this.autoMatchApRecon(user, storeId, supplierId, periodYm);
        const again = await this.apReconSummary(
          user,
          storeId,
          supplierId,
          periodYm,
        );
        if (
          again.unmatchedStatementCount > 0 ||
          again.unmatchedBookCount > 0 ||
          again.varianceVnd !== 0
        ) {
          throw new BadRequestException('ap_recon_unmatched_remaining');
        }
      } else {
        throw new BadRequestException('ap_recon_unmatched_remaining');
      }
    }
    const lock = await this.prisma.apReconLock.upsert({
      where: { storeId_supplierId_periodYm: { storeId, supplierId, periodYm } },
      create: {
        id: randomUUID(),
        storeId,
        supplierId,
        periodYm,
        lockedById: user.userId,
      },
      update: {},
    });
    await this.prisma.auditLog.create({
      data: {
        id: randomUUID(),
        actorUserId: user.userId,
        action: 'ap_recon_locked',
        entityType: 'ap_recon',
        entityId: `${storeId}:${supplierId}:${periodYm}`,
        detailJson: JSON.stringify({
          varianceVnd: summary.varianceVnd,
          matchedCount: summary.matchedCount,
        }),
      },
    });
    return lock;
  }
}
