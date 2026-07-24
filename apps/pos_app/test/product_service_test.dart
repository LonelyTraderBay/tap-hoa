import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pos_app/data/local/database.dart';
import 'package:pos_app/features/products/product_service.dart';

void main() {
  late AppDatabase db;
  late ProductService service;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    service = ProductService(db);
  });

  tearDown(() => db.close());

  test('create inserts product, stock for store, and product_upsert outbox', () async {
    final id = await service.create(
      storeId: 's1',
      sku: 'ABC-1',
      name: 'Test',
      unit: 'chai',
      isWeighted: false,
      basePriceVnd: 10000,
      costVnd: 7000,
      active: true,
      initialQty: '3',
      minQty: '0',
    );
    final product = await (db.select(db.products)..where((t) => t.id.equals(id)))
        .getSingle();
    expect(product.sku, 'ABC-1');
    final stock = await (db.select(db.productStocks)
          ..where((t) => t.productId.equals(id) & t.storeId.equals('s1')))
        .getSingle();
    expect(stock.qty, '3');
    final outbox = await db.pendingOutbox();
    expect(outbox.single.entityType, 'product_upsert');
    final payload = jsonDecode(outbox.single.payloadJson) as Map<String, dynamic>;
    expect(payload['seedStock']['qty'], '3');
  });

  test('update changes fields and omits seedStock when stock exists', () async {
    final id = await service.create(
      storeId: 's1',
      sku: 'ABC-1',
      name: 'Test',
      unit: 'chai',
      isWeighted: false,
      basePriceVnd: 10000,
      initialQty: '3',
    );

    await service.update(
      id: id,
      storeId: 's1',
      sku: 'ABC-1',
      name: 'Updated',
      unit: 'chai',
      isWeighted: false,
      basePriceVnd: 12000,
      costVnd: 7000,
      active: true,
    );

    final product = await (db.select(db.products)..where((t) => t.id.equals(id)))
        .getSingle();
    expect(product.name, 'Updated');
    expect(product.basePriceVnd, 12000);

    final outbox = await db.pendingOutbox();
    final updateEntry = outbox.last;
    expect(updateEntry.entityType, 'product_upsert');
    final payload = jsonDecode(updateEntry.payloadJson) as Map<String, dynamic>;
    expect(payload.containsKey('seedStock'), isFalse);
  });
}
