import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pos_app/data/local/database.dart';
import 'package:pos_app/data/sync/outbox_worker.dart';
import 'package:pos_app/features/customers/debt_payment_service.dart';
import 'package:pos_app/features/shifts/shift_repository.dart';
import 'package:pos_app/features/sync/outbox_reason_labels.dart';

class MockDio extends Mock implements Dio {}

class MockResponse extends Mock implements Response<Map<String, dynamic>> {}

void main() {
  late AppDatabase db;
  late MockDio dio;
  late OutboxWorker worker;
  late DebtPaymentService service;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    dio = MockDio();
    worker = OutboxWorker(db: db, dio: dio);
    final shiftRepository = ShiftRepository(dio: MockDio(), db: db);
    service = DebtPaymentService(db: db, shiftRepository: shiftRepository);

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
    await db
        .into(db.customersLocal)
        .insert(
          CustomersLocalCompanion.insert(
            id: 'c1',
            name: 'Customer',
            balanceVnd: const Value(20000),
            updatedAt: DateTime(2026),
          ),
        );
    await shiftRepository.openShift(
      storeId: 'store-1',
      openingCash: 500000,
      userId: 'user-1',
    );
  });

  tearDown(() => db.close());

  Future<int> balance() async {
    final row = await (db.select(
      db.customersLocal,
    )..where((r) => r.id.equals('c1'))).getSingle();
    return row.balanceVnd;
  }

  Future<OutboxEntry> debtOutboxEntry() async {
    return (db.select(
      db.outboxEntries,
    )..where((row) => row.entityType.equals('debt_payment'))).getSingle();
  }

  void stubPushResponse(Map<String, dynamic> data) {
    final response = MockResponse();
    when(() => response.data).thenReturn(data);
    when(
      () =>
          dio.post<Map<String, dynamic>>('/sync/push', data: any(named: 'data')),
    ).thenAnswer((_) async => response);
  }

  test(
    'server rejects debt payment permanently -> local balance restored, ledger row removed, entry in error',
    () async {
      final paymentId = await service.recordPayment(
        customerId: 'c1',
        amountVnd: 5000,
        paymentMethod: 'cash',
      );
      expect(await balance(), 15000);

      stubPushResponse({
        'acceptedDebtPaymentIds': <String>[],
        'rejectedDebtPayments': [
          {'id': paymentId, 'reason': 'payment_exceeds_balance'},
        ],
      });

      await worker.tick();

      expect(await balance(), 20000);
      final ledger = await (db.select(
        db.debtLedgerLocal,
      )..where((row) => row.id.equals(paymentId))).getSingleOrNull();
      expect(ledger, isNull);

      final entry = await debtOutboxEntry();
      expect(entry.status, 'error');
      expect(entry.lastError, 'payment_exceeds_balance');
      expect(
        labelOutboxReason(entry.lastError),
        'Khách đã hết nợ (máy khác thu trước) — đã hoàn tác trên máy này',
      );
    },
  );

  test('customer_not_found rejection also reverts local debt payment', () async {
    final paymentId = await service.recordPayment(
      customerId: 'c1',
      amountVnd: 7000,
      paymentMethod: 'transfer',
    );
    expect(await balance(), 13000);

    stubPushResponse({
      'acceptedDebtPaymentIds': <String>[],
      'rejectedDebtPayments': [
        {'id': paymentId, 'reason': 'customer_not_found'},
      ],
    });

    await worker.tick();

    expect(await balance(), 20000);
    final entry = await debtOutboxEntry();
    expect(entry.status, 'error');
    expect(entry.lastError, 'customer_not_found');
  });

  test('DioException (offline) keeps entry pending and does not revert', () async {
    final paymentId = await service.recordPayment(
      customerId: 'c1',
      amountVnd: 5000,
      paymentMethod: 'cash',
    );
    expect(await balance(), 15000);

    when(
      () =>
          dio.post<Map<String, dynamic>>('/sync/push', data: any(named: 'data')),
    ).thenThrow(
      DioException(requestOptions: RequestOptions(path: '/sync/push')),
    );

    await worker.tick();

    expect(await balance(), 15000);
    final ledger = await (db.select(
      db.debtLedgerLocal,
    )..where((row) => row.id.equals(paymentId))).getSingleOrNull();
    expect(ledger, isNotNull);

    final entry = await debtOutboxEntry();
    expect(entry.status, 'pending');
    expect(entry.lastError, isNull);
  });

  test('accepted debt payment is not reverted', () async {
    final paymentId = await service.recordPayment(
      customerId: 'c1',
      amountVnd: 5000,
      paymentMethod: 'cash',
    );

    stubPushResponse({
      'acceptedDebtPaymentIds': [paymentId],
      'rejectedDebtPayments': <Map<String, dynamic>>[],
    });

    await worker.tick();

    expect(await balance(), 15000);
    final entry = await debtOutboxEntry();
    expect(entry.status, 'done');
  });

  test('revertLocalDebtPayment is idempotent (no double credit)', () async {
    final paymentId = await service.recordPayment(
      customerId: 'c1',
      amountVnd: 5000,
      paymentMethod: 'cash',
    );

    expect(await db.revertLocalDebtPayment(paymentId), isTrue);
    expect(await balance(), 20000);

    expect(await db.revertLocalDebtPayment(paymentId), isFalse);
    expect(await balance(), 20000);

    expect(await db.revertLocalDebtPayment('never-existed'), isFalse);
    expect(await balance(), 20000);
  });

  test('two worker ticks over the same rejection do not double-credit', () async {
    final paymentId = await service.recordPayment(
      customerId: 'c1',
      amountVnd: 5000,
      paymentMethod: 'cash',
    );

    stubPushResponse({
      'acceptedDebtPaymentIds': <String>[],
      'rejectedDebtPayments': [
        {'id': paymentId, 'reason': 'payment_exceeds_balance'},
      ],
    });

    await worker.tick();
    expect(await balance(), 20000);

    // Requeue like the conflicts page does, then let the server reject again.
    final entry = await debtOutboxEntry();
    await db.requeueOutbox(entry.id);
    await worker.tick();

    expect(await balance(), 20000);
    final after = await debtOutboxEntry();
    expect(after.status, 'error');
  });

  test('revert only touches the rejected payment, not other ledger rows', () async {
    final keptId = await service.recordPayment(
      customerId: 'c1',
      amountVnd: 4000,
      paymentMethod: 'cash',
    );
    final rejectedId = await service.recordPayment(
      customerId: 'c1',
      amountVnd: 6000,
      paymentMethod: 'cash',
    );
    expect(await balance(), 10000);

    stubPushResponse({
      'acceptedDebtPaymentIds': [keptId],
      'rejectedDebtPayments': [
        {'id': rejectedId, 'reason': 'payment_exceeds_balance'},
      ],
    });

    await worker.tick();

    expect(await balance(), 16000);
    final rows = await db.select(db.debtLedgerLocal).get();
    expect(rows.map((r) => r.id), [keptId]);
  });
}
