import 'package:flutter_test/flutter_test.dart';
import 'package:decimal/decimal.dart';
import 'package:pos_app/features/products/unit_conversion.dart';

void main() {
  test('toBaseQty without packSize returns sell qty', () {
    expect(toBaseQty(Decimal.parse('2'), null), Decimal.parse('2'));
  });

  test('toBaseQty multiplies by packSize', () {
    expect(
      toBaseQty(Decimal.one, Decimal.parse('24')),
      Decimal.parse('24'),
    );
  });
}
