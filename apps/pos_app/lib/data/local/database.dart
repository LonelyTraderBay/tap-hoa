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
    CashCategoriesLocal,
    CashVouchersLocal,
    StockTransfersLocal,
    StockTransferLinesLocal,
    StocktakesLocal,
    StocktakeLinesLocal,
    PurchaseReceiptsLocal,
    PurchaseReceiptLinesLocal,
    WastageVouchersLocal,
    WastageVoucherLinesLocal,
    StockMovementsLocal,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 5;

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
      if (from < 4) {
        await migrator.createTable(cashCategoriesLocal);
        await migrator.createTable(cashVouchersLocal);
        await migrator.addColumn(shiftsLocal, shiftsLocal.expectedCashVnd);
        await migrator.addColumn(shiftsLocal, shiftsLocal.varianceVnd);
        await migrator.addColumn(shiftsLocal, shiftsLocal.transferInShiftVnd);
      }
      if (from < 5) {
        await migrator.createTable(stockTransfersLocal);
        await migrator.createTable(stockTransferLinesLocal);
        await migrator.createTable(stocktakesLocal);
        await migrator.createTable(stocktakeLinesLocal);
        await migrator.createTable(purchaseReceiptsLocal);
        await migrator.createTable(purchaseReceiptLinesLocal);
        await migrator.createTable(wastageVouchersLocal);
        await migrator.createTable(wastageVoucherLinesLocal);
        await migrator.createTable(stockMovementsLocal);
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

  Future<void> upsertCashCategory(Map<String, dynamic> category) {
    return into(cashCategoriesLocal).insertOnConflictUpdate(
      CashCategoriesLocalCompanion.insert(
        id: category['id'] as String,
        code: category['code'] as String,
        name: category['name'] as String,
        direction: category['direction'] as String,
        sortOrder: Value(category['sortOrder'] as int? ?? 0),
      ),
    );
  }

  Future<void> upsertCashVoucher(Map<String, dynamic> voucher) {
    return into(cashVouchersLocal).insertOnConflictUpdate(
      CashVouchersLocalCompanion.insert(
        id: voucher['id'] as String,
        storeId: voucher['storeId'] as String,
        shiftId: voucher['shiftId'] as String,
        categoryId: voucher['categoryId'] as String,
        direction: voucher['direction'] as String,
        channel: voucher['channel'] as String,
        amountVnd: voucher['amountVnd'] as int,
        note: Value(voucher['note'] as String?),
        recordedById: voucher['recordedById'] as String,
        clientCreatedAt: DateTime.parse(voucher['clientCreatedAt'] as String),
        updatedAt: DateTime.parse(voucher['updatedAt'] as String),
      ),
    );
  }

  Future<void> upsertInventoryFromPull({
    required List<Map<String, dynamic>> stockTransfers,
    required List<Map<String, dynamic>> stocktakes,
    required List<Map<String, dynamic>> purchaseReceipts,
    required List<Map<String, dynamic>> wastageVouchers,
    required List<Map<String, dynamic>> stockMovements,
  }) async {
    await transaction(() async {
      for (final t in stockTransfers) {
        await into(stockTransfersLocal).insertOnConflictUpdate(
          StockTransfersLocalCompanion.insert(
            id: t['id'] as String,
            fromStoreId: t['fromStoreId'] as String,
            toStoreId: t['toStoreId'] as String,
            status: t['status'] as String,
            note: Value(t['note'] as String?),
            createdById: t['createdById'] as String,
            approvedById: Value(t['approvedById'] as String?),
            receivedById: Value(t['receivedById'] as String?),
            clientCreatedAt: DateTime.parse(t['clientCreatedAt'] as String),
            approvedAt: Value(
              t['approvedAt'] != null
                  ? DateTime.parse(t['approvedAt'] as String)
                  : null,
            ),
            receivedAt: Value(
              t['receivedAt'] != null
                  ? DateTime.parse(t['receivedAt'] as String)
                  : null,
            ),
            updatedAt: DateTime.parse(t['updatedAt'] as String),
          ),
        );
        for (final line
            in (t['lines'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>()) {
          await into(stockTransferLinesLocal).insertOnConflictUpdate(
            StockTransferLinesLocalCompanion.insert(
              id: line['id'] as String,
              transferId: t['id'] as String,
              productId: line['productId'] as String,
              qty: line['qty'] as String,
            ),
          );
        }
      }
      for (final s in stocktakes) {
        await into(stocktakesLocal).insertOnConflictUpdate(
          StocktakesLocalCompanion.insert(
            id: s['id'] as String,
            storeId: s['storeId'] as String,
            note: Value(s['note'] as String?),
            recordedById: s['recordedById'] as String,
            clientCreatedAt: DateTime.parse(s['clientCreatedAt'] as String),
            updatedAt: DateTime.parse(s['updatedAt'] as String),
          ),
        );
        for (final line
            in (s['lines'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>()) {
          await into(stocktakeLinesLocal).insertOnConflictUpdate(
            StocktakeLinesLocalCompanion.insert(
              id: line['id'] as String,
              stocktakeId: s['id'] as String,
              productId: line['productId'] as String,
              systemQty: line['systemQty'] as String,
              countedQty: line['countedQty'] as String,
              varianceQty: line['varianceQty'] as String,
              reason: line['reason'] as String,
              reasonNote: Value(line['reasonNote'] as String?),
            ),
          );
        }
      }
      for (final r in purchaseReceipts) {
        await into(purchaseReceiptsLocal).insertOnConflictUpdate(
          PurchaseReceiptsLocalCompanion.insert(
            id: r['id'] as String,
            storeId: r['storeId'] as String,
            supplierName: r['supplierName'] as String,
            supplierPhone: Value(r['supplierPhone'] as String?),
            note: Value(r['note'] as String?),
            recordedById: r['recordedById'] as String,
            clientCreatedAt: DateTime.parse(r['clientCreatedAt'] as String),
            updatedAt: DateTime.parse(r['updatedAt'] as String),
          ),
        );
        for (final line
            in (r['lines'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>()) {
          await into(purchaseReceiptLinesLocal).insertOnConflictUpdate(
            PurchaseReceiptLinesLocalCompanion.insert(
              id: line['id'] as String,
              receiptId: r['id'] as String,
              productId: line['productId'] as String,
              qty: line['qty'] as String,
              unitCostVnd: Value(line['unitCostVnd'] as int?),
            ),
          );
        }
      }
      for (final w in wastageVouchers) {
        await into(wastageVouchersLocal).insertOnConflictUpdate(
          WastageVouchersLocalCompanion.insert(
            id: w['id'] as String,
            storeId: w['storeId'] as String,
            reasonCode: w['reasonCode'] as String,
            note: Value(w['note'] as String?),
            recordedById: w['recordedById'] as String,
            clientCreatedAt: DateTime.parse(w['clientCreatedAt'] as String),
            updatedAt: DateTime.parse(w['updatedAt'] as String),
          ),
        );
        for (final line
            in (w['lines'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>()) {
          await into(wastageVoucherLinesLocal).insertOnConflictUpdate(
            WastageVoucherLinesLocalCompanion.insert(
              id: line['id'] as String,
              wastageId: w['id'] as String,
              productId: line['productId'] as String,
              qty: line['qty'] as String,
            ),
          );
        }
      }
      for (final m in stockMovements) {
        await into(stockMovementsLocal).insertOnConflictUpdate(
          StockMovementsLocalCompanion.insert(
            id: m['id'] as String,
            storeId: m['storeId'] as String,
            productId: m['productId'] as String,
            qtyDelta: m['qtyDelta'] as String,
            balanceAfter: m['balanceAfter'] as String,
            docType: m['docType'] as String,
            docId: m['docId'] as String,
            docLineId: Value(m['docLineId'] as String?),
            recordedById: m['recordedById'] as String,
            clientCreatedAt: DateTime.parse(m['clientCreatedAt'] as String),
            updatedAt: DateTime.parse(m['updatedAt'] as String),
          ),
        );
      }
    });
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
