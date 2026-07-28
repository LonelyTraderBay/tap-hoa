import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../data/local/database.dart';

class ComboComponentInput {
  const ComboComponentInput({
    required this.componentProductId,
    required this.qtyBase,
  });

  final String componentProductId;
  final String qtyBase;
}

class ProductService {
  ProductService(this._db);

  final AppDatabase _db;
  final _uuid = const Uuid();

  Future<String> create({
    required String storeId,
    required String sku,
    String? barcode,
    required String name,
    required String unit,
    String? sellUnit,
    String? packSize,
    String kind = 'normal',
    String? groupId,
    required bool isWeighted,
    required int basePriceVnd,
    int costVnd = 0,
    bool active = true,
    String initialQty = '0',
    String minQty = '0',
    List<ComboComponentInput> components = const [],
    String? id,
  }) async {
    if (kind == 'combo' && components.isEmpty) {
      throw StateError('invalid_combo');
    }
    final productId = id ?? _uuid.v4();
    final now = DateTime.now().toUtc();
    final trimmedBarcode = _trimOrNull(barcode);
    await _db.transaction(() async {
      await _db.into(_db.products).insert(
        ProductsCompanion.insert(
          id: productId,
          sku: sku.trim(),
          barcode: Value(trimmedBarcode),
          name: name.trim(),
          unit: unit.trim(),
          sellUnit: Value(_trimOrNull(sellUnit)),
          packSize: Value(_trimOrNull(packSize)),
          kind: Value(kind),
          groupId: Value(groupId),
          isWeighted: Value(isWeighted),
          basePriceVnd: basePriceVnd,
          costVnd: Value(costVnd),
          active: Value(active),
          updatedAt: now,
        ),
      );
      await _db.into(_db.productStocks).insert(
        ProductStocksCompanion.insert(
          productId: productId,
          storeId: storeId,
          qty: initialQty,
          minQty: minQty,
          updatedAt: now,
        ),
      );
      await _replaceComponents(productId, components);
      await _enqueueOutbox(
        productId: productId,
        storeId: storeId,
        sku: sku.trim(),
        barcode: trimmedBarcode,
        name: name.trim(),
        unit: unit.trim(),
        sellUnit: _trimOrNull(sellUnit),
        packSize: _trimOrNull(packSize),
        kind: kind,
        groupId: groupId,
        isWeighted: isWeighted,
        basePriceVnd: basePriceVnd,
        costVnd: costVnd,
        active: active,
        seedStock: {'qty': initialQty, 'minQty': minQty},
        components: components,
        createdAt: now,
      );
    });
    return productId;
  }

  Future<void> update({
    required String id,
    required String storeId,
    required String sku,
    String? barcode,
    required String name,
    required String unit,
    String? sellUnit,
    String? packSize,
    String kind = 'normal',
    String? groupId,
    required bool isWeighted,
    required int basePriceVnd,
    int costVnd = 0,
    bool active = true,
    String initialQty = '0',
    String minQty = '0',
    List<ComboComponentInput> components = const [],
  }) async {
    if (kind == 'combo' && components.isEmpty) {
      throw StateError('invalid_combo');
    }
    final now = DateTime.now().toUtc();
    final trimmedBarcode = _trimOrNull(barcode);
    await _db.transaction(() async {
      await (_db.update(_db.products)..where((t) => t.id.equals(id))).write(
        ProductsCompanion(
          sku: Value(sku.trim()),
          barcode: Value(trimmedBarcode),
          name: Value(name.trim()),
          unit: Value(unit.trim()),
          sellUnit: Value(_trimOrNull(sellUnit)),
          packSize: Value(_trimOrNull(packSize)),
          kind: Value(kind),
          groupId: Value(groupId),
          isWeighted: Value(isWeighted),
          basePriceVnd: Value(basePriceVnd),
          costVnd: Value(costVnd),
          active: Value(active),
          updatedAt: Value(now),
        ),
      );

      final existingStock = await (_db.select(_db.productStocks)
            ..where(
              (t) => t.productId.equals(id) & t.storeId.equals(storeId),
            ))
          .getSingleOrNull();

      // minQty ("Tồn tối thiểu") phải luôn được ghi lại — kể cả khi sản phẩm
      // đã có dòng tồn kho tại điểm bán này — nên seedStock luôn được gửi đi.
      // Khi đã có tồn, không đụng tới qty thực tế (giữ nguyên như cũ), chỉ
      // cập nhật minQty; backend (`upsertFromSync`) cũng chỉ áp dụng minQty
      // trong nhánh "existing" đó.
      final Map<String, String> seedStock;
      if (existingStock == null) {
        await _db.into(_db.productStocks).insert(
          ProductStocksCompanion.insert(
            productId: id,
            storeId: storeId,
            qty: initialQty,
            minQty: minQty,
            updatedAt: now,
          ),
        );
        seedStock = {'qty': initialQty, 'minQty': minQty};
      } else {
        await (_db.update(_db.productStocks)
              ..where(
                (t) => t.productId.equals(id) & t.storeId.equals(storeId),
              ))
            .write(
          ProductStocksCompanion(
            minQty: Value(minQty),
            updatedAt: Value(now),
          ),
        );
        seedStock = {'qty': existingStock.qty, 'minQty': minQty};
      }

      await _replaceComponents(id, components);
      await _enqueueOutbox(
        productId: id,
        storeId: storeId,
        sku: sku.trim(),
        barcode: trimmedBarcode,
        name: name.trim(),
        unit: unit.trim(),
        sellUnit: _trimOrNull(sellUnit),
        packSize: _trimOrNull(packSize),
        kind: kind,
        groupId: groupId,
        isWeighted: isWeighted,
        basePriceVnd: basePriceVnd,
        costVnd: costVnd,
        active: active,
        seedStock: seedStock,
        components: components,
        createdAt: now,
      );
    });
  }

