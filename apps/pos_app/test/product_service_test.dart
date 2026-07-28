import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pos_app/data/local/database.dart';
import 'package:pos_app/features/products/product_repository.dart';
import 'package:pos_app/features/products/product_service.dart';

void main() {
  late AppDatabase db;
  late ProductService service;
  late ProductRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    service = ProductService(db);
    repository = ProductRepository(db);
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

  test(
    'update on a product that already has stock still sends seedStock '
    '(current qty + new minQty) — regression cho bug G4',
    () async {
      final id = await service.create(
        storeId: 's1',
        sku: 'ABC-1',
        name: 'Test',
        unit: 'chai',
        isWeighted: false,
        basePriceVnd: 10000,
        initialQty: '3',
        minQty: '2',
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
        minQty: '9',
      );

      final product = await (db.select(db.products)..where((t) => t.id.equals(id)))
          .getSingle();
      expect(product.name, 'Updated');
      expect(product.basePriceVnd, 12000);

      // qty thực tế không bị đụng khi update() chỉ đổi minQty trên tồn đã có.
      final stock = await (db.select(db.productStocks)
            ..where((t) => t.productId.equals(id) & t.storeId.equals('s1')))
          .getSingle();
      expect(stock.minQty, '9');
      expect(stock.qty, '3');

      final outbox = await db.pendingOutbox();
      final updateEntry = outbox.last;
      expect(updateEntry.entityType, 'product_upsert');
      final payload = jsonDecode(updateEntry.payloadJson) as Map<String, dynamic>;
      // seedStock luôn phải có mặt — đây chính là kênh backend
      // (`upsertFromSync`) dùng để cập nhật minQty cho tồn đã tồn tại; thiếu
      // seedStock.qty thì backend từ chối luôn cả bản ghi upsert (invalid_product).
      expect(payload.containsKey('seedStock'), isTrue);
      expect(payload['seedStock']['qty'], '3');
      expect(payload['seedStock']['minQty'], '9');
    },
  );

  test(
    'round-trip: sửa minQty trên sản phẩm ĐÃ CÓ tồn kho rồi đọc lại qua '
    'ProductRepository.getForEdit ra đúng giá trị mới',
    () async {
      final id = await service.create(
        storeId: 's1',
        sku: 'ABC-2',
        name: 'Round trip',
        unit: 'chai',
        isWeighted: false,
        basePriceVnd: 15000,
        initialQty: '10',
        minQty: '1',
      );

      final before = await repository.getForEdit(id, 's1');
      expect(before, isA<ProductEditData>());
      expect(before!.minQty, '1');

      await service.update(
        id: id,
        storeId: 's1',
        sku: 'ABC-2',
        name: 'Round trip',
        unit: 'chai',
        isWeighted: false,
        basePriceVnd: 15000,
        active: true,
        minQty: '7',
      );

      final after = await repository.getForEdit(id, 's1');
      expect(after, isA<ProductEditData>());
      expect(after!.minQty, '7');
      // Tồn thực tế (qty) không bị reset về initialQty mặc định ('0') khi
      // sửa sản phẩm đã tồn tại — chỉ minQty được đổi.
      expect(after.qty, '10');
    },
  );
}
