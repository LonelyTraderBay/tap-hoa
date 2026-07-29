export type ShiftCashInputs = {
  openingCash: number;
  saleCashTotal: number;
  saleTransferTotal: number;
  /**
   * SaleReturn.cashRefundVnd cộng dồn trong ca — tiền mặt đã ra khỏi ngăn
   * kéo khi hoàn trả hàng, phải TRỪ khỏi expectedCashVnd. Chỉ phần hoàn
   * bằng tiền mặt; SaleReturn.transferRefundVnd KHÔNG chạm tiền mặt nên
   * không được cộng vào đây (xem loadShiftCashInputsWithClient).
   */
  saleReturnCashTotal: number;
  debtPaymentCashTotal: number;
  debtPaymentTransferTotal: number;
  voucherCashInTotal: number;
  voucherCashOutTotal: number;
  voucherTransferInTotal: number;
  voucherTransferOutTotal: number;
};

export type ShiftCashSnapshot = {
  expectedCashVnd: number;
  transferInShiftVnd: number;
  varianceVnd: number; // closingCash - expected
};

export function computeShiftCashSnapshot(
  inputs: ShiftCashInputs,
  closingCash: number,
): ShiftCashSnapshot {
  const expectedCashVnd =
    inputs.openingCash +
    inputs.saleCashTotal +
    inputs.debtPaymentCashTotal +
    inputs.voucherCashInTotal -
    inputs.voucherCashOutTotal -
    inputs.saleReturnCashTotal;
  const transferInShiftVnd =
    inputs.saleTransferTotal +
    inputs.debtPaymentTransferTotal +
    inputs.voucherTransferInTotal -
    inputs.voucherTransferOutTotal;
  return {
    expectedCashVnd,
    transferInShiftVnd,
    varianceVnd: closingCash - expectedCashVnd,
  };
}
