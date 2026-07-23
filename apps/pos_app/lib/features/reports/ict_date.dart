/// Asia/Ho_Chi_Minh (ICT, UTC+7) calendar helpers for day reports.
const ictOffset = Duration(hours: 7);

String formatIctDate(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

DateTime ictToday() {
  final now = DateTime.now().toUtc().add(ictOffset);
  return DateTime(now.year, now.month, now.day);
}

({DateTime start, DateTime end}) ictDayRangeUtc(DateTime date) {
  final midnightUtc = DateTime.utc(date.year, date.month, date.day);
  return (
    start: midnightUtc.subtract(ictOffset),
    end: midnightUtc.add(const Duration(days: 1)).subtract(ictOffset),
  );
}
