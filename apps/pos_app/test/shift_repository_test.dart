import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pos_app/data/local/database.dart';
import 'package:pos_app/features/shifts/shift_repository.dart';
import 'package:dio/dio.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late AppDatabase db;
  late ShiftRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = ShiftRepository(dio: MockDio(), db: db);
  });

  tearDown(() => db.close());

  test('openShift persists shift and enqueues outbox', () async {
    final shiftId = await repository.openShift(
      storeId: 'store-1',
      openingCash: 500000,
      userId: 'user-1',
    );

    final shifts = await db.select(db.shiftsLocal).get();
    expect(shifts, hasLength(1));
    expect(shifts.single.id, shiftId);
    expect(shifts.single.openingCash, 500000);
    expect(shifts.single.closedAt, isNull);

    final outbox = await (db.select(
      db.outboxEntries,
    )..where((entry) => entry.status.equals('pending'))).get();
    expect(outbox.single.entityType, 'shift_open');
    expect(outbox.single.payloadJson, contains(shiftId));
    expect(await db.metaValue('currentStoreId'), 'store-1');
  });

  test('openShift rejects second open shift for same store and user', () async {
    await repository.openShift(
      storeId: 'store-1',
      openingCash: 100000,
      userId: 'user-1',
    );

    expect(
      () => repository.openShift(
        storeId: 'store-1',
        openingCash: 200000,
        userId: 'user-1',
      ),
      throwsA(isA<ShiftAlreadyOpenException>()),
    );
  });

  test('requireOpenShift throws when no shift is open', () async {
    await expectLater(
      repository.requireOpenShift(storeId: 'store-1', userId: 'user-1'),
      throwsA(isA<NoOpenShiftException>()),
    );
  });

  test('requireOpenShift returns open shift', () async {
    final shiftId = await repository.openShift(
      storeId: 'store-1',
      openingCash: 300000,
      userId: 'user-1',
    );

    final shift = await repository.requireOpenShift(
      storeId: 'store-1',
      userId: 'user-1',
    );
    expect(shift.id, shiftId);
  });
}
