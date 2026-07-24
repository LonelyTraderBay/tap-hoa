import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/features/inventory/weighted_average_cost.dart';

void main() {
  test('uses unit cost when old qty is zero', () {
    expect(
      weightedAverageCost(
        oldQty: Decimal.zero,
        oldAvgVnd: 0,
        receiptQty: Decimal.fromInt(10),
        unitCostVnd: 8000,
      ),
      8000,
    );
  });

  test('blends existing avg with receipt', () {
    expect(
      weightedAverageCost(
        oldQty: Decimal.fromInt(10),
        oldAvgVnd: 10000,
        receiptQty: Decimal.fromInt(10),
        unitCostVnd: 8000,
      ),
      9000,
    );
  });
}
