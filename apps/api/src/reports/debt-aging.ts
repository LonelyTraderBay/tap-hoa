/** FIFO debt aging: cover sale_debt with payments in chronological order. */

export type DebtLedgerRow = {
  type: 'sale_debt' | 'payment' | 'sale_return_credit' | string;
  amountVnd: number;
  clientCreatedAt: Date;
};

export type DebtAgingResult = {
  oldestUnpaidAt: Date | null;
  daysOutstanding: number;
  overdue: boolean;
};

export function ictDayDiff(from: Date, to: Date): number {
  const ictOffsetMs = 7 * 60 * 60 * 1000;
  const start = Date.UTC(
    from.getUTCFullYear(),
    from.getUTCMonth(),
    from.getUTCDate(),
  );
  const end = Date.UTC(to.getUTCFullYear(), to.getUTCMonth(), to.getUTCDate());
  // Convert to ICT calendar days via offset on the instant
  const fromIct = new Date(from.getTime() + ictOffsetMs);
  const toIct = new Date(to.getTime() + ictOffsetMs);
  const a = Date.UTC(fromIct.getUTCFullYear(), fromIct.getUTCMonth(), fromIct.getUTCDate());
  const b = Date.UTC(toIct.getUTCFullYear(), toIct.getUTCMonth(), toIct.getUTCDate());
  void start;
  void end;
  return Math.floor((b - a) / (24 * 60 * 60 * 1000));
}

export function computeDebtAging(
  entries: DebtLedgerRow[],
  debtOverdueDays: number,
  asOf: Date = new Date(),
): DebtAgingResult {
  const sorted = [...entries].sort(
    (a, b) => a.clientCreatedAt.getTime() - b.clientCreatedAt.getTime(),
  );

  type OpenDebt = { remaining: number; at: Date };
  const open: OpenDebt[] = [];

  for (const e of sorted) {
    if (e.type === 'sale_debt' && e.amountVnd > 0) {
      open.push({ remaining: e.amountVnd, at: e.clientCreatedAt });
      continue;
    }
    if (
      (e.type === 'payment' || e.type === 'sale_return_credit') &&
      e.amountVnd > 0
    ) {
      let left = e.amountVnd;
      while (left > 0 && open.length > 0) {
        const head = open[0];
        const take = Math.min(head.remaining, left);
        head.remaining -= take;
        left -= take;
        if (head.remaining <= 0) {
          open.shift();
        }
      }
    }
  }

  if (open.length === 0) {
    return { oldestUnpaidAt: null, daysOutstanding: 0, overdue: false };
  }

  const oldestUnpaidAt = open[0].at;
  const daysOutstanding = Math.max(0, ictDayDiff(oldestUnpaidAt, asOf));
  const overdue = daysOutstanding > debtOverdueDays;
  return { oldestUnpaidAt, daysOutstanding, overdue };
}
