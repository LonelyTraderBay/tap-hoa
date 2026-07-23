import 'package:dio/dio.dart';
import 'package:drift/drift.dart';

import '../../data/local/database.dart';

class StoreDayReport {
  const StoreDayReport({
    required this.storeId,
    required this.revenueVnd,
    required this.orderCount,
    required this.cashVnd,
    required this.transferVnd,
    required this.debtVnd,
  });

  factory StoreDayReport.fromJson(Map<String, dynamic> json) {
    return StoreDayReport(
      storeId: json['storeId'] as String,
      revenueVnd: json['revenueVnd'] as int,
      orderCount: json['orderCount'] as int,
      cashVnd: json['cashVnd'] as int,
      transferVnd: json['transferVnd'] as int,
      debtVnd: json['debtVnd'] as int,
    );
  }

  final String storeId;
  final int revenueVnd;
  final int orderCount;
  final int cashVnd;
  final int transferVnd;
  final int debtVnd;
}

class DayReport {
  const DayReport({
    required this.byStore,
    required this.totalRevenueVnd,
    required this.isOffline,
  });

  factory DayReport.fromJson(Map<String, dynamic> json, {bool isOffline = false}) {
    final byStore = (json['byStore'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(StoreDayReport.fromJson)
        .toList();
    return DayReport(
      byStore: byStore,
      totalRevenueVnd: json['totalRevenueVnd'] as int,
      isOffline: isOffline,
    );
  }

  final List<StoreDayReport> byStore;
  final int totalRevenueVnd;
  final bool isOffline;
}

class DayReportRepository {
  DayReportRepository({required Dio dio, required AppDatabase db})
    : _dio = dio,
      _db = db;

  final Dio _dio;
  final AppDatabase _db;

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  ({DateTime start, DateTime end}) _localDayRange(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (start: start, end: end);
  }

  Future<DayReport> fetchDayReport({
    required DateTime date,
    String? storeId,
  }) async {
    final dateStr = _formatDate(date);
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/reports/day',
        queryParameters: {
          'date': dateStr,
          'storeId': ?storeId,
        },
      );
      final data = response.data;
      if (data == null) {
        throw StateError('Empty report response');
      }
      return DayReport.fromJson(data);
    } catch (_) {
      final store = storeId ?? await _db.metaValue('currentStoreId');
      if (store == null) {
        rethrow;
      }
      return _aggregateFromSalesLocal(store, date);
    }
  }

  Future<DayReport> _aggregateFromSalesLocal(
    String storeId,
    DateTime date,
  ) async {
    final range = _localDayRange(date);
    final sales =
        await (_db.select(_db.salesLocal)..where(
              (sale) =>
                  sale.storeId.equals(storeId) &
                  sale.clientCreatedAt.isBiggerOrEqualValue(range.start) &
                  sale.clientCreatedAt.isSmallerThanValue(range.end),
            ))
            .get();

    var revenueVnd = 0;
    var cashVnd = 0;
    var transferVnd = 0;
    var debtVnd = 0;
    for (final sale in sales) {
      revenueVnd += sale.totalVnd;
      cashVnd += sale.cashAmount;
      transferVnd += sale.transferAmount;
      debtVnd += sale.debtAmount;
    }

    return DayReport(
      byStore: [
        StoreDayReport(
          storeId: storeId,
          revenueVnd: revenueVnd,
          orderCount: sales.length,
          cashVnd: cashVnd,
          transferVnd: transferVnd,
          debtVnd: debtVnd,
        ),
      ],
      totalRevenueVnd: revenueVnd,
      isOffline: true,
    );
  }
}
