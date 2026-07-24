import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../data/local/database.dart';

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
    required bool isWeighted,
    required int basePriceVnd,
    int costVnd = 0,
    bool active = true,
    String initialQty = '0',
    String minQty = '0',
    String? id,
  }) async {
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
      await _enqueueOutbox(
        productId: productId,
        storeId: storeId,
        sku: sku.trim(),
        barcode: trimmedBarcode,
        name: name.trim(),
        unit: unit.trim(),
        isWeighted: isWeighted,
        basePriceVnd: basePriceVnd,
        costVnd: costVnd,
        active: active,
        seedStock: {'qty': initialQty, 'minQty': minQty},
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
    required bool isWeighted,
    required int basePriceVnd,
    int costVnd = 0,
    bool active = true,
    String initialQty = '0',
    String minQty = '0',
  }) async {
    final now = DateTime.now().toUtc();
    final trimmedBarcode = _trimOrNull(barcode);
    await _db.transaction(() async {
      await (_db.update(_db.products)..where((t) => t.id.equals(id))).write(
        ProductsCompanion(
          sku: Value(sku.trim()),
          barcode: Value(trimmedBarcode),
          name: Value(name.trim()),
          unit: Value(unit.trim()),
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

      Map<String, String>? seedStock;
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
      }

      await _enqueueOutbox(
        productId: id,
        storeId: storeId,
        sku: sku.trim(),
        barcode: trimmedBarcode,
        name: name.trim(),
        unit: unit.trim(),
        isWeighted: isWeighted,
        basePriceVnd: basePriceVnd,
        costVnd: costVnd,
        active: active,
        seedStock: seedStock,
        createdAt: now,
      );
    });
  }

  Future<void> _enqueueOutbox({
    required String productId,
    required String storeId,
    required String sku,
    required String? barcode,
    required String name,
    required String unit,
    required bool isWeighted,
    required int basePriceVnd,
    required int costVnd,
    required bool active,
    required Map<String, String>? seedStock,
    required DateTime createdAt,
  }) async {
    final payload = <String, dynamic>{
      'id': productId,
      'sku': sku,
      'barcode': barcode,
      'name': name,
      'unit': unit,
      'isWeighted': isWeighted,
      'basePriceVnd': basePriceVnd,
      'costVnd': costVnd,
      'active': active,
      'storeId': storeId,
    };
    if (seedStock != null) {
      payload['seedStock'] = seedStock;
    }
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
