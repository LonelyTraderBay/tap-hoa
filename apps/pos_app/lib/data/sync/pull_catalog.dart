import 'package:dio/dio.dart';

import '../local/database.dart';

class PullCatalog {
  PullCatalog({required AppDatabase db, required Dio dio})
    : _db = db,
      _dio = dio;

  final AppDatabase _db;
  final Dio _dio;

  Future<void> pullCatalog(String storeId) async {
    final since =
        await _db.lastPullAt(storeId) ??
        DateTime.fromMillisecondsSinceEpoch(0);
    final response = await _dio.get<Map<String, dynamic>>(
      '/sync/pull',
      queryParameters: {
        'since': since.toUtc().toIso8601String(),
        'storeId': storeId,
      },
    );
    final data = response.data;
    if (data == null) {
      throw const FormatException('Empty sync pull response');
    }

    final products = (data['products'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final stocks = (data['stocks'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final customers = (data['customers'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final debtLedger = (data['debtLedger'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final serverTime = data['serverTime'] as String?;

    await _db.upsertProductsAndStocks(products: products, stocks: stocks);
    await _db.upsertCustomersAndDebtLedger(
      customers: customers,
      debtLedger: debtLedger,
    );
    if (serverTime != null) {
      await _db.setLastPullAt(storeId, DateTime.parse(serverTime));
    }
  }
}
