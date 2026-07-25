export type JournalLineDraft = {
  accountCode: string;
  debitVnd: number;
  creditVnd: number;
};

export function periodYmFromDate(d: Date): string {
  const ictOffsetMs = 7 * 60 * 60 * 1000;
  const ict = new Date(d.getTime() + ictOffsetMs);
  const y = ict.getUTCFullYear();
  const m = String(ict.getUTCMonth() + 1).padStart(2, '0');
  return `${y}-${m}`;
}

export function assertBalanced(lines: JournalLineDraft[]): void {
  const debit = lines.reduce((s, l) => s + l.debitVnd, 0);
  const credit = lines.reduce((s, l) => s + l.creditVnd, 0);
  if (debit !== credit) {
    throw new Error(`unbalanced_journal:${debit}:${credit}`);
  }
}

/** Split VAT-inclusive gross into net + VAT (VND integers). */
export function splitInclusiveVat(
  grossVnd: number,
  rateBps: number,
): { netVnd: number; vatVnd: number } {
  if (grossVnd <= 0 || rateBps <= 0) {
    return { netVnd: Math.max(0, grossVnd), vatVnd: 0 };
  }
  const netVnd = Math.round((grossVnd * 10000) / (10000 + rateBps));
  return { netVnd, vatVnd: grossVnd - netVnd };
}

function pushDr(
  lines: JournalLineDraft[],
  accountCode: string,
  amount: number,
) {
  if (amount > 0) {
    lines.push({ accountCode, debitVnd: amount, creditVnd: 0 });
  }
}

function pushCr(
  lines: JournalLineDraft[],
  accountCode: string,
  amount: number,
) {
  if (amount > 0) {
    lines.push({ accountCode, debitVnd: 0, creditVnd: amount });
  }
}

function cogsFromLines(
  lines: { qty: number; unitCostVnd: number | null }[],
): number {
  let cogs = 0;
  for (const line of lines) {
    if (line.unitCostVnd != null && line.unitCostVnd > 0 && line.qty > 0) {
      cogs += Math.round(line.qty * line.unitCostVnd);
    }
  }
  return cogs;
}

export type SaleVatLineInput = {
  qty: number;
  unitCostVnd: number | null;
  /** Gross line before sale-level discount allocation. */
  lineTotal?: number;
  /** Snapshot or product override; falls back to input.vatRateBps. */
  vatRateBps?: number | null;
  /** Prefer snapshot when present (post-sale / re-post). */
  netVnd?: number | null;
  vatVnd?: number | null;
};

/**
 * Allocate sale discount across gross lines by proportion; remainder to last line.
 */
export function allocateSaleDiscount(
  lineTotals: number[],
  discountVnd: number,
): number[] {
  if (lineTotals.length === 0) return [];
  const gross = lineTotals.reduce((s, n) => s + n, 0);
  if (discountVnd <= 0 || gross <= 0) {
    return [...lineTotals];
  }
  const disc = Math.min(discountVnd, gross);
  const out = new Array<number>(lineTotals.length);
  let allocatedDisc = 0;
  for (let i = 0; i < lineTotals.length - 1; i++) {
    const share = Math.round((lineTotals[i] * disc) / gross);
    out[i] = Math.max(0, lineTotals[i] - share);
    allocatedDisc += lineTotals[i] - out[i];
  }
  const last = lineTotals.length - 1;
  out[last] = Math.max(0, lineTotals[last] - (disc - allocatedDisc));
  return out;
}

/**
 * @param vatRateBps store default when VAT on; null = no VAT split (legacy)
 * Per-line rates via lines[].vatRateBps; discount allocated by gross lineTotal.
 */
