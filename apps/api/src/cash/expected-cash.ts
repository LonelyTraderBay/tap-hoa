export type ShiftCashInputs = {
  openingCash: number;
  saleCashTotal: number;
  saleTransferTotal: number;
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
    inputs.voucherCashOutTotal;
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
