import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pos_app/data/local/database.dart';
import 'package:pos_app/features/customers/customer_repository.dart';
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
  late CustomerRepository customerRepository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    shiftRepository = ShiftRepository(dio: MockDio(), db: db);
    checkout = CheckoutService(db: db, shiftRepository: shiftRepository);
    customerRepository = CustomerRepository(db: db, dio: MockDio());
  });

  tearDown(() => db.close());

  test('debt checkout requires customer', () async {
    await seedProductStock(db);
    await seedSession(db);
    await openShift(shiftRepository);

    await expectLater(
      checkout.complete(
        cart: cartWithStingQty2(),
        payment: const PaymentSplit(debt: 20000),
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          'customer required for debt',
        ),
      ),
    );
  });

  test('debt checkout increases local customer balance', () async {
    await seedProductStock(db);
    await seedSession(db);
    await openShift(shiftRepository);

    final customer = await customerRepository.create(
      name: 'Anh Ba',
      phone: '0900111222',
    );

    await checkout.complete(
      cart: cartWithStingQty2(),
      payment: const PaymentSplit(debt: 20000),
      customerId: customer.id,
    );

    final row = await (db.select(db.customersLocal)
          ..where((customerRow) => customerRow.id.equals(customer.id)))
        .getSingle();
    expect(row.balanceVnd, 20000);

    final sale = await db.select(db.salesLocal).getSingle();
    expect(sale.debtAmount, 20000);
    expect(sale.customerId, customer.id);
  });

  test('customer repository lists only customers with debt', () async {
    await customerRepository.create(name: 'No debt');
    final debtor = await customerRepository.create(name: 'Debtor');
    await db.into(db.customersLocal).insertOnConflictUpdate(
      CustomersLocalCompanion(
        id: Value(debtor.id),
        name: Value(debtor.name),
        balanceVnd: const Value(15000),
        updatedAt: Value(DateTime(2026)),
      ),
    );

    final debtors = await customerRepository.watchWithDebt().first;
    expect(debtors, hasLength(1));
    expect(debtors.single.name, 'Debtor');
    expect(debtors.single.balanceVnd, 15000);
  });
}
