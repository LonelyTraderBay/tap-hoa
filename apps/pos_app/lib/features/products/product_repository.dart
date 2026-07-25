import 'package:drift/drift.dart';

import '../../data/local/database.dart';

class ProductWithStock {
  const ProductWithStock({
    required this.id,
    required this.name,
    required this.sku,
    this.barcode,
    required this.unit,
    this.sellUnit,
    this.packSize,
    this.kind = 'normal',
    this.groupId,
    required this.isWeighted,
    required this.basePriceVnd,
    required this.qty,
  });

  final String id;
  final String name;
  final String sku;
  final String? barcode;
  final String unit;
  final String? sellUnit;
  final String? packSize;
  final String kind;
  final String? groupId;
  final bool isWeighted;
  final int basePriceVnd;
  final String qty;

  String get displayUnit => sellUnit?.isNotEmpty == true ? sellUnit! : unit;
}

class ProductEditData {
  const ProductEditData({
    required this.id,
    required this.sku,
    this.barcode,
    required this.name,
    required this.unit,
    this.sellUnit,
    this.packSize,
    this.kind = 'normal',
    this.groupId,
    required this.isWeighted,
    required this.basePriceVnd,
    required this.costVnd,
    required this.active,
    required this.qty,
    required this.minQty,
    this.components = const [],
  });

  final String id;
  final String sku;
  final String? barcode;
  final String name;
  final String unit;
  final String? sellUnit;
  final String? packSize;
  final String kind;
  final String? groupId;
  final bool isWeighted;
  final int basePriceVnd;
  final int costVnd;
  final bool active;
  final String qty;
  final String minQty;
  final List<({String componentProductId, String qtyBase, String name})>
      components;
}

class ProductGroupRow {
  const ProductGroupRow({
    required this.id,
    required this.name,
    required this.sortOrder,
    required this.active,
  });

  final String id;
  final String name;
  final int sortOrder;
  final bool active;
}

class ProductRepository {
  ProductRepository(this._db);

  final AppDatabase _db;

  Stream<List<ProductGroupRow>> watchGroups({bool activeOnly = true}) {
    final query = _db.select(_db.productGroups)
      ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]);
    if (activeOnly) {
      query.where((t) => t.active.equals(true));
    }
    return query.watch().map(
      (rows) => rows
          .map(
            (g) => ProductGroupRow(
              id: g.id,
              name: g.name,
              sortOrder: g.sortOrder,
              active: g.active,
            ),
          )
          .toList(),
    );
  }

  Stream<List<ProductWithStock>> watchByStore(
    String storeId, {
    String? groupId,
  }) {
    final query = _db.select(_db.products).join([
      innerJoin(
        _db.productStocks,
        _db.productStocks.productId.equalsExp(_db.products.id),
      ),
    ])
      ..where(
        _db.productStocks.storeId.equals(storeId) &
            _db.products.active.equals(true),
      )
      ..orderBy([OrderingTerm.asc(_db.products.name)]);

    if (groupId != null) {
      query.where(_db.products.groupId.equals(groupId));
    }

    return query.watch().map(
      (rows) => rows.map((row) {
        final product = row.readTable(_db.products);
        final stock = row.readTable(_db.productStocks);
        return ProductWithStock(
          id: product.id,
          name: product.name,
          sku: product.sku,
          barcode: product.barcode,
          unit: product.unit,
          sellUnit: product.sellUnit,
          packSize: product.packSize,
          kind: product.kind,
          groupId: product.groupId,
          isWeighted: product.isWeighted,
          basePriceVnd: product.basePriceVnd,
          qty: stock.qty,
        );
      }).toList(),
    );
  }

  Future<List<ProductWithStock>> listWithStock(String storeId) {
    return watchByStore(storeId).first;
  }

  Future<ProductEditData?> getForEdit(String productId, String storeId) async {
    final product = await (_db.select(_db.products)
          ..where((t) => t.id.equals(productId)))
        .getSingleOrNull();
    if (product == null) return null;

    final stock = await (_db.select(_db.productStocks)
          ..where(
            (t) => t.productId.equals(productId) & t.storeId.equals(storeId),
          ))
        .getSingleOrNull();

    final components = await (_db.select(_db.productComboComponents)
          ..where((t) => t.comboProductId.equals(productId)))
        .get();
    final componentRows =
        <({String componentProductId, String qtyBase, String name})>[];
    for (final c in components) {
      final p = await (_db.select(_db.products)
            ..where((t) => t.id.equals(c.componentProductId)))
          .getSingleOrNull();
      componentRows.add((
        componentProductId: c.componentProductId,
        qtyBase: c.qtyBase,
        name: p?.name ?? c.componentProductId,
      ));
    }

    return ProductEditData(
      id: product.id,
      sku: product.sku,
      barcode: product.barcode,
      name: product.name,
      unit: product.unit,
      sellUnit: product.sellUnit,
      packSize: product.packSize,
      kind: product.kind,
      groupId: product.groupId,
      isWeighted: product.isWeighted,
      basePriceVnd: product.basePriceVnd,
      costVnd: product.costVnd,
      active: product.active,
      qty: stock?.qty ?? '0',
      minQty: stock?.minQty ?? '0',
      components: componentRows,
    );
  }
}
