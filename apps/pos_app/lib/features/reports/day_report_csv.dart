String dayReportToCsv({
  required String date,
  required List<
          ({
            String storeCode,
            String storeName,
            int orderCount,
            int revenueVnd,
            int cashVnd,
            int transferVnd,
            int debtVnd,
          })>
      rows,
}) {
  final buffer = StringBuffer();
  // UTF-8 BOM for Excel
  buffer.write('\uFEFF');
  buffer.writeln(
    'date,storeCode,storeName,orderCount,revenueVnd,cashVnd,transferVnd,debtVnd',
  );
  for (final r in rows) {
    buffer.writeln(
      [
        date,
        _csv(r.storeCode),
        _csv(r.storeName),
        r.orderCount,
        r.revenueVnd,
        r.cashVnd,
        r.transferVnd,
        r.debtVnd,
      ].join(','),
    );
  }
  return buffer.toString();
}

String _csv(String value) {
  if (value.contains(',') || value.contains('"') || value.contains('\n')) {
    return '"${value.replaceAll('"', '""')}"';
  }
  return value;
}
