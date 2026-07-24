import { computeDebtAging } from './debt-aging';

describe('computeDebtAging', () => {
  const day = (n: number) => new Date(Date.UTC(2026, 0, n, 10, 0, 0));

  it('marks overdue when oldest unpaid exceeds X days', () => {
    const entries = [
      { type: 'sale_debt', amountVnd: 100_000, clientCreatedAt: day(1) },
    ];
    const asOf = day(32);
    const result = computeDebtAging(entries, 30, asOf);
    expect(result.overdue).toBe(true);
    expect(result.daysOutstanding).toBe(31);
    expect(result.oldestUnpaidAt?.toISOString()).toBe(day(1).toISOString());
  });

  it('FIFO payment clears oldest debt first', () => {
    const entries = [
      { type: 'sale_debt', amountVnd: 50_000, clientCreatedAt: day(1) },
      { type: 'sale_debt', amountVnd: 50_000, clientCreatedAt: day(10) },
      { type: 'payment', amountVnd: 50_000, clientCreatedAt: day(15) },
    ];
    const asOf = day(40);
    const result = computeDebtAging(entries, 30, asOf);
    expect(result.oldestUnpaidAt?.toISOString()).toBe(day(10).toISOString());
    expect(result.daysOutstanding).toBe(30);
    expect(result.overdue).toBe(false);
  });

  it('no balance means not overdue', () => {
    const entries = [
      { type: 'sale_debt', amountVnd: 10_000, clientCreatedAt: day(1) },
      { type: 'payment', amountVnd: 10_000, clientCreatedAt: day(2) },
    ];
    const result = computeDebtAging(entries, 30, day(100));
    expect(result.overdue).toBe(false);
    expect(result.oldestUnpaidAt).toBeNull();
  });
});
