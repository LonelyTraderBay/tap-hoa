import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/features/cash/expected_cash.dart';

void main() {
  test('computeBreakdown matches server spec formula', () {
    final breakdown = computeBreakdown(
      openingCash: 500_000,
      saleCashTotal: 900_000,
      saleTransferTotal: 300_000,
      debtPaymentCashTotal: 100_000,
      debtPaymentTransferTotal: 50_000,
      voucherCashInTotal: 50_000,
      voucherCashOutTotal: 300_000,
      voucherTransferInTotal: 30_000,
      voucherTransferOutTotal: 0,
    );

    expect(breakdown.expectedCash, 1_250_000);
    expect(breakdown.transferInShift, 380_000);
    expect(breakdown.variance(1_230_000), -20_000);
  });

  test('computeBreakdown ignores debt sale amounts', () {
    final breakdown = computeBreakdown(
      openingCash: 100,
      saleCashTotal: 0,
      saleTransferTotal: 0,
      debtPaymentCashTotal: 0,
      debtPaymentTransferTotal: 0,
      voucherCashInTotal: 0,
      voucherCashOutTotal: 0,
      voucherTransferInTotal: 0,
      voucherTransferOutTotal: 0,
    );

    expect(breakdown.expectedCash, 100);
    expect(breakdown.variance(100), 0);
  });
}
