import {
  assertBalanced,
  buildSaleJournal,
  periodYmFromDate,
} from './journal-builders';

describe('journal-builders', () => {
  it('periodYmFromDate uses ICT month', () => {
    // 2026-07-31 20:00 UTC = 2026-08-01 03:00 ICT
    expect(periodYmFromDate(new Date('2026-07-31T20:00:00.000Z'))).toBe(
      '2026-08',
    );
  });

  it('buildSaleJournal balances cash + COGS', () => {
    const lines = buildSaleJournal({
      cashAmount: 10000,
      transferAmount: 0,
      debtAmount: 0,
      totalVnd: 10000,
      lines: [{ qty: 1, unitCostVnd: 9000 }],
    });
    expect(() => assertBalanced(lines)).not.toThrow();
    const debit = lines.reduce((s, l) => s + l.debitVnd, 0);
    expect(debit).toBe(19000);
  });
});
