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

export function buildSaleJournal(input: {
  cashAmount: number;
  transferAmount: number;
  debtAmount: number;
  totalVnd: number;
  lines: { qty: number; unitCostVnd: number | null }[];
}): JournalLineDraft[] {
  const out: JournalLineDraft[] = [];
  pushDr(out, '111', input.cashAmount);
  pushDr(out, '112', input.transferAmount);
  pushDr(out, '131', input.debtAmount);
  pushCr(out, '511', input.totalVnd);
  let cogs = 0;
  for (const line of input.lines) {
    if (line.unitCostVnd != null && line.unitCostVnd > 0 && line.qty > 0) {
      cogs += Math.round(line.qty * line.unitCostVnd);
    }
  }
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

export function buildPurchaseJournal(input: {
  lines: { qty: number; unitCostVnd: number | null }[];
}): JournalLineDraft[] {
  let amount = 0;
  for (const line of input.lines) {
    if (line.unitCostVnd != null && line.unitCostVnd > 0 && line.qty > 0) {
      amount += Math.round(line.qty * line.unitCostVnd);
    }
  }
  if (amount <= 0) {
    return [];
  }
  const out: JournalLineDraft[] = [];
  pushDr(out, '156', amount);
  pushCr(out, '331', amount);
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
