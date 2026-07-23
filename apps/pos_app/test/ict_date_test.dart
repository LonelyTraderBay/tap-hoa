import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/features/reports/ict_date.dart';

void main() {
  test('ictDayRangeUtc maps ICT calendar day to UTC instants', () {
    final range = ictDayRangeUtc(DateTime(2026, 7, 23));

    expect(range.start, DateTime.utc(2026, 7, 22, 17));
    expect(range.end, DateTime.utc(2026, 7, 23, 17));
  });

  test('formatIctDate formats calendar components', () {
    expect(formatIctDate(DateTime(2026, 7, 23)), '2026-07-23');
  });
}
