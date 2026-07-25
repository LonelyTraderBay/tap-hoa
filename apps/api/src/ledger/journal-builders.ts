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

/**
 * @param vatRateBps null/undefined = no VAT split (legacy Epic 2 mapping)
 */
export function buildSaleJournal(input: {
  cashAmount: number;
  transferAmount: number;
  debtAmount: number;
  totalVnd: number;
  lines: { qty: number; unitCostVnd: number | null }[];
  vatRateBps?: number | null;
}): JournalLineDraft[] {
  const out: JournalLineDraft[] = [];
  pushDr(out, '111', input.cashAmount);
  pushDr(out, '112', input.transferAmount);
  pushDr(out, '131', input.debtAmount);
  if (input.vatRateBps != null && input.vatRateBps > 0) {
    const { netVnd, vatVnd } = splitInclusiveVat(
      input.totalVnd,
      input.vatRateBps,
    );
    pushCr(out, '511', netVnd);
    pushCr(out, '3331', vatVnd);
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
  lines: { qty: number; unitCostVnd: number | null }[];
  vatRateBps?: number | null;
}): JournalLineDraft[] {
  const out: JournalLineDraft[] = [];
  if (input.vatRateBps != null && input.vatRateBps > 0) {
    const { netVnd, vatVnd } = splitInclusiveVat(
      input.totalRefundVnd,
      input.vatRateBps,
    );
    pushDr(out, '511', netVnd);
    pushDr(out, '3331', vatVnd);
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
