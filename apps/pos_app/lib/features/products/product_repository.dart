import 'package:drift/drift.dart';

import '../../data/local/database.dart';

class ProductWithStock {
  const ProductWithStock({
    required this.id,
    required this.name,
    required this.sku,
    this.barcode,
    required this.unit,
    required this.basePriceVnd,
    required this.qty,
  });

  final String id;
  final String name;
  final String sku;
  final String? barcode;
  final String unit;
  final int basePriceVnd;
  final String qty;
}

class ProductEditData {
  const ProductEditData({
    required this.id,
    required this.sku,
    this.barcode,
    required this.name,
    required this.unit,
    required this.isWeighted,
    required this.basePriceVnd,
    required this.costVnd,
    required this.active,
    required this.qty,
    required this.minQty,
  });

  final String id;
  final String sku;
  final String? barcode;
  final String name;
  final String unit;
  final bool isWeighted;
  final int basePriceVnd;
  final int costVnd;
  final bool active;
  final String qty;
  final String minQty;
}

class ProductRepository {
  ProductRepository(this._db);

  final AppDatabase _db;

  Stream<List<ProductWithStock>> watchByStore(String storeId) {
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

    return ProductEditData(
      id: product.id,
      sku: product.sku,
      barcode: product.barcode,
      name: product.name,
      unit: product.unit,
      isWeighted: product.isWeighted,
      basePriceVnd: product.basePriceVnd,
      costVnd: product.costVnd,
      active: product.active,
      qty: stock?.qty ?? '0',
      minQty: stock?.minQty ?? '0',
    );
  }
}
