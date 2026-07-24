import 'package:flutter_test/flutter_test.dart';

import 'package:pos_app/features/pos/receipt_print.dart';

void main() {
  test('buildReceiptPdf returns non-empty pdf', () async {
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
