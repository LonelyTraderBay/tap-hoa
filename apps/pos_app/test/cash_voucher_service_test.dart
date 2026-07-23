import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pos_app/data/local/database.dart';
import 'package:pos_app/features/cash/cash_voucher_service.dart';
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

Future<void> seedCategory(AppDatabase db, {String id = 'cat-1'}) async {
  await db.into(db.cashCategoriesLocal).insert(
    CashCategoriesLocalCompanion.insert(
      id: id,
      code: 'misc-in',
      name: 'Misc in',
      direction: 'in',
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
  late CashVoucherService service;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    shiftRepository = ShiftRepository(dio: MockDio(), db: db);
    service = CashVoucherService(db: db, shiftRepository: shiftRepository);
  });

  tearDown(() => db.close());

  test('recordVoucher inserts voucher and enqueues cash_voucher outbox', () async {
    await seedSession(db);
    await seedCategory(db);
    await openShift(shiftRepository);

    final id = await service.recordVoucher(
      direction: 'in',
      categoryId: 'cat-1',
      channel: 'cash',
      amountVnd: 50000,
      note: 'tip',
    );

    final voucher = await (db.select(db.cashVouchersLocal)
          ..where((t) => t.id.equals(id)))
        .getSingle();
    expect(voucher.direction, 'in');
    expect(voucher.channel, 'cash');
    expect(voucher.amountVnd, 50000);

    final outbox = await db.pendingOutbox();
    expect(outbox.any((e) => e.entityType == 'cash_voucher'), isTrue);
  });

  test('recordVoucher fails with no open shift', () async {
    await seedSession(db);
    await seedCategory(db);

    expect(
      () => service.recordVoucher(
        direction: 'in',
        categoryId: 'cat-1',
        channel: 'cash',
        amountVnd: 1000,
      ),
      throwsA(isA<NoOpenShiftException>()),
    );
  });

  test('recordVoucher fails when amountVnd <= 0', () async {
    await seedSession(db);
    await seedCategory(db);
    await openShift(shiftRepository);

    expect(
      () => service.recordVoucher(
        direction: 'in',
        categoryId: 'cat-1',
        channel: 'cash',
        amountVnd: 0,
      ),
      throwsA(isA<StateError>()),
    );
  });
}
