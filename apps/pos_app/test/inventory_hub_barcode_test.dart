import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/features/inventory/inventory_hub_page.dart';
import 'package:pos_app/features/products/product_repository.dart';

// Mirrors test/pos_page_barcode_test.dart's coverage of
// posExactBarcodeMatch — inventoryScanExactBarcodeMatch is a deliberate
// replica of the same matching semantics (trim+lowercase normalize, unique
// exact match only) for the §4.8 "quét mã xem tồn" quick-check flow, so a
// scanned code behaves identically whether it's being added to the checkout
// cart or just looked up in the inventory hub.
void main() {
  test('exact barcode match trims and ignores case', () {
    final product = _product(id: 'p1', barcode: '893ABC001');
    final match = inventoryScanExactBarcodeMatch([
      _product(id: 'p2', barcode: 'other'),
      product,
    ], ' 893abc001 ');

    expect(match, same(product));
  });

  test('exact barcode match requires exactly one product', () {
    final products = [
      _product(id: 'p1', barcode: '893ABC001'),
      _product(id: 'p2', barcode: '893abc001'),
    ];

    expect(inventoryScanExactBarcodeMatch(products, '893ABC001'), isNull);
  });

  test('no match returns null (not found)', () {
    final products = [_product(id: 'p1', barcode: '893ABC001')];

    expect(inventoryScanExactBarcodeMatch(products, 'missing'), isNull);
  });

  test('blank scanned value returns null', () {
    final products = [_product(id: 'p1', barcode: '893ABC001')];

    expect(inventoryScanExactBarcodeMatch(products, '   '), isNull);
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
