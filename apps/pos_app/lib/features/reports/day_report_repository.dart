import 'package:dio/dio.dart';
import 'package:drift/drift.dart';

import '../../data/local/database.dart';
import 'ict_date.dart';

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

class TopSkuItem {
  const TopSkuItem({
    required this.productId,
    required this.sku,
    required this.name,
    required this.qty,
    required this.revenueVnd,
    required this.estimatedGrossVnd,
  });

  factory TopSkuItem.fromJson(Map<String, dynamic> json) {
    final gross = json['estimatedGrossVnd'];
    return TopSkuItem(
      productId: json['productId'] as String,
      sku: json['sku'] as String,
      name: json['name'] as String,
      qty: (json['qty'] as num).toDouble(),
      revenueVnd: json['revenueVnd'] as int,
      estimatedGrossVnd: gross == null ? null : (gross as num).toInt(),
    );
  }

  final String productId;
  final String sku;
  final String name;
  final double qty;
  final int revenueVnd;
  final int? estimatedGrossVnd;
}

class TopSkuReport {
  const TopSkuReport({
    required this.items,
    required this.isOffline,
  });

  factory TopSkuReport.fromJson(
    Map<String, dynamic> json, {
    bool isOffline = false,
  }) {
    final items = (json['items'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(TopSkuItem.fromJson)
        .toList();
    return TopSkuReport(items: items, isOffline: isOffline);
  }

  final List<TopSkuItem> items;
  final bool isOffline;
}

class DayReportRepository {
  DayReportRepository({required Dio dio, required AppDatabase db})
    : _dio = dio,
      _db = db;

  final Dio _dio;
  final AppDatabase _db;

  bool _isOfflineNetworkError(DioException error) {
    return error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.unknown;
  }

  Future<DayReport> fetchDayReport({
    required DateTime date,
    String? storeId,
  }) async {
    final dateStr = formatIctDate(date);
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
    } on DioException catch (error) {
      if (!_isOfflineNetworkError(error)) {
        rethrow;
      }
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
    final range = ictDayRangeUtc(date);
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

  Future<TopSkuReport> fetchTopSkus({
    required DateTime date,
    String? storeId,
    int limit = 10,
  }) async {
    final dateStr = formatIctDate(date);
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/reports/top-skus',
        queryParameters: {
          'date': dateStr,
          'storeId': ?storeId,
          'limit': limit,
        },
      );
      final data = response.data;
      if (data == null) {
        throw StateError('Empty top SKU response');
      }
      return TopSkuReport.fromJson(data);
    } on DioException catch (error) {
      if (!_isOfflineNetworkError(error)) {
        rethrow;
      }
      final store = storeId ?? await _db.metaValue('currentStoreId');
      if (store == null) {
        rethrow;
      }
      return _aggregateTopSkusFromLocal(store, date, limit);
    }
  }

  Future<TopSkuReport> _aggregateTopSkusFromLocal(
    String storeId,
    DateTime date,
    int limit,
  ) async {
    final range = ictDayRangeUtc(date);
    final sales =
        await (_db.select(_db.salesLocal)..where(
              (sale) =>
                  sale.storeId.equals(storeId) &
                  sale.clientCreatedAt.isBiggerOrEqualValue(range.start) &
                  sale.clientCreatedAt.isSmallerThanValue(range.end),
            ))
            .get();

    if (sales.isEmpty) {
      return const TopSkuReport(items: [], isOffline: true);
    }

    final saleIds = sales.map((sale) => sale.id).toSet();
    final lines = await (_db.select(_db.saleLinesLocal)
          ..where((line) => line.saleId.isIn(saleIds)))
        .get();

    final byProduct = <String, ({double qty, int revenueVnd})>{};
    for (final line in lines) {
      final qty = double.parse(line.qty);
      final existing = byProduct[line.productId];
      if (existing == null) {
        byProduct[line.productId] = (qty: qty, revenueVnd: line.lineTotal);
      } else {
        byProduct[line.productId] = (
          qty: existing.qty + qty,
          revenueVnd: existing.revenueVnd + line.lineTotal,
        );
      }
    }

    if (byProduct.isEmpty) {
      return const TopSkuReport(items: [], isOffline: true);
    }

    final productIds = byProduct.keys.toList();
    final products = await (_db.select(_db.products)
          ..where((product) => product.id.isIn(productIds)))
        .get();
    final productById = {for (final product in products) product.id: product};

    final items = byProduct.entries
        .map((entry) {
          final product = productById[entry.key];
          final agg = entry.value;
          return TopSkuItem(
            productId: entry.key,
            sku: product?.sku ?? '',
            name: product?.name ?? '',
            qty: agg.qty,
            revenueVnd: agg.revenueVnd,
            estimatedGrossVnd: product == null
                ? null
                : agg.revenueVnd - (agg.qty * product.costVnd).round(),
          );
        })
        .toList()
      ..sort((a, b) {
        final qtyCmp = b.qty.compareTo(a.qty);
        if (qtyCmp != 0) {
          return qtyCmp;
        }
        return b.revenueVnd.compareTo(a.revenueVnd);
      });

    return TopSkuReport(
      items: items.take(limit).toList(),
      isOffline: true,
    );
  }
}