export function buildSaleJournal(input: {
  cashAmount: number;
  transferAmount: number;
  debtAmount: number;
  totalVnd: number;
  discountVnd?: number;
  lines: SaleVatLineInput[];
  vatRateBps?: number | null;
}): JournalLineDraft[] {
  const out: JournalLineDraft[] = [];
  pushDr(out, '111', input.cashAmount);
  pushDr(out, '112', input.transferAmount);
  pushDr(out, '131', input.debtAmount);

  const hasAnyVat =
    input.lines.some(
      (l) =>
        (l.vatRateBps != null && l.vatRateBps > 0) ||
        (l.netVnd != null && l.vatVnd != null),
    ) ||
    (input.vatRateBps != null && input.vatRateBps > 0);

  if (hasAnyVat) {
    const snapshotsReady = input.lines.every(
      (l) => l.netVnd != null && l.vatVnd != null,
    );
    let netTotal = 0;
    let vatTotal = 0;
    if (snapshotsReady) {
      for (const l of input.lines) {
        netTotal += l.netVnd ?? 0;
        vatTotal += l.vatVnd ?? 0;
      }
    } else {
      const lineTotals = input.lines.map((l) =>
        l.lineTotal != null && l.lineTotal > 0
          ? l.lineTotal
          : 0,
      );
      const sumLines = lineTotals.reduce((s, n) => s + n, 0);
      const discount =
        input.discountVnd != null && input.discountVnd > 0
          ? input.discountVnd
          : sumLines > input.totalVnd
            ? sumLines - input.totalVnd
            : 0;
      const afterDisc =
        sumLines > 0
          ? allocateSaleDiscount(lineTotals, discount)
          : [input.totalVnd];
      const rates = input.lines.map((l) =>
        l.vatRateBps != null && l.vatRateBps > 0
          ? l.vatRateBps
          : input.vatRateBps != null && input.vatRateBps > 0
            ? input.vatRateBps
            : 0,
      );
      if (sumLines <= 0) {
        const rate = input.vatRateBps != null && input.vatRateBps > 0
          ? input.vatRateBps
          : 0;
        if (rate > 0) {
          const split = splitInclusiveVat(input.totalVnd, rate);
          netTotal = split.netVnd;
          vatTotal = split.vatVnd;
        } else {
          netTotal = input.totalVnd;
        }
      } else {
        for (let i = 0; i < afterDisc.length; i++) {
          const gross = afterDisc[i];
          const rate = rates[i] ?? 0;
          if (rate > 0) {
            const split = splitInclusiveVat(gross, rate);
            netTotal += split.netVnd;
            vatTotal += split.vatVnd;
          } else {
            netTotal += gross;
          }
        }
      }
    }
    // Align to payment total (cash+transfer+debt) for VND remainder
    const paid =
      input.cashAmount + input.transferAmount + input.debtAmount;
    const splitSum = netTotal + vatTotal;
    if (paid > 0 && splitSum !== paid) {
      const delta = paid - splitSum;
      netTotal += delta;
    }
    pushCr(out, '511', netTotal);
    pushCr(out, '3331', vatTotal);
  } else {
    pushCr(out, '511', input.totalVnd);
  }
  const cogs = cogsFromLines(input.lines);
  pushDr(out, '632', cogs);
  pushCr(out, '156', cogs);
  assertBalanced(out);
  return out;
}

export function buildDebtPaymentJournal(input: {
  amountVnd: number;
  paymentMethod: 'cash' | 'transfer' | string;
}): JournalLineDraft[] {
  const out: JournalLineDraft[] = [];
  const cashAcct = input.paymentMethod === 'transfer' ? '112' : '111';
  pushDr(out, cashAcct, input.amountVnd);
  pushCr(out, '131', input.amountVnd);
  assertBalanced(out);
  return out;
}

export function buildCashVoucherJournal(input: {
  direction: 'in' | 'out' | string;
  channel: 'cash' | 'transfer' | string;
  amountVnd: number;
}): JournalLineDraft[] {
  const out: JournalLineDraft[] = [];
  const cashAcct = input.channel === 'transfer' ? '112' : '111';
  if (input.direction === 'in') {
    pushDr(out, cashAcct, input.amountVnd);
    pushCr(out, '711', input.amountVnd);
  } else {
    pushDr(out, '642', input.amountVnd);
    pushCr(out, cashAcct, input.amountVnd);
  }
  assertBalanced(out);
  return out;
}

/**
 * Purchase lines use VAT-inclusive unitCostVnd.
 * When vatRateBps > 0, inventory (156) is net; input VAT to 1331; AP (331) is gross.
 * Per-line rate via line.vatRateBps, else input.vatRateBps.
 */
