import 'package:dio/dio.dart';
import 'package:drift/drift.dart';

import '../../data/local/database.dart';

class StockOnHandItem {
  const StockOnHandItem({
    required this.productId,
    required this.sku,
    required this.name,
    required this.unit,
    required this.qty,
    required this.minQty,
    required this.costVnd,
    required this.estimatedValueVnd,
    required this.belowMin,
  });

  factory StockOnHandItem.fromJson(Map<String, dynamic> json) {
    final qty = (json['qty'] as num).toDouble();
    final minQty = (json['minQty'] as num).toDouble();
    return StockOnHandItem(
      productId: json['productId'] as String,
      sku: json['sku'] as String,
      name: json['name'] as String,
      unit: json['unit'] as String,
      qty: qty,
      minQty: minQty,
      costVnd: json['costVnd'] as int,
      estimatedValueVnd: json['estimatedValueVnd'] as int,
      belowMin: json['belowMin'] as bool,
    );
  }

  final String productId;
  final String sku;
  final String name;
  final String unit;
  final double qty;
  final double minQty;
  final int costVnd;
  final int estimatedValueVnd;
  final bool belowMin;
}

class StockOnHandReport {
  const StockOnHandReport({
    required this.storeId,
    required this.items,
    required this.totalEstimatedValueVnd,
    required this.isOffline,
  });

  factory StockOnHandReport.fromJson(
    Map<String, dynamic> json, {
    bool isOffline = false,
  }) {
    final items = (json['items'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(StockOnHandItem.fromJson)
        .toList();
    return StockOnHandReport(
      storeId: json['storeId'] as String,
      items: items,
      totalEstimatedValueVnd: json['totalEstimatedValueVnd'] as int,
      isOffline: isOffline,
    );
  }

  final String storeId;
  final List<StockOnHandItem> items;
  final int totalEstimatedValueVnd;
  final bool isOffline;
}

List<StockOnHandItem> applyStockOnHandFilters(
  List<StockOnHandItem> items, {
  String query = '',
  bool belowMinOnly = false,
  bool showZero = false,
}) {
  final normalizedQuery = query.trim().toLowerCase();
  return items.where((item) {
    if (!showZero && item.qty == 0) {
      return false;
    }
    if (belowMinOnly && !item.belowMin) {
      return false;
    }
    if (normalizedQuery.isNotEmpty) {
      final haystack = '${item.name} ${item.sku}'.toLowerCase();
      if (!haystack.contains(normalizedQuery)) {
        return false;
      }
    }
    return true;
  }).toList();
}

class StockOnHandRepository {
  StockOnHandRepository({required Dio dio, required AppDatabase db})
    : _dio = dio,
      _db = db;

  final Dio _dio;
  final AppDatabase _db;

  bool _isOfflineNetworkError(DioException error) {
    return error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.unknown;
  }

  Future<StockOnHandReport> fetch({required String storeId}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/reports/stock-on-hand',
        queryParameters: {'storeId': storeId},
      );
      final data = response.data;
      if (data == null) {
        throw StateError('Empty stock-on-hand response');
      }
      return StockOnHandReport.fromJson(data);
    } on DioException catch (error) {
      if (!_isOfflineNetworkError(error)) {
        rethrow;
      }
      return _aggregateFromLocal(storeId);
    }
  }

  Future<StockOnHandReport> _aggregateFromLocal(String storeId) async {
    final query = _db.select(_db.products).join([
      innerJoin(
        _db.productStocks,
        _db.productStocks.productId.equalsExp(_db.products.id),
      ),
    ])
      ..where(
        _db.productStocks.storeId.equals(storeId) &
            _db.products.active.equals(true),
      );

    final rows = await query.get();
    final items = rows.map((row) {
      final product = row.readTable(_db.products);
      final stock = row.readTable(_db.productStocks);
      final qty = double.parse(stock.qty);
      final minQty = double.parse(stock.minQty);
      final estimatedValueVnd = (qty * product.costVnd).round();
      return StockOnHandItem(
        productId: product.id,
        sku: product.sku,
        name: product.name,
        unit: product.unit,
        qty: qty,
        minQty: minQty,
        costVnd: product.costVnd,
        estimatedValueVnd: estimatedValueVnd,
        belowMin: qty < minQty,
      );
    }).toList()
      ..sort((a, b) {
        if (a.belowMin != b.belowMin) {
          return a.belowMin ? -1 : 1;
        }
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

    final totalEstimatedValueVnd = items.fold<int>(
      0,
      (sum, item) => sum + item.estimatedValueVnd,
    );

    return StockOnHandReport(
      storeId: storeId,
      items: items,
      totalEstimatedValueVnd: totalEstimatedValueVnd,
      isOffline: true,
    );
  }
}
