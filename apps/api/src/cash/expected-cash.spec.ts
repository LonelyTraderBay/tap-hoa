import { computeShiftCashSnapshot } from './expected-cash';

describe('computeShiftCashSnapshot', () => {
  it('matches spec formula', () => {
    const snap = computeShiftCashSnapshot(
      {
        openingCash: 500_000,
        saleCashTotal: 900_000,
        saleTransferTotal: 300_000,
        saleReturnCashTotal: 0,
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
        saleReturnCashTotal: 0,
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

  it('H1: trừ hoàn tiền mặt trả hàng (SaleReturn.cashRefundVnd) khỏi expectedCashVnd', () => {
    const snap = computeShiftCashSnapshot(
      {
        openingCash: 500_000,
        saleCashTotal: 900_000,
        saleTransferTotal: 300_000,
        saleReturnCashTotal: 150_000,
        debtPaymentCashTotal: 100_000,
        debtPaymentTransferTotal: 50_000,
        voucherCashInTotal: 50_000,
        voucherCashOutTotal: 300_000,
        voucherTransferInTotal: 30_000,
        voucherTransferOutTotal: 0,
      },
      1_080_000,
    );
    // Giống test 'matches spec formula' nhưng trừ thêm 150.000 hoàn tiền mặt.
    expect(snap.expectedCashVnd).toBe(1_100_000);
    // Tiền đếm khớp đúng kỳ vọng mới (không còn lệch âm giả do quên trừ hoàn tiền).
    expect(snap.varianceVnd).toBe(-20_000);
    // transferInShiftVnd không đổi: hoàn tiền CK không tính ở đây (ngoài phạm vi H1).
    expect(snap.transferInShiftVnd).toBe(380_000);
  });
});
