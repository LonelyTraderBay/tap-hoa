import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/features/pos/cart.dart';

void main() {
  test('line total and cart total', () {
    final cart = Cart();
    cart.add(
      CartLine(
        productId: 'p1',
        name: 'Sting',
        unitPrice: 10000,
        qty: Decimal.parse('2'),
      ),
    );
    expect(cart.totalVnd, 20000);
    cart.discountVnd = 2000;
    expect(cart.totalVnd, 18000);
  });

  test('weighted qty', () {
    final cart = Cart();
    cart.add(
      CartLine(
        productId: 'p2',
        name: 'Duong',
        unitPrice: 25000,
        qty: Decimal.parse('0.500'),
      ),
    );
    expect(cart.totalVnd, 12500);
  });

  test('update and remove lines', () {
    final cart = Cart();
    cart.add(
      CartLine(
        productId: 'p1',
        name: 'Sting',
        unitPrice: 10000,
        qty: Decimal.parse('2'),
      ),
    );
    cart.update('p1', Decimal.parse('3'));
    expect(cart.totalVnd, 30000);
    cart.remove('p1');
    expect(cart.lines, isEmpty);
    expect(cart.totalVnd, 0);
  });

  test('toSaleDraft maps lines and discount', () {
    final cart = Cart();
    cart.add(
      CartLine(
        productId: 'p2',
        name: 'Duong',
        unitPrice: 25000,
        qty: Decimal.parse('0.500'),
      ),
    );
    cart.discountVnd = 500;
    final draft = cart.toSaleDraft();
    expect(draft.subtotalVnd, 12500);
    expect(draft.discountVnd, 500);
    expect(draft.totalVnd, 12000);
    expect(draft.lines.single.qty, '0.500');
    expect(draft.lines.single.lineTotal, 12500);
  });
}
