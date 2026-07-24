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
    final cashCategories = (data['cashCategories'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final cashVouchers = (data['cashVouchers'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final stockTransfers = (data['stockTransfers'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final stocktakes = (data['stocktakes'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final purchaseReceipts = (data['purchaseReceipts'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final wastageVouchers = (data['wastageVouchers'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final stockMovements = (data['stockMovements'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final serverTime = data['serverTime'] as String?;

    await _db.upsertProductsAndStocks(products: products, stocks: stocks);
    await _db.upsertCustomersAndDebtLedger(
      customers: customers,
      debtLedger: debtLedger,
    );
    for (final category in cashCategories) {
      await _db.upsertCashCategory(category);
    }
    for (final voucher in cashVouchers) {
      await _db.upsertCashVoucher(voucher);
    }
    await _db.upsertInventoryFromPull(
      stockTransfers: stockTransfers,
      stocktakes: stocktakes,
      purchaseReceipts: purchaseReceipts,
      wastageVouchers: wastageVouchers,
      stockMovements: stockMovements,
    );
    if (serverTime != null) {
      await _db.setLastPullAt(storeId, DateTime.parse(serverTime));
    }
  }
}
