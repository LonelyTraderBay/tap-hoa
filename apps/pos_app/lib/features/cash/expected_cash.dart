class ShiftCashBreakdown {
  const ShiftCashBreakdown({
    required this.openingCash,
    required this.saleCash,
    required this.debtPaymentCash,
    required this.voucherCashIn,
    required this.voucherCashOut,
    required this.expectedCash,
    required this.saleTransfer,
    required this.debtPaymentTransfer,
    required this.voucherTransferIn,
    required this.voucherTransferOut,
    required this.transferInShift,
  });

  final int openingCash;
  final int saleCash;
  final int debtPaymentCash;
  final int voucherCashIn;
  final int voucherCashOut;
  final int expectedCash;
  final int saleTransfer;
  final int debtPaymentTransfer;
  final int voucherTransferIn;
  final int voucherTransferOut;
  final int transferInShift;

  int variance(int closingCash) => closingCash - expectedCash;
}

ShiftCashBreakdown computeBreakdown({
  required int openingCash,
  required int saleCashTotal,
  required int saleTransferTotal,
  required int debtPaymentCashTotal,
  required int debtPaymentTransferTotal,
  required int voucherCashInTotal,
  required int voucherCashOutTotal,
  required int voucherTransferInTotal,
  required int voucherTransferOutTotal,
}) {
  final expectedCash =
      openingCash +
      saleCashTotal +
      debtPaymentCashTotal +
      voucherCashInTotal -
      voucherCashOutTotal;
  final transferInShift =
      saleTransferTotal +
      debtPaymentTransferTotal +
      voucherTransferInTotal -
      voucherTransferOutTotal;
  return ShiftCashBreakdown(
    openingCash: openingCash,
    saleCash: saleCashTotal,
    debtPaymentCash: debtPaymentCashTotal,
    voucherCashIn: voucherCashInTotal,
    voucherCashOut: voucherCashOutTotal,
    expectedCash: expectedCash,
    saleTransfer: saleTransferTotal,
    debtPaymentTransfer: debtPaymentTransferTotal,
    voucherTransferIn: voucherTransferInTotal,
    voucherTransferOut: voucherTransferOutTotal,
    transferInShift: transferInShift,
  );
}
