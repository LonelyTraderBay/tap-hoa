import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    Products,
    ProductStocks,
    OutboxEntries,
    SalesLocal,
    SaleLinesLocal,
    ShiftsLocal,
    StoresLocal,
    MetaLocal,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  Future<String?> metaValue(String key) async {
    final row = await (select(
      metaLocal,
    )..where((table) => table.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<void> setMetaValue(String key, String value) {
    return into(metaLocal).insertOnConflictUpdate(
      MetaLocalCompanion.insert(
        key: key,
        value: value,
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  String _lastPullAtKey(String storeId) => 'lastPullAt:$storeId';

  Future<DateTime?> lastPullAt(String storeId) async {
    final value = await metaValue(_lastPullAtKey(storeId));
    if (value == null) {
      return null;
    }
    return DateTime.parse(value);
  }

  Future<void> setLastPullAt(String storeId, DateTime at) {
    return setMetaValue(
      _lastPullAtKey(storeId),
      at.toUtc().toIso8601String(),
    );
  }

  Future<void> upsertProductsAndStocks({
    required List<Map<String, dynamic>> products,
    required List<Map<String, dynamic>> stocks,
  }) async {
    await transaction(() async {
      for (final product in products) {
        await into(this.products).insertOnConflictUpdate(
          ProductsCompanion.insert(
            id: product['id'] as String,
            sku: product['sku'] as String,
            barcode: Value(product['barcode'] as String?),
            name: product['name'] as String,
            unit: product['unit'] as String,
            isWeighted: Value(product['isWeighted'] as bool? ?? false),
            basePriceVnd: product['basePriceVnd'] as int,
            costVnd: Value(product['costVnd'] as int? ?? 0),
            active: Value(product['active'] as bool? ?? true),
            updatedAt: DateTime.parse(product['updatedAt'] as String),
          ),
        );
      }

      for (final stock in stocks) {
        await into(productStocks).insertOnConflictUpdate(
          ProductStocksCompanion.insert(
            productId: stock['productId'] as String,
            storeId: stock['storeId'] as String,
            qty: stock['qty'] as String,
            minQty: stock['minQty'] as String,
            updatedAt: DateTime.parse(stock['updatedAt'] as String),
          ),
        );
      }
    });
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File(path.join(directory.path, 'tap_hoa_pos.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
