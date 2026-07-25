import {
  assertBalanced,
  buildSaleJournal,
  buildSaleReturnJournal,
  buildStocktakeJournal,
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

  it('buildSaleReturnJournal reverses revenue and COGS', () => {
    const lines = buildSaleReturnJournal({
      cashRefundVnd: 15000,
      transferRefundVnd: 0,
      debtCreditVnd: 0,
      totalRefundVnd: 15000,
      lines: [{ qty: 1, unitCostVnd: 9000 }],
    });
    expect(() => assertBalanced(lines)).not.toThrow();
    expect(lines.find((l) => l.accountCode === '511')?.debitVnd).toBe(15000);
    expect(lines.find((l) => l.accountCode === '111')?.creditVnd).toBe(15000);
    expect(lines.find((l) => l.accountCode === '156')?.debitVnd).toBe(9000);
    expect(lines.find((l) => l.accountCode === '632')?.creditVnd).toBe(9000);
  });

  it('buildStocktakeJournal posts increase and decrease at WAC', () => {
    const lines = buildStocktakeJournal({
      lines: [
        { varianceQty: 2, avgCostVnd: 1000 },
        { varianceQty: -1, avgCostVnd: 1000 },
        { varianceQty: 1, avgCostVnd: null },
      ],
    });
    expect(() => assertBalanced(lines)).not.toThrow();
    expect(lines.find((l) => l.accountCode === '711')?.creditVnd).toBe(2000);
    expect(lines.find((l) => l.accountCode === '642')?.debitVnd).toBe(1000);
    // net 156: +2000 Dr and +1000 Cr
    const dr156 = lines
      .filter((l) => l.accountCode === '156')
      .reduce((s, l) => s + l.debitVnd, 0);
    const cr156 = lines
      .filter((l) => l.accountCode === '156')
      .reduce((s, l) => s + l.creditVnd, 0);
    expect(dr156).toBe(2000);
    expect(cr156).toBe(1000);
  });

  it('buildStocktakeJournal returns empty when no costed variance', () => {
    expect(
      buildStocktakeJournal({
        lines: [{ varianceQty: 5, avgCostVnd: null }],
      }),
    ).toEqual([]);
  });
});
