import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pos_app/data/local/database.dart';
import 'package:pos_app/features/pos/cart.dart';
import 'package:pos_app/features/pos/checkout_service.dart';
import 'package:pos_app/features/products/product_service.dart';
import 'package:pos_app/features/shifts/shift_repository.dart';
import 'package:dio/dio.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late AppDatabase db;
  late ShiftRepository shiftRepository;
  late CheckoutService checkout;
  late ProductService products;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    shiftRepository = ShiftRepository(dio: MockDio(), db: db);
    checkout = CheckoutService(db: db, shiftRepository: shiftRepository);
    products = ProductService(db);
  });

  tearDown(() => db.close());

  test('combo checkout decrements component stock; empty combo rejected', () async {
    expect(
      () => products.create(
        storeId: 'store-1',
        sku: 'COMBO-EMPTY',
        name: 'Empty',
        unit: 'bo',
        kind: 'combo',
        isWeighted: false,
        basePriceVnd: 20000,
        initialQty: '0',
        components: const [],
      ),
      throwsA(
        isA<StateError>().having((e) => e.message, 'message', 'invalid_combo'),
      ),
    );

    await db.into(db.products).insert(
      ProductsCompanion.insert(
        id: 'px',
        sku: 'X',
        name: 'X',
        unit: 'chai',
        basePriceVnd: 10000,
        updatedAt: DateTime(2026),
      ),
    );
    await db.into(db.products).insert(
      ProductsCompanion.insert(
        id: 'py',
        sku: 'Y',
        name: 'Y',
        unit: 'chai',
        basePriceVnd: 5000,
        updatedAt: DateTime(2026),
      ),
    );
    await db.into(db.productStocks).insert(
      ProductStocksCompanion.insert(
        productId: 'px',
        storeId: 'store-1',
        qty: '10',
        minQty: '0',
        updatedAt: DateTime(2026),
      ),
    );
    await db.into(db.productStocks).insert(
      ProductStocksCompanion.insert(
        productId: 'py',
        storeId: 'store-1',
        qty: '10',
        minQty: '0',
        updatedAt: DateTime(2026),
      ),
    );

    final comboId = await products.create(
      storeId: 'store-1',
      sku: 'COMBO-A',
      name: 'Combo A',
      unit: 'bo',
      kind: 'combo',
      isWeighted: false,
      basePriceVnd: 20000,
      initialQty: '0',
      components: const [
        ComboComponentInput(componentProductId: 'px', qtyBase: '1'),
        ComboComponentInput(componentProductId: 'py', qtyBase: '2'),
      ],
    );

    await db.setMetaValue('currentStoreId', 'store-1');
    await db.setMetaValue(
      'currentUser',
      jsonEncode({
        'id': 'user-1',
        'name': 'Cashier',
        'role': 'cashier',
        'storeIds': ['store-1'],
      }),
    );
    await shiftRepository.openShift(
      storeId: 'store-1',
      openingCash: 100000,
      userId: 'user-1',
    );

    final cart = Cart();
    cart.add(
      CartLine(
        productId: comboId,
        name: 'Combo A',
        unitPrice: 20000,
        qty: Decimal.one,
      ),
    );
    await checkout.complete(
      cart: cart,
      payment: const PaymentSplit(cash: 20000),
    );

    final stockX = await (db.select(db.productStocks)
          ..where(
            (t) => t.productId.equals('px') & t.storeId.equals('store-1'),
          ))
        .getSingle();
    final stockY = await (db.select(db.productStocks)
          ..where(
            (t) => t.productId.equals('py') & t.storeId.equals('store-1'),
          ))
        .getSingle();
    expect(stockX.qty, '9');
    expect(stockY.qty, '8');
  });
}
