import 'dart:convert';
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
    CustomersLocal,
    DebtLedgerLocal,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
    },
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.createTable(customersLocal);
      }
      if (from < 3) {
        await migrator.addColumn(customersLocal, customersLocal.creditLimitVnd);
        await migrator.createTable(debtLedgerLocal);
      }
    },
  );

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
    return setMetaValue(_lastPullAtKey(storeId), at.toUtc().toIso8601String());
  }

  Future<void> upsertCustomersAndDebtLedger({
    required List<Map<String, dynamic>> customers,
    required List<Map<String, dynamic>> debtLedger,
  }) async {
    await transaction(() async {
      for (final c in customers) {
        await into(customersLocal).insertOnConflictUpdate(
          CustomersLocalCompanion.insert(
            id: c['id'] as String,
            name: c['name'] as String,
            phone: Value(c['phone'] as String?),
            balanceVnd: Value(c['balanceVnd'] as int),
            creditLimitVnd: Value(c['creditLimitVnd'] as int?),
            updatedAt: DateTime.parse(c['updatedAt'] as String),
          ),
        );
      }
      for (final e in debtLedger) {
        await into(debtLedgerLocal).insertOnConflictUpdate(
          DebtLedgerLocalCompanion.insert(
            id: e['id'] as String,
            storeId: e['storeId'] as String,
            customerId: e['customerId'] as String,
            type: e['type'] as String,
            amountVnd: e['amountVnd'] as int,
            balanceAfterVnd: e['balanceAfterVnd'] as int,
            saleId: Value(e['saleId'] as String?),
            shiftId: Value(e['shiftId'] as String?),
            recordedById: e['recordedById'] as String,
            paymentMethod: Value(e['paymentMethod'] as String?),
            note: Value(e['note'] as String?),
            clientCreatedAt: DateTime.parse(e['clientCreatedAt'] as String),
            updatedAt: DateTime.parse(e['updatedAt'] as String),
          ),
        );
      }
    });
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

  Future<List<OutboxEntry>> pendingOutbox({int limit = 50}) {
    return (select(outboxEntries)
          ..where((entry) => entry.status.equals('pending'))
          ..orderBy([(entry) => OrderingTerm.asc(entry.createdAt)])
          ..limit(limit))
        .get();
  }

  Future<void> markOutboxDone(List<String> saleIds) async {
    await markOutboxEntitiesDone('sale', saleIds);
  }

  Future<void> markOutboxEntitiesDone(
    String entityType,
    List<String> entityIds,
  ) async {
    if (entityIds.isEmpty) {
      return;
    }
    final pending = await pendingOutbox(limit: 500);
    final accepted = entityIds.toSet();
    for (final entry in pending) {
      if (entry.entityType != entityType) {
        continue;
      }
      final payload = jsonDecode(entry.payloadJson) as Map<String, dynamic>;
      final entityId = payload['id'] as String?;
      if (entityId == null || !accepted.contains(entityId)) {
        continue;
      }
      await (update(outboxEntries)..where((row) => row.id.equals(entry.id)))
          .write(const OutboxEntriesCompanion(status: Value('done')));
      if (entityType == 'sale') {
        await (update(salesLocal)..where((row) => row.id.equals(entityId)))
            .write(SalesLocalCompanion(syncedAt: Value(DateTime.now())));
      }
    }
  }

  Future<void> markOutboxError(
    String entityId,
    String reason, {
    String? entityType,
  }) async {
    final pending = await pendingOutbox(limit: 500);
    for (final entry in pending) {
      if (entityType != null && entry.entityType != entityType) {
        continue;
      }
      final payload = jsonDecode(entry.payloadJson) as Map<String, dynamic>;
      if (payload['id'] != entityId) {
        continue;
      }
      await (update(
        outboxEntries,
      )..where((row) => row.id.equals(entry.id))).write(
        OutboxEntriesCompanion(
          status: const Value('error'),
          lastError: Value(reason),
        ),
      );
    }
  }

  Stream<SyncStatusSnapshot> watchSyncStatus() {
    final query = select(outboxEntries)
      ..where(
        (entry) =>
            entry.status.equals('pending') | entry.status.equals('error'),
      )
      ..orderBy([(entry) => OrderingTerm.desc(entry.createdAt)]);

    return query.watch().map((entries) {
      final pendingCount = entries
          .where(
            (entry) => entry.status == 'pending' && entry.entityType == 'sale',
          )
          .length;
      final lastError = entries
          .where((entry) => entry.status == 'error' && entry.lastError != null)
          .map((entry) => entry.lastError!)
          .firstOrNull;
      return SyncStatusSnapshot(
        pendingCount: pendingCount,
        lastError: lastError,
      );
    });
  }
}

class SyncStatusSnapshot {
  const SyncStatusSnapshot({required this.pendingCount, this.lastError});

  final int pendingCount;
  final String? lastError;

  bool get isVisible => pendingCount > 0 || lastError != null;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File(path.join(directory.path, 'tap_hoa_pos.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