export function buildPurchaseJournal(input: {
  lines: {
    qty: number;
    unitCostVnd: number | null;
    vatRateBps?: number | null;
  }[];
  vatRateBps?: number | null;
}): JournalLineDraft[] {
  let inventoryNet = 0;
  let inputVat = 0;
  let apGross = 0;
  for (const line of input.lines) {
    if (line.unitCostVnd == null || line.unitCostVnd <= 0 || line.qty <= 0) {
      continue;
    }
    const gross = Math.round(line.qty * line.unitCostVnd);
    apGross += gross;
    const rate =
      line.vatRateBps != null && line.vatRateBps > 0
        ? line.vatRateBps
        : input.vatRateBps != null && input.vatRateBps > 0
          ? input.vatRateBps
          : null;
    if (rate != null) {
      const { netVnd, vatVnd } = splitInclusiveVat(gross, rate);
      inventoryNet += netVnd;
      inputVat += vatVnd;
    } else {
      inventoryNet += gross;
    }
  }
  if (apGross <= 0) {
    return [];
  }
  const out: JournalLineDraft[] = [];
  pushDr(out, '156', inventoryNet);
  pushDr(out, '1331', inputVat);
  pushCr(out, '331', apGross);
  assertBalanced(out);
  return out;
}

/**
 * Reverse purchase: Dr 331 gross; Cr 156 net (+ Cr 1331 vat when rate set).
 * unitCostVnd on lines is VAT-inclusive gross (same as purchase).
 */
export function buildPurchaseReturnJournal(input: {
  lines: {
    qty: number;
    unitCostVnd: number | null;
    vatRateBps?: number | null;
  }[];
  vatRateBps?: number | null;
}): JournalLineDraft[] {
  let inventoryNet = 0;
  let inputVat = 0;
  let apGross = 0;
  for (const line of input.lines) {
    if (line.unitCostVnd == null || line.unitCostVnd <= 0 || line.qty <= 0) {
      continue;
    }
    const gross = Math.round(line.qty * line.unitCostVnd);
    apGross += gross;
    const rate =
      line.vatRateBps != null && line.vatRateBps > 0
        ? line.vatRateBps
        : input.vatRateBps != null && input.vatRateBps > 0
          ? input.vatRateBps
          : null;
    if (rate != null) {
      const { netVnd, vatVnd } = splitInclusiveVat(gross, rate);
      inventoryNet += netVnd;
      inputVat += vatVnd;
    } else {
      inventoryNet += gross;
    }
  }
  if (apGross <= 0) {
    return [];
  }
  const out: JournalLineDraft[] = [];
  pushDr(out, '331', apGross);
  pushCr(out, '156', inventoryNet);
  pushCr(out, '1331', inputVat);
  assertBalanced(out);
  return out;
}

/** Pay AP: Dr 331 / Cr cash channel. */
export function buildSupplierPaymentJournal(input: {
  amountVnd: number;
  channel: 'cash' | 'transfer' | string;
}): JournalLineDraft[] {
  const out: JournalLineDraft[] = [];
  const cashAcct = input.channel === 'transfer' ? '112' : '111';
  pushDr(out, '331', input.amountVnd);
  pushCr(out, cashAcct, input.amountVnd);
  assertBalanced(out);
  return out;
}

export function purchaseAmountFromLines(
  lines: { qty: number; unitCostVnd: number | null }[],
): number {
  let amount = 0;
  for (const line of lines) {
    if (line.unitCostVnd != null && line.unitCostVnd > 0 && line.qty > 0) {
      amount += Math.round(line.qty * line.unitCostVnd);
    }
  }
  return amount;
}

