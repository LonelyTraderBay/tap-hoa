import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/features/pos/pos_page.dart';
import 'package:pos_app/features/products/product_repository.dart';

void main() {
  test('search matches barcode by contains', () {
    final product = _product(barcode: '893ABC001');

    expect(posProductMatchesQuery(product, 'abc'), isTrue);
    expect(posProductMatchesQuery(product, ' 3AB '), isTrue);
    expect(posProductMatchesQuery(product, 'missing'), isFalse);
  });

  test('exact barcode match trims and ignores case', () {
    final product = _product(id: 'p1', barcode: '893ABC001');
    final match = posExactBarcodeMatch([
      _product(id: 'p2', barcode: 'other'),
      product,
    ], ' 893abc001 ');

    expect(match, same(product));
  });

  test('exact barcode match requires one product', () {
    final products = [
      _product(id: 'p1', barcode: '893ABC001'),
      _product(id: 'p2', barcode: '893abc001'),
    ];

    expect(posExactBarcodeMatch(products, '893ABC001'), isNull);
  });
}

ProductWithStock _product({String id = 'p1', String barcode = 'barcode'}) {
  return ProductWithStock(
    id: id,
    name: 'Product $id',
    sku: 'SKU-$id',
    barcode: barcode,
    unit: 'each',
    isWeighted: false,
    basePriceVnd: 10000,
    qty: '10',
  );
}
