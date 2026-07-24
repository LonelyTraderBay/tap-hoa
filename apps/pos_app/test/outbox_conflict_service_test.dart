import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pos_app/data/local/database.dart';
import 'package:pos_app/data/sync/outbox_worker.dart';
import 'package:pos_app/features/sync/outbox_conflict_service.dart';
import 'package:pos_app/features/sync/outbox_reason_labels.dart';

class MockOutboxWorker extends Mock implements OutboxWorker {}

void main() {
  late AppDatabase db;
  late MockOutboxWorker worker;
  late OutboxConflictService service;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    worker = MockOutboxWorker();
    when(() => worker.tick()).thenAnswer((_) async {});
    service = OutboxConflictService(db: db, worker: worker);
  });

  tearDown(() => db.close());

  group('reason labels', () {
    test('maps known outbox reason codes to Vietnamese', () {
      expect(labelOutboxReason('insufficient_stock'), 'Không đủ tồn kho');
      expect(labelOutboxReason('sku_conflict'), 'Trùng mã SKU');
      expect(labelOutboxReason('barcode_conflict'), 'Trùng mã vạch');
      expect(labelOutboxReason('credit_limit_exceeded'), 'Vượt hạn mức nợ');
      expect(labelOutboxReason('store_forbidden'), 'Không có quyền / cửa hàng');
      expect(labelOutboxReason('role_forbidden'), 'Không có quyền / cửa hàng');
      expect(labelOutboxReason('shift_not_open'), 'Ca chưa mở / không tìm thấy ca');
      expect(labelOutboxReason('shift_not_found'), 'Ca chưa mở / không tìm thấy ca');
      expect(labelOutboxReason('invalid_payload'), 'Dữ liệu không hợp lệ');
      expect(labelOutboxReason('invalid_qty'), 'Dữ liệu không hợp lệ');
    });

    test('falls back to raw code for unknown reasons', () {
      expect(labelOutboxReason('custom_server_code'), 'custom_server_code');
      expect(labelOutboxReason(null), isNull);
    });

    test('maps entity types to Vietnamese labels', () {
      expect(labelEntityType('sale'), 'Bán hàng');
      expect(labelEntityType('wastage'), 'Phiếu xuất hủy');
      expect(labelEntityType('product_upsert'), 'Sản phẩm');
      expect(labelEntityType('unknown_type'), 'unknown_type');
    });
  });

  group('listErrors', () {
    test('returns only error rows newest first', () async {
      await db.into(db.outboxEntries).insert(
        OutboxEntriesCompanion.insert(
          id: 'err-old',
          entityType: 'sale',
          payloadJson: '{}',
          createdAt: DateTime(2026, 1, 1),
          status: const Value('error'),
          lastError: const Value('insufficient_stock'),
        ),
      );
      await db.into(db.outboxEntries).insert(
        OutboxEntriesCompanion.insert(
          id: 'err-new',
          entityType: 'sale',
          payloadJson: '{}',
          createdAt: DateTime(2026, 1, 2),
          status: const Value('error'),
          lastError: const Value('sku_conflict'),
        ),
      );
      await db.into(db.outboxEntries).insert(
        OutboxEntriesCompanion.insert(
          id: 'pending-1',
          entityType: 'sale',
          payloadJson: '{}',
          createdAt: DateTime(2026, 1, 3),
        ),
      );

      final errors = await service.listErrors();
      expect(errors.map((e) => e.id), ['err-new', 'err-old']);
    });
  });

  group('retry', () {
    Future<void> seedErrorOutbox(String outboxRowId) async {
      await db.into(db.outboxEntries).insert(
        OutboxEntriesCompanion.insert(
          id: outboxRowId,
          entityType: 'sale',
          payloadJson: jsonEncode({'id': 'sale-1'}),
          createdAt: DateTime(2026),
          status: const Value('error'),
          lastError: const Value('insufficient_stock'),
        ),
      );
    }

    test('requeue clears error and calls worker tick', () async {
      const outboxRowId = 'outbox-row-1';
      await seedErrorOutbox(outboxRowId);

      await service.retry(outboxRowId);

      final row = await (db.select(db.outboxEntries)
            ..where((r) => r.id.equals(outboxRowId)))
          .getSingle();
      expect(row.status, 'pending');
      expect(row.lastError, isNull);
      verify(() => worker.tick()).called(1);
    });

    test('retryAll requeues every error then ticks once', () async {
      await seedErrorOutbox('outbox-a');
      await seedErrorOutbox('outbox-b');

      await service.retryAll();

      final rows = await db.select(db.outboxEntries).get();
      expect(rows.every((r) => r.status == 'pending' && r.lastError == null), isTrue);
      verify(() => worker.tick()).called(1);
    });
  });

  group('saveRawJson', () {
    test('rejects invalid JSON', () async {
      await db.into(db.outboxEntries).insert(
        OutboxEntriesCompanion.insert(
          id: 'outbox-raw',
          entityType: 'sale',
          payloadJson: '{}',
          createdAt: DateTime(2026),
          status: const Value('error'),
        ),
      );

      await expectLater(
        service.saveRawJson('outbox-raw', 'not-json'),
        throwsA(isA<FormatException>()),
      );
      await expectLater(
        service.saveRawJson('outbox-raw', '["array"]'),
        throwsA(isA<FormatException>()),
      );
    });

    test('saves valid object, requeues, and ticks', () async {
      const outboxRowId = 'outbox-raw-ok';
      await db.into(db.outboxEntries).insert(
        OutboxEntriesCompanion.insert(
          id: outboxRowId,
          entityType: 'sale',
          payloadJson: jsonEncode({'id': 'sale-1', 'totalVnd': 1000}),
          createdAt: DateTime(2026),
          status: const Value('error'),
          lastError: const Value('invalid_payload'),
        ),
      );

      const newJson = '{"id":"sale-1","totalVnd":2000}';
      await service.saveRawJson(outboxRowId, newJson);

      final row = await (db.select(db.outboxEntries)
            ..where((r) => r.id.equals(outboxRowId)))
          .getSingle();
      expect(row.payloadJson, newJson);
      expect(row.status, 'pending');
      expect(row.lastError, isNull);
      verify(() => worker.tick()).called(1);
    });
  });

  group('saveProductUpsertIdentity', () {
    test('updates payload and local product then requeues', () async {
      const productId = 'prod-1';
      const outboxRowId = 'outbox-prod-1';
      await db.into(db.products).insert(
        ProductsCompanion.insert(
          id: productId,
          sku: 'OLD-SKU',
          barcode: const Value('111'),
          name: 'Test',
          unit: 'cái',
          basePriceVnd: 10000,
          updatedAt: DateTime(2026),
        ),
      );
      await db.into(db.outboxEntries).insert(
        OutboxEntriesCompanion.insert(
          id: outboxRowId,
          entityType: 'product_upsert',
          payloadJson: jsonEncode({
            'id': productId,
            'sku': 'OLD-SKU',
            'barcode': '111',
            'name': 'Test',
          }),
          createdAt: DateTime(2026),
          status: const Value('error'),
          lastError: const Value('sku_conflict'),
        ),
      );

      await service.saveProductUpsertIdentity(
        outboxRowId: outboxRowId,
        sku: 'NEW-SKU',
        barcode: '222',
      );

      final product = await (db.select(db.products)
            ..where((p) => p.id.equals(productId)))
          .getSingle();
      expect(product.sku, 'NEW-SKU');
      expect(product.barcode, '222');

      final outbox = await (db.select(db.outboxEntries)
            ..where((r) => r.id.equals(outboxRowId)))
          .getSingle();
      final payload = jsonDecode(outbox.payloadJson) as Map<String, dynamic>;
      expect(payload['sku'], 'NEW-SKU');
      expect(payload['barcode'], '222');
      expect(outbox.status, 'pending');
      verify(() => worker.tick()).called(1);
    });
  });

  group('saveInsufficientStockQtys', () {
    Future<String> seedSaleWithStock({
      required String saleId,
      required String outboxRowId,
      String qty = '2',
      String stockQty = '8',
    }) async {
      await db.into(db.products).insert(
        ProductsCompanion.insert(
          id: 'p1',
          sku: 'SKU-1',
          name: 'Product',
          unit: 'cái',
          basePriceVnd: 10000,
          updatedAt: DateTime(2026),
        ),
      );
      await db.into(db.productStocks).insert(
        ProductStocksCompanion.insert(
          productId: 'p1',
          storeId: 'store-1',
          qty: stockQty,
          minQty: '0',
          updatedAt: DateTime(2026),
        ),
      );
      await db.into(db.salesLocal).insert(
        SalesLocalCompanion.insert(
          id: saleId,
          storeId: 'store-1',
          shiftId: 'shift-1',
          paymentMethod: 'cash',
          totalVnd: 20000,
          cashAmount: 20000,
          transferAmount: 0,
          debtAmount: 0,
          clientCreatedAt: DateTime(2026),
        ),
      );
      await db.into(db.saleLinesLocal).insert(
        SaleLinesLocalCompanion.insert(
          id: 'line-1',
          saleId: saleId,
          productId: 'p1',
          qty: qty,
          unitPrice: 10000,
          lineTotal: 20000,
        ),
      );
      await db.into(db.outboxEntries).insert(
        OutboxEntriesCompanion.insert(
          id: outboxRowId,
          entityType: 'sale',
          payloadJson: jsonEncode({
            'id': saleId,
            'storeId': 'store-1',
            'shiftId': 'shift-1',
            'soldById': 'user-1',
            'paymentMethod': 'cash',
            'cashAmount': 20000,
            'transferAmount': 0,
            'debtAmount': 0,
            'discountVnd': 0,
            'totalVnd': 20000,
            'clientCreatedAt': DateTime.utc(2026).toIso8601String(),
            'lines': [
              {
                'productId': 'p1',
                'qty': qty,
                'unitPrice': 10000,
                'lineTotal': 20000,
              },
            ],
          }),
          createdAt: DateTime(2026),
          status: const Value('error'),
          lastError: const Value('insufficient_stock'),
        ),
      );
      return saleId;
    }

    test('sale qty decrease updates line, stock, total, and requeues', () async {
      const saleId = 'sale-qty';
      const outboxRowId = 'outbox-sale-qty';
      await seedSaleWithStock(saleId: saleId, outboxRowId: outboxRowId);

      final localSynced = await service.saveInsufficientStockQtys(
        outboxRowId: outboxRowId,
        productIdToQty: const {'p1': '1'},
      );

      expect(localSynced, isTrue);

      final line = await (db.select(db.saleLinesLocal)
            ..where((l) => l.saleId.equals(saleId) & l.productId.equals('p1')))
          .getSingle();
      expect(line.qty, '1');
      expect(line.lineTotal, 10000);

      final stock = await (db.select(db.productStocks)
            ..where(
              (s) => s.productId.equals('p1') & s.storeId.equals('store-1'),
            ))
          .getSingle();
      expect(Decimal.parse(stock.qty), Decimal.parse('9'));

      final sale = await (db.select(db.salesLocal)
            ..where((s) => s.id.equals(saleId)))
          .getSingle();
      expect(sale.totalVnd, 10000);
      expect(sale.cashAmount, 10000);

      final outbox = await (db.select(db.outboxEntries)
            ..where((r) => r.id.equals(outboxRowId)))
          .getSingle();
      final payload = jsonDecode(outbox.payloadJson) as Map<String, dynamic>;
      expect(payload['totalVnd'], 10000);
      expect((payload['lines'] as List).single['qty'], '1');
      expect(outbox.status, 'pending');
      verify(() => worker.tick()).called(1);
    });

    test('throws use_raw_json for unsupported entity types', () async {
      await db.into(db.outboxEntries).insert(
        OutboxEntriesCompanion.insert(
          id: 'outbox-transfer',
          entityType: 'stock_transfer_create',
          payloadJson: jsonEncode({
            'id': 'xfer-1',
            'lines': [
              {'productId': 'p1', 'qty': '1'},
            ],
          }),
          createdAt: DateTime(2026),
          status: const Value('error'),
        ),
      );

      await expectLater(
        service.saveInsufficientStockQtys(
          outboxRowId: 'outbox-transfer',
          productIdToQty: const {'p1': '2'},
        ),
        throwsA(
          predicate<StateError>((e) => e.message == 'use_raw_json'),
        ),
      );
    });
  });
}
