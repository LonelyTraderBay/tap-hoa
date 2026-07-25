import 'package:decimal/decimal.dart';

/// Pure validation for sale-return refund channel split.
class SaleReturnRefundSplit {
  const SaleReturnRefundSplit({
    required this.cashRefundVnd,
    required this.transferRefundVnd,
    required this.debtCreditVnd,
  });

  final int cashRefundVnd;
  final int transferRefundVnd;
  final int debtCreditVnd;

  int get total => cashRefundVnd + transferRefundVnd + debtCreditVnd;
}

/// Returns an error code, or null when valid.
String? validateSaleReturnRefundSplit({
  required int lineRefundTotal,
  required int cashRefundVnd,
  required int transferRefundVnd,
  required int debtCreditVnd,
  required bool originalSaleHasCustomer,
}) {
  if (cashRefundVnd < 0 || transferRefundVnd < 0 || debtCreditVnd < 0) {
    return 'negative_refund';
  }
  final total = cashRefundVnd + transferRefundVnd + debtCreditVnd;
  if (total != lineRefundTotal) {
    return 'refund_mismatch';
  }
  if (debtCreditVnd > 0 && !originalSaleHasCustomer) {
    return 'debt_credit_requires_customer';
  }
  return null;
}

int discountedReturnLineRefundVnd({
  required Decimal soldQty,
  required Decimal returnQty,
  required int soldLineTotalVnd,
}) {
  if (soldQty <= Decimal.zero || returnQty <= Decimal.zero) {
    return 0;
  }
  return (soldLineTotalVnd * returnQty.toDouble() / soldQty.toDouble()).round();
}
