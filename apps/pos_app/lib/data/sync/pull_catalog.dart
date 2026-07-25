import 'package:dio/dio.dart';
import 'package:drift/drift.dart';

import '../local/database.dart';

class PullCatalog {
  PullCatalog({required AppDatabase db, required Dio dio})
    : _db = db,
      _dio = dio;

  final AppDatabase _db;
  final Dio _dio;

  Future<void> pullCatalog(String storeId) async {
    final since =
        await _db.lastPullAt(storeId) ?? DateTime.fromMillisecondsSinceEpoch(0);
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
    final productGroups = (data['productGroups'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final comboComponents = (data['comboComponents'] as List<dynamic>? ?? [])
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
    final purchaseOrders = (data['purchaseOrders'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final purchaseReceipts = (data['purchaseReceipts'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final wastageVouchers = (data['wastageVouchers'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final stockMovements = (data['stockMovements'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final store = data['store'] as Map<String, dynamic>?;
    final serverTime = data['serverTime'] as String?;

    await _db.upsertProductsAndStocks(
      products: products,
      stocks: stocks,
      productGroups: productGroups,
      comboComponents: comboComponents,
    );
    if (store != null) {
      await _db
          .into(_db.storesLocal)
          .insertOnConflictUpdate(
            StoresLocalCompanion.insert(
              id: store['id'] as String,
              code: store['code'] as String,
              name: store['name'] as String,
              active: Value(store['active'] as bool? ?? true),
              debtOverdueDays: Value(store['debtOverdueDays'] as int? ?? 30),
              largeDebtThresholdVnd: Value(
                store['largeDebtThresholdVnd'] as int?,
              ),
              updatedAt: DateTime.parse(store['updatedAt'] as String),
            ),
          );
    }
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
      purchaseOrders: purchaseOrders,
      purchaseReceipts: purchaseReceipts,
      wastageVouchers: wastageVouchers,
      stockMovements: stockMovements,
    );
    if (serverTime != null) {
      await _db.setLastPullAt(storeId, DateTime.parse(serverTime));
    }
  }

  /// Convenience: pull then run low-stock checks via [onAfterPull].
  Future<void> pullCatalogAndNotify(
    String storeId, {
    Future<void> Function(String storeId)? onAfterPull,
  }) async {
    await pullCatalog(storeId);
    if (onAfterPull != null) {
      await onAfterPull(storeId);
    }
  }
}
