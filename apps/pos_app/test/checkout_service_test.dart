import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pos_app/data/local/database.dart';
import 'package:pos_app/features/pos/cart.dart';
import 'package:pos_app/features/pos/checkout_service.dart';
import 'package:pos_app/features/shifts/shift_repository.dart';
import 'package:dio/dio.dart';

class MockDio extends Mock implements Dio {}

Future<void> seedProductStock(
  AppDatabase db, {
  String productId = 'p1',
  String storeId = 'store-1',
  String qty = '10',
}) async {
  await db.into(db.products).insert(
    ProductsCompanion.insert(
      id: productId,
      sku: 'STING-330',
      name: 'Sting',
      unit: 'chai',
      basePriceVnd: 10000,
      updatedAt: DateTime(2026),
    ),
  );
  await db.into(db.productStocks).insert(
    ProductStocksCompanion.insert(
      productId: productId,
      storeId: storeId,
      qty: qty,
      minQty: '0',
      updatedAt: DateTime(2026),
    ),
  );
}

Future<void> seedSession(AppDatabase db) async {
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
}

Future<void> openShift(ShiftRepository repository) {
  return repository.openShift(
    storeId: 'store-1',
    openingCash: 500000,
    userId: 'user-1',
  );
}

Cart cartWithStingQty2() {
  final cart = Cart();
  cart.add(
    CartLine(
      productId: 'p1',
      name: 'Sting',
      unitPrice: 10000,
      qty: Decimal.parse('2'),
    ),
  );
  return cart;
}

void main() {
  late AppDatabase db;
  late ShiftRepository shiftRepository;
  late CheckoutService checkout;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    shiftRepository = ShiftRepository(dio: MockDio(), db: db);
    checkout = CheckoutService(db: db, shiftRepository: shiftRepository);
  });

  tearDown(() => db.close());

  test('checkout writes sale and decrements stock', () async {
    await seedProductStock(db);
    await seedSession(db);
    await openShift(shiftRepository);

    final id = await checkout.complete(
      cart: cartWithStingQty2(),
      payment: const PaymentSplit(cash: 20000),
    );

    final stock = await (db.select(db.productStocks)
          ..where(
            (row) =>
                row.productId.equals('p1') & row.storeId.equals('store-1'),
          ))
        .getSingle();
    expect(stock.qty, '8');

    final outbox = await (db.select(db.outboxEntries)
          ..where(
            (entry) =>
                entry.status.equals('pending') &
                entry.entityType.equals('sale'),
          ))
        .get();
    expect(outbox.single.entityType, 'sale');
    expect(id, isNotEmpty);

    final sales = await db.select(db.salesLocal).get();
    expect(sales.single.totalVnd, 20000);
    expect(sales.single.cashAmount, 20000);
  });

  test('checkout rejects payment mismatch', () async {
    await seedProductStock(db);
    await seedSession(db);
    await openShift(shiftRepository);

    await expectLater(
      checkout.complete(
        cart: cartWithStingQty2(),
        payment: const PaymentSplit(cash: 15000),
      ),
      throwsA(isA<PaymentMismatchException>()),
    );
  });

  test('checkout rejects insufficient stock', () async {
    await seedProductStock(db, qty: '1');
    await seedSession(db);
    await openShift(shiftRepository);

    await expectLater(
      checkout.complete(
        cart: cartWithStingQty2(),
        payment: const PaymentSplit(cash: 20000),
      ),
      throwsA(isA<InsufficientStockException>()),
    );
  });

  test('checkout allows negative stock when meta enabled', () async {
    await seedProductStock(db, qty: '1');
    await seedSession(db);
    await db.setMetaValue('allowNegativeStock', 'true');
    await openShift(shiftRepository);

    await checkout.complete(
      cart: cartWithStingQty2(),
      payment: const PaymentSplit(cash: 20000),
    );

    final stock = await (db.select(db.productStocks)
          ..where(
            (row) =>
                row.productId.equals('p1') & row.storeId.equals('store-1'),
          ))
        .getSingle();
    expect(stock.qty, '-1');
  });

  test('checkout requires open shift', () async {
    await seedProductStock(db);
    await seedSession(db);

    await expectLater(
      checkout.complete(
        cart: cartWithStingQty2(),
        payment: const PaymentSplit(cash: 20000),
      ),
      throwsA(isA<NoOpenShiftException>()),
    );
  });
}
