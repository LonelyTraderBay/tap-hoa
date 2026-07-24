import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/features/reports/day_report_csv.dart';

void main() {
  test('dayReportToCsv includes BOM and rows', () {
    final csv = dayReportToCsv(
      date: '2026-07-24',
      rows: [
        (
          storeCode: 'A',
          storeName: 'Store A',
          orderCount: 2,
          revenueVnd: 1000,
          cashVnd: 500,
          transferVnd: 300,
          debtVnd: 200,
        ),
      ],
    );
    expect(csv.startsWith('\uFEFF'), isTrue);
    expect(csv, contains('Store A'));
    expect(csv, contains('1000'));
  });
}
