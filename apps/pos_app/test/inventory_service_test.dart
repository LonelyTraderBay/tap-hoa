import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

import 'package:pos_app/data/local/database.dart';
import 'package:pos_app/features/inventory/inventory_service.dart';

void main() {
  late AppDatabase db;
  late InventoryService service;
  const uuid = Uuid();

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    service = InventoryService(db: db);
    final storeId = uuid.v4();
    final productId = uuid.v4();
    final userId = uuid.v4();
    await db.setMetaValue('currentStoreId', storeId);
    await db.setMetaValue(
      'currentUser',
      '{"id":"$userId","role":"owner","name":"Chu"}',
    );
    await db.into(db.storesLocal).insert(
      StoresLocalCompanion.insert(
        id: storeId,
        code: 'CH1',
        name: 'Cua hang 1',
        updatedAt: DateTime.now(),
      ),
    );
    await db.into(db.products).insert(
      ProductsCompanion.insert(
        id: productId,
        sku: 'SKU-1',
        name: 'Sting',
        unit: 'chai',
        basePriceVnd: 10000,
        updatedAt: DateTime.now(),
      ),
    );
    await db.into(db.productStocks).insert(
      ProductStocksCompanion.insert(
        productId: productId,
        storeId: storeId,
        qty: '10',
        minQty: '0',
        updatedAt: DateTime.now(),
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('recordPurchase increases stock and enqueues outbox', () async {
    final storeId = (await db.metaValue('currentStoreId'))!;
    final product = await db.select(db.products).getSingle();

    await service.recordPurchase(
      supplierName: 'NCC Test',
      lines: [
        InventoryLineInput(productId: product.id, qty: Decimal.fromInt(3)),
      ],
    );

    final stock = await (db.select(db.productStocks)
          ..where(
            (s) =>
                s.productId.equals(product.id) & s.storeId.equals(storeId),
          ))
        .getSingle();
    expect(stock.qty, '13');

    final outbox = await db.pendingOutbox();
    expect(outbox.any((e) => e.entityType == 'purchase_receipt'), isTrue);

    final movements = await db.select(db.stockMovementsLocal).get();
    expect(movements, hasLength(1));
    expect(movements.first.docType, 'purchase');
  });

  test('recordWastage rejects insufficient stock', () async {
    final product = await db.select(db.products).getSingle();
    expect(
      () => service.recordWastage(
        reasonCode: 'spoilage',
        lines: [
          InventoryLineInput(productId: product.id, qty: Decimal.fromInt(99)),
        ],
      ),
      throwsA(isA<StateError>()),
    );
  });
}
