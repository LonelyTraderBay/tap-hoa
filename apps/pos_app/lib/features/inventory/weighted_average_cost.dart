import 'package:decimal/decimal.dart';

/// Weighted-average unit cost (VND integers). Mirrors API helper.
int weightedAverageCost({
  required Decimal oldQty,
  required int oldAvgVnd,
  required Decimal receiptQty,
  required int unitCostVnd,
}) {
  if (receiptQty <= Decimal.zero) {
    return oldAvgVnd < 0 ? 0 : oldAvgVnd;
  }
  if (oldQty <= Decimal.zero) {
    return unitCostVnd < 0 ? 0 : unitCostVnd;
  }
  final oldQ = oldQty.toDouble();
  final recQ = receiptQty.toDouble();
  final avg = (oldQ * oldAvgVnd + recQ * unitCostVnd) / (oldQ + recQ);
  final rounded = avg.round();
  return rounded < 0 ? 0 : rounded;
}
