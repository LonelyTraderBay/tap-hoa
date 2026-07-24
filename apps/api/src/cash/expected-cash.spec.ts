import { computeShiftCashSnapshot } from './expected-cash';

describe('computeShiftCashSnapshot', () => {
  it('matches spec formula', () => {
    const snap = computeShiftCashSnapshot(
      {
        openingCash: 500_000,
        saleCashTotal: 900_000,
        saleTransferTotal: 300_000,
        debtPaymentCashTotal: 100_000,
        debtPaymentTransferTotal: 50_000,
        voucherCashInTotal: 50_000,
        voucherCashOutTotal: 300_000,
        voucherTransferInTotal: 30_000,
        voucherTransferOutTotal: 0,
      },
      1_230_000,
    );
    expect(snap.expectedCashVnd).toBe(1_250_000);
    expect(snap.transferInShiftVnd).toBe(380_000);
    expect(snap.varianceVnd).toBe(-20_000);
  });

  it('ignores debt sale amounts (not in inputs)', () => {
    const snap = computeShiftCashSnapshot(
      {
        openingCash: 100,
        saleCashTotal: 0,
        saleTransferTotal: 0,
        debtPaymentCashTotal: 0,
        debtPaymentTransferTotal: 0,
        voucherCashInTotal: 0,
        voucherCashOutTotal: 0,
        voucherTransferInTotal: 0,
        voucherTransferOutTotal: 0,
      },
      100,
    );
    expect(snap.expectedCashVnd).toBe(100);
    expect(snap.varianceVnd).toBe(0);
  });
});
