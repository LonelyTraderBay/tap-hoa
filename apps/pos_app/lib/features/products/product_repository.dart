import 'package:drift/drift.dart';

import '../../data/local/database.dart';

class ProductWithStock {
  const ProductWithStock({
    required this.id,
    required this.name,
    required this.sku,
    required this.unit,
    required this.basePriceVnd,
    required this.qty,
  });

  final String id;
  final String name;
  final String sku;
  final String unit;
  final int basePriceVnd;
  final String qty;
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
          unit: product.unit,
          basePriceVnd: product.basePriceVnd,
          qty: stock.qty,
        );
      }).toList(),
    );
  }
}