  Future<void> _replaceComponents(
    String productId,
    List<ComboComponentInput> components,
  ) async {
    await (_db.delete(_db.productComboComponents)
          ..where((t) => t.comboProductId.equals(productId)))
        .go();
    for (final c in components) {
      await _db.into(_db.productComboComponents).insert(
        ProductComboComponentsCompanion.insert(
          id: _uuid.v4(),
          comboProductId: productId,
          componentProductId: c.componentProductId,
          qtyBase: c.qtyBase,
        ),
      );
    }
  }

  Future<void> _enqueueOutbox({
    required String productId,
    required String storeId,
    required String sku,
    required String? barcode,
    required String name,
    required String unit,
    required String? sellUnit,
    required String? packSize,
    required String kind,
    required String? groupId,
    required bool isWeighted,
    required int basePriceVnd,
    required int costVnd,
    required bool active,
    required Map<String, String> seedStock,
    required List<ComboComponentInput> components,
    required DateTime createdAt,
  }) async {
    final payload = <String, dynamic>{
      'id': productId,
      'sku': sku,
      'barcode': barcode,
      'name': name,
      'unit': unit,
      'sellUnit': sellUnit,
      'packSize': packSize,
      'kind': kind,
      'groupId': groupId,
      'isWeighted': isWeighted,
      'basePriceVnd': basePriceVnd,
      'costVnd': costVnd,
      'active': active,
      'storeId': storeId,
      'seedStock': seedStock,
      'components': [
        for (final c in components)
          {
            'componentProductId': c.componentProductId,
            'qtyBase': c.qtyBase,
          },
      ],
    };
    await _db.into(_db.outboxEntries).insert(
      OutboxEntriesCompanion.insert(
        id: _uuid.v4(),
        entityType: 'product_upsert',
        payloadJson: jsonEncode(payload),
        createdAt: createdAt,
      ),
    );
  }

  String? _trimOrNull(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }
}

class ProductGroupService {
  ProductGroupService(this._db);

  final AppDatabase _db;
  final _uuid = const Uuid();

  Future<String> upsert({
    String? id,
    required String name,
    int sortOrder = 0,
    bool active = true,
  }) async {
    final groupId = id ?? _uuid.v4();
    final now = DateTime.now().toUtc();
    await _db.transaction(() async {
      await _db.into(_db.productGroups).insertOnConflictUpdate(
        ProductGroupsCompanion.insert(
          id: groupId,
          name: name.trim(),
          sortOrder: Value(sortOrder),
          active: Value(active),
          updatedAt: now,
        ),
      );
      await _db.into(_db.outboxEntries).insert(
        OutboxEntriesCompanion.insert(
          id: _uuid.v4(),
          entityType: 'product_group_upsert',
          payloadJson: jsonEncode({
            'id': groupId,
            'name': name.trim(),
            'sortOrder': sortOrder,
            'active': active,
          }),
          createdAt: now,
        ),
      );
    });
    return groupId;
  }
}
