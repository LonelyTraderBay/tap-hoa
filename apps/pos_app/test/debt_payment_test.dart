import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pos_app/data/local/database.dart';
import 'package:pos_app/features/customers/debt_payment_service.dart';
import 'package:pos_app/features/shifts/shift_repository.dart';
import 'package:dio/dio.dart';

class MockDio extends Mock implements Dio {}

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

Future<void> seedCustomer(
  AppDatabase db, {
  String id = 'c1',
  int balanceVnd = 20000,
}) async {
  await db.into(db.customersLocal).insert(
    CustomersLocalCompanion.insert(
      id: id,
      name: 'Customer',
      balanceVnd: Value(balanceVnd),
      updatedAt: DateTime(2026),
    ),
  );
}

Future<void> openShift(ShiftRepository repository) {
  return repository.openShift(
    storeId: 'store-1',
    openingCash: 500000,
    userId: 'user-1',
  );
}

void main() {
  late AppDatabase db;
  late ShiftRepository shiftRepository;
  late DebtPaymentService service;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    shiftRepository = ShiftRepository(dio: MockDio(), db: db);
    service = DebtPaymentService(db: db, shiftRepository: shiftRepository);
  });

  tearDown(() => db.close());

  test('recordPayment decreases balance and enqueues debt_payment outbox', () async {
    await seedSession(db);
    await seedCustomer(db);
    await openShift(shiftRepository);

    final id = await service.recordPayment(
      customerId: 'c1',
      amountVnd: 5000,
      paymentMethod: 'cash',
      note: 'tra',
    );

    final customer = await (db.select(db.customersLocal)
          ..where((t) => t.id.equals('c1')))
        .getSingle();
    expect(customer.balanceVnd, 15000);

    final ledger = await (db.select(db.debtLedgerLocal)
          ..where((t) => t.id.equals(id)))
        .getSingle();
    expect(ledger.type, 'payment');
    expect(ledger.amountVnd, 5000);

    final outbox = await db.pendingOutbox();
    expect(outbox.any((e) => e.entityType == 'debt_payment'), isTrue);
  });

  test('recordPayment rejects amount over balance', () async {
    await seedSession(db);
    await seedCustomer(db);
    await openShift(shiftRepository);

    expect(
      () => service.recordPayment(
        customerId: 'c1',
        amountVnd: 999999,
        paymentMethod: 'cash',
      ),
      throwsA(isA<StateError>()),
    );
  });

  // §4.8 G3 "Xem nhanh, không mở ca": owner/store_manager thu nợ tại chỗ mà
  // không mở ca bán hàng tại quầy — recordPayment không còn được phép ném
  // NoOpenShiftException (hành vi cũ của requireOpenShift) vì kiến trúc đã
  // hỗ trợ shiftId rỗng ở cả local schema (DebtLedgerLocal.shiftId nullable)
  // lẫn server (DebtLedgerEntry.shiftId nullable, sync.service.ts đã dùng
  // `payment.shiftId ?? null` từ trước).
  test(
    'recordPayment succeeds without an open shift and stores a null shiftId',
    () async {
      await seedSession(db);
      await seedCustomer(db);
      // Cố ý KHÔNG gọi openShift(...) — mô phỏng "Xem nhanh".

      final id = await service.recordPayment(
        customerId: 'c1',
        amountVnd: 5000,
        paymentMethod: 'cash',
      );

      final customer = await (db.select(
        db.customersLocal,
      )..where((t) => t.id.equals('c1'))).getSingle();
      expect(customer.balanceVnd, 15000);

      final ledger = await (db.select(
        db.debtLedgerLocal,
      )..where((t) => t.id.equals(id))).getSingle();
      expect(ledger.type, 'payment');
      // Not `isNull` — that matcher name collides with drift's query-builder
      // `isNull` (both libraries are imported in this file), so use plain
      // equality instead.
      expect(ledger.shiftId, null);

      final outbox = await db.pendingOutbox();
      final entry = outbox.firstWhere((e) => e.entityType == 'debt_payment');
      expect(entry.payloadJson, contains('"shiftId":null'));
    },
  );
}