/** Reverse sale: Dr 511 (+3331 if VAT) / Cr cash channels; reverse COGS. */
export function buildSaleReturnJournal(input: {
  cashRefundVnd: number;
  transferRefundVnd: number;
  debtCreditVnd: number;
  totalRefundVnd: number;
  lines: SaleVatLineInput[];
  vatRateBps?: number | null;
}): JournalLineDraft[] {
  const out: JournalLineDraft[] = [];
  const hasAnyVat =
    input.lines.some(
      (l) =>
        (l.vatRateBps != null && l.vatRateBps > 0) ||
        (l.netVnd != null && l.vatVnd != null),
    ) ||
    (input.vatRateBps != null && input.vatRateBps > 0);

  if (hasAnyVat) {
    const snapshotsReady = input.lines.every(
      (l) => l.netVnd != null && l.vatVnd != null,
    );
    let netTotal = 0;
    let vatTotal = 0;
    if (snapshotsReady) {
      for (const l of input.lines) {
        netTotal += l.netVnd ?? 0;
        vatTotal += l.vatVnd ?? 0;
      }
    } else {
      const lineTotals = input.lines.map((l) => l.lineTotal ?? 0);
      const sumLines = lineTotals.reduce((s, n) => s + n, 0);
      const afterDisc =
        sumLines > 0 ? lineTotals : [input.totalRefundVnd];
      for (let i = 0; i < afterDisc.length; i++) {
        const gross = afterDisc[i];
        const rate =
          input.lines[i]?.vatRateBps != null &&
          (input.lines[i].vatRateBps as number) > 0
            ? (input.lines[i].vatRateBps as number)
            : input.vatRateBps != null && input.vatRateBps > 0
              ? input.vatRateBps
              : 0;
        if (rate > 0) {
          const split = splitInclusiveVat(gross, rate);
          netTotal += split.netVnd;
          vatTotal += split.vatVnd;
        } else {
          netTotal += gross;
        }
      }
      if (sumLines <= 0 && input.vatRateBps != null && input.vatRateBps > 0) {
        const split = splitInclusiveVat(
          input.totalRefundVnd,
          input.vatRateBps,
        );
        netTotal = split.netVnd;
        vatTotal = split.vatVnd;
      }
    }
    const refunded =
      input.cashRefundVnd +
      input.transferRefundVnd +
      input.debtCreditVnd;
    const splitSum = netTotal + vatTotal;
    if (refunded > 0 && splitSum !== refunded) {
      netTotal += refunded - splitSum;
    }
    pushDr(out, '511', netTotal);
    pushDr(out, '3331', vatTotal);
  } else {
    pushDr(out, '511', input.totalRefundVnd);
  }
  pushCr(out, '111', input.cashRefundVnd);
  pushCr(out, '112', input.transferRefundVnd);
  pushCr(out, '131', input.debtCreditVnd);
  const cogs = cogsFromLines(input.lines);
  pushDr(out, '156', cogs);
  pushCr(out, '632', cogs);
  assertBalanced(out);
  return out;
}

/** Compute per-line VAT snapshots for a sale (after discount allocation). */
export function computeSaleLineVatSnapshots(input: {
  lines: { lineTotal: number; vatRateBps?: number | null }[];
  discountVnd: number;
  storeVatRateBps: number | null;
}): { vatRateBps: number | null; netVnd: number; vatVnd: number }[] {
  const rates = input.lines.map((l) =>
    l.vatRateBps != null && l.vatRateBps > 0
      ? l.vatRateBps
      : input.storeVatRateBps != null && input.storeVatRateBps > 0
        ? input.storeVatRateBps
        : null,
  );
  const after = allocateSaleDiscount(
    input.lines.map((l) => l.lineTotal),
    input.discountVnd,
  );
  return after.map((gross, i) => {
    const rate = rates[i];
    if (rate == null) {
      return { vatRateBps: null, netVnd: gross, vatVnd: 0 };
    }
    const split = splitInclusiveVat(gross, rate);
    return {
      vatRateBps: rate,
      netVnd: split.netVnd,
      vatVnd: split.vatVnd,
    };
  });
}

/**
 * Stocktake variance at WAC.
 * Increase: Dr 156 / Cr 711; decrease: Dr 642 / Cr 156.
 */
export function buildStocktakeJournal(input: {
  lines: { varianceQty: number; avgCostVnd: number | null }[];
}): JournalLineDraft[] {
  let increase = 0;
  let decrease = 0;
  for (const line of input.lines) {
    if (line.avgCostVnd == null || line.avgCostVnd <= 0) continue;
    if (line.varianceQty > 0) {
      increase += Math.round(line.varianceQty * line.avgCostVnd);
    } else if (line.varianceQty < 0) {
      decrease += Math.round(Math.abs(line.varianceQty) * line.avgCostVnd);
    }
  }
  if (increase <= 0 && decrease <= 0) {
    return [];
  }
  const out: JournalLineDraft[] = [];
  if (increase > 0) {
    pushDr(out, '156', increase);
    pushCr(out, '711', increase);
  }
  if (decrease > 0) {
    pushDr(out, '642', decrease);
    pushCr(out, '156', decrease);
  }
  assertBalanced(out);
  return out;
}

/** Wastage decreases inventory at WAC: Dr 642 / Cr 156. */
export function buildWastageJournal(input: {
  lines: { qty: number; avgCostVnd: number | null }[];
}): JournalLineDraft[] {
  let total = 0;
  for (const line of input.lines) {
    if (line.avgCostVnd == null || line.avgCostVnd <= 0) continue;
    total += Math.round(line.qty * line.avgCostVnd);
  }
  if (total <= 0) {
    return [];
  }
  const out: JournalLineDraft[] = [];
  pushDr(out, '642', total);
  pushCr(out, '156', total);
  assertBalanced(out);
  return out;
}
