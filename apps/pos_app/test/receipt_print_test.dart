import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pos_app/features/pos/receipt_print.dart';
import 'package:pos_app/shared/pdf_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    resetPdfFontsForTesting();
  });

  test('pdf font assets load and parse as TTF', () async {
    final regular = await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
    final bold = await rootBundle.load('assets/fonts/NotoSans-Bold.ttf');
    expect(regular.lengthInBytes, greaterThan(1000));
    expect(bold.lengthInBytes, greaterThan(1000));

    await ensurePdfFontsLoaded();
    expect(pdfFontRegular, isNotNull);
    expect(pdfFontBold, isNotNull);
  });

  test('buildReceiptPdf returns non-empty pdf with Vietnamese text', () async {
    final bytes = await buildReceiptPdf(
      storeName: 'Tạp hóa Minh Anh',
      saleId: 'abc12345-6789-0000-0000-000000000001',
      soldAt: DateTime.utc(2026, 7, 24, 3, 30),
      lines: const [
        ReceiptLine(
          name: 'Sting do 330ml',
          qtyLabel: '2',
          unitPriceVnd: 10000,
          lineTotalVnd: 20000,
        ),
        ReceiptLine(
          name: 'Mì gói Hảo Hảo tôm chua cay',
          qtyLabel: '1',
          unitPriceVnd: 4500,
          lineTotalVnd: 4500,
        ),
      ],
      totalVnd: 24500,
      cashVnd: 20000,
      transferVnd: 4500,
      debtVnd: 0,
      customerName: 'Anh Tuấn',
    );
    expect(bytes.length, greaterThan(100));
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    // Glyph rendering for Vietnamese diacritics requires visual PDF inspection.
  });

  test('formatReceiptVnd uses dot thousands separator', () {
    expect(formatReceiptVnd(10000), '10.000');
    expect(formatReceiptVnd(1200), '1.200');
  });

  test('truncateReceiptName limits length', () {
    expect(
      truncateReceiptName('Mì gói Hảo Hảo tôm chua cay extra long'),
      'Mì gói Hảo Hảo tôm chua…',
    );
  });

  test('shortenSaleId keeps short ids', () {
    expect(shortenSaleId('abc'), 'abc');
    expect(
      shortenSaleId('abc12345-6789-0000-0000-000000000001'),
      'abc12345-678',
    );
  });
}
