import {
  allocateSaleDiscount,
  assertBalanced,
  buildPurchaseJournal,
  buildPurchaseReturnJournal,
  buildSaleJournal,
  buildSaleReturnJournal,
  buildStockTransferJournal,
  buildStockTransferStoreJournals,
  buildStocktakeJournal,
  buildWastageJournal,
  computeSaleLineVatSnapshots,
  periodYmFromDate,
  splitInclusiveVat,
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

  it('buildStockTransferJournal posts transfer at WAC without COGS', () => {
    const lines = buildStockTransferJournal({
      lines: [
        { qty: 2, avgCostVnd: 8000 },
        { qty: 1.5, avgCostVnd: 10000 },
        { qty: 1, avgCostVnd: null },
        { qty: 1, avgCostVnd: 0 },
      ],
    });
    expect(() => assertBalanced(lines)).not.toThrow();
    const dr156 = lines
      .filter((l) => l.accountCode === '156')
      .reduce((s, l) => s + l.debitVnd, 0);
    const cr156 = lines
      .filter((l) => l.accountCode === '156')
      .reduce((s, l) => s + l.creditVnd, 0);
    expect(dr156).toBe(31000);
    expect(cr156).toBe(31000);
    expect(lines.some((l) => l.accountCode === '632')).toBe(false);
  });

  it('buildStockTransferJournal returns empty when no costed lines', () => {
    expect(
      buildStockTransferJournal({
        lines: [
          { qty: 1, avgCostVnd: null },
          { qty: 1, avgCostVnd: 0 },
          { qty: 1, avgCostVnd: -1000 },
        ],
      }),
    ).toEqual([]);
  });

  it('buildStockTransferJournal rounds each costed line', () => {
    const lines = buildStockTransferJournal({
      lines: [
        { qty: 0.333, avgCostVnd: 1000 },
        { qty: 0.333, avgCostVnd: 1000 },
      ],
    });
    const dr156 = lines
      .filter((l) => l.accountCode === '156')
      .reduce((s, l) => s + l.debitVnd, 0);
    const cr156 = lines
      .filter((l) => l.accountCode === '156')
      .reduce((s, l) => s + l.creditVnd, 0);
    expect(dr156).toBe(666);
    expect(cr156).toBe(666);
  });

  it('buildStockTransferStoreJournals uses 151 clearing by store', () => {
    const journals = buildStockTransferStoreJournals({
      lines: [
        { qty: 2, unitCostVnd: 8000 },
        { qty: 1.5, unitCostVnd: 10000 },
      ],
    });
    expect(() => assertBalanced(journals.sourceLines)).not.toThrow();
    expect(() => assertBalanced(journals.destinationLines)).not.toThrow();
    expect(
      journals.sourceLines.find((l) => l.accountCode === '151')?.debitVnd,
    ).toBe(31000);
    expect(
      journals.sourceLines.find((l) => l.accountCode === '156')?.creditVnd,
    ).toBe(31000);
    expect(
      journals.destinationLines.find((l) => l.accountCode === '156')?.debitVnd,
    ).toBe(31000);
    expect(
      journals.destinationLines.find((l) => l.accountCode === '151')?.creditVnd,
    ).toBe(31000);
  });

  it('buildWastageJournal posts wastage at WAC', () => {
    const lines = buildWastageJournal({
      lines: [
        { qty: 2, avgCostVnd: 8000 },
        { qty: 1.5, avgCostVnd: 10000 },
        { qty: 1, avgCostVnd: null },
        { qty: 1, avgCostVnd: 0 },
      ],
    });
    expect(() => assertBalanced(lines)).not.toThrow();
    expect(lines.find((l) => l.accountCode === '642')?.debitVnd).toBe(31000);
    expect(lines.find((l) => l.accountCode === '156')?.creditVnd).toBe(31000);
  });

  it('buildWastageJournal returns empty when no costed lines', () => {
    expect(
      buildWastageJournal({
        lines: [
          { qty: 1, avgCostVnd: null },
          { qty: 1, avgCostVnd: 0 },
          { qty: 1, avgCostVnd: -1000 },
        ],
      }),
    ).toEqual([]);
  });

  it('buildWastageJournal rounds each costed line', () => {
    const lines = buildWastageJournal({
      lines: [{ qty: 0.333, avgCostVnd: 1000 }],
    });
    expect(lines.find((l) => l.accountCode === '642')?.debitVnd).toBe(333);
    expect(lines.find((l) => l.accountCode === '156')?.creditVnd).toBe(333);
  });

  it('splitInclusiveVat 110k @ 10%', () => {
    expect(splitInclusiveVat(110_000, 1000)).toEqual({
      netVnd: 100_000,
      vatVnd: 10_000,
    });
  });

  it('buildSaleJournal with VAT splits 511 and 3331', () => {
    const lines = buildSaleJournal({
      cashAmount: 110_000,
      transferAmount: 0,
      debtAmount: 0,
      totalVnd: 110_000,
      lines: [{ qty: 1, unitCostVnd: 80_000 }],
      vatRateBps: 1000,
    });
    expect(() => assertBalanced(lines)).not.toThrow();
    expect(lines.find((l) => l.accountCode === '511')?.creditVnd).toBe(100_000);
    expect(lines.find((l) => l.accountCode === '3331')?.creditVnd).toBe(10_000);
  });

  it('buildPurchaseJournal with VAT splits 156 / 1331 / 331', () => {
    const lines = buildPurchaseJournal({
      vatRateBps: 1000,
      lines: [{ qty: 1, unitCostVnd: 110_000 }],
    });
    expect(() => assertBalanced(lines)).not.toThrow();
    expect(lines.find((l) => l.accountCode === '156')?.debitVnd).toBe(100_000);
    expect(lines.find((l) => l.accountCode === '1331')?.debitVnd).toBe(10_000);
    expect(lines.find((l) => l.accountCode === '331')?.creditVnd).toBe(110_000);
  });

  it('buildSaleReturnJournal with VAT reverses 511 and 3331', () => {
    const lines = buildSaleReturnJournal({
      cashRefundVnd: 110_000,
      transferRefundVnd: 0,
      debtCreditVnd: 0,
      totalRefundVnd: 110_000,
      lines: [{ qty: 1, unitCostVnd: 80_000 }],
      vatRateBps: 1000,
    });
    expect(() => assertBalanced(lines)).not.toThrow();
    expect(lines.find((l) => l.accountCode === '511')?.debitVnd).toBe(100_000);
    expect(lines.find((l) => l.accountCode === '3331')?.debitVnd).toBe(10_000);
  });

  it('buildPurchaseReturnJournal reverses purchase with VAT', () => {
    const lines = buildPurchaseReturnJournal({
      vatRateBps: 1000,
      lines: [{ qty: 1, unitCostVnd: 110_000 }],
    });
    expect(() => assertBalanced(lines)).not.toThrow();
    expect(lines.find((l) => l.accountCode === '331')?.debitVnd).toBe(110_000);
    expect(lines.find((l) => l.accountCode === '156')?.creditVnd).toBe(100_000);
    expect(lines.find((l) => l.accountCode === '1331')?.creditVnd).toBe(10_000);
  });

  it('allocateSaleDiscount puts remainder on last line', () => {
    expect(allocateSaleDiscount([100, 100, 100], 1)).toEqual([100, 100, 99]);
  });

  it('buildSaleJournal mixed product VAT rates', () => {
    // 110k@10% + 105k@5% = 215k gross
    const lines = buildSaleJournal({
      cashAmount: 215_000,
      transferAmount: 0,
      debtAmount: 0,
      totalVnd: 215_000,
      discountVnd: 0,
      lines: [
        { qty: 1, unitCostVnd: 80_000, lineTotal: 110_000, vatRateBps: 1000 },
        { qty: 1, unitCostVnd: 70_000, lineTotal: 105_000, vatRateBps: 500 },
      ],
      vatRateBps: 1000,
    });
    expect(() => assertBalanced(lines)).not.toThrow();
    expect(lines.find((l) => l.accountCode === '511')?.creditVnd).toBe(200_000);
    expect(lines.find((l) => l.accountCode === '3331')?.creditVnd).toBe(15_000);
  });

  it('computeSaleLineVatSnapshots respects product override', () => {
    const snaps = computeSaleLineVatSnapshots({
      lines: [
        { lineTotal: 110_000, vatRateBps: 1000 },
        { lineTotal: 105_000, vatRateBps: 500 },
      ],
      discountVnd: 0,
      storeVatRateBps: 1000,
    });
    expect(snaps[0]).toEqual({ vatRateBps: 1000, netVnd: 100_000, vatVnd: 10_000 });
    expect(snaps[1]).toEqual({ vatRateBps: 500, netVnd: 100_000, vatVnd: 5_000 });
  });

  it('buildSaleJournal mixed rates + discount allocation is deterministic', () => {
    // Gross 110k@10% + 108k@8%, discount 18k → paid 200k.
    // Allocation: A share round(110000*18000/218000)=9083 → 100917;
    // B gets remainder 8917 → 99083. Splits: A 91743/9174, B 91744/7339.
    expect(allocateSaleDiscount([110_000, 108_000], 18_000)).toEqual([
      100_917, 99_083,
    ]);
    const lines = buildSaleJournal({
      cashAmount: 200_000,
      transferAmount: 0,
      debtAmount: 0,
      totalVnd: 200_000,
      discountVnd: 18_000,
      lines: [
        { qty: 1, unitCostVnd: 80_000, lineTotal: 110_000, vatRateBps: 1000 },
        { qty: 1, unitCostVnd: 70_000, lineTotal: 108_000, vatRateBps: 800 },
      ],
      vatRateBps: 1000,
    });
    expect(() => assertBalanced(lines)).not.toThrow();
    expect(lines.find((l) => l.accountCode === '511')?.creditVnd).toBe(183_487);
    expect(lines.find((l) => l.accountCode === '3331')?.creditVnd).toBe(16_513);
  });

  it('computeSaleLineVatSnapshots starts from line nets before invoice discount', () => {
    const snaps = computeSaleLineVatSnapshots({
      // First line was 220k gross with 10k line discount; invoice discount is
      // then allocated over 210k + 105k.
      lines: [
        { lineTotal: 210_000, vatRateBps: 1000 },
        { lineTotal: 105_000, vatRateBps: 500 },
      ],
      discountVnd: 15_000,
      storeVatRateBps: 1000,
    });
    expect(allocateSaleDiscount([210_000, 105_000], 15_000)).toEqual([
      200_000, 100_000,
    ]);
    expect(snaps[0]).toEqual({ vatRateBps: 1000, netVnd: 181_818, vatVnd: 18_182 });
    expect(snaps[1]).toEqual({ vatRateBps: 500, netVnd: 95_238, vatVnd: 4_762 });
  });

  it('buildSaleReturnJournal prefers line snapshots for VAT reversal', () => {
    const lines = buildSaleReturnJournal({
      cashRefundVnd: 110_000,
      transferRefundVnd: 0,
      debtCreditVnd: 0,
      totalRefundVnd: 110_000,
      lines: [
        {
          qty: 1,
          unitCostVnd: 80_000,
          lineTotal: 110_000,
          vatRateBps: 1000,
          netVnd: 100_000,
          vatVnd: 10_000,
        },
      ],
      vatRateBps: null,
    });
    expect(() => assertBalanced(lines)).not.toThrow();
    expect(lines.find((l) => l.accountCode === '511')?.debitVnd).toBe(100_000);
    expect(lines.find((l) => l.accountCode === '3331')?.debitVnd).toBe(10_000);
  });
});
