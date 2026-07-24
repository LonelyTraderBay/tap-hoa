import 'package:flutter_test/flutter_test.dart';

import 'package:pos_app/features/products/barcode_label.dart';
import 'package:pos_app/shared/pdf_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    resetPdfFontsForTesting();
  });

  test('buildProductLabelPdf returns non-empty pdf', () async {
    final bytes = await buildProductLabelPdf(
      title: 'Sting do 330ml',
      priceLabel: '10.000 VND',
      code: '8934588012345',
      copies: 1,
    );
    expect(bytes.length, greaterThan(100));
  });

  test('formatPriceLabelVnd uses dot thousands separator', () {
    expect(formatPriceLabelVnd(10000), '10.000 VND');
    expect(formatPriceLabelVnd(1200), '1.200 VND');
  });
}
