import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pos_app/data/local/database.dart';
import 'package:pos_app/data/sync/outbox_worker.dart';

class MockDio extends Mock implements Dio {}

class MockResponse extends Mock implements Response<Map<String, dynamic>> {}

void main() {
  late AppDatabase db;
  late MockDio dio;
  late OutboxWorker worker;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dio = MockDio();
    worker = OutboxWorker(db: db, dio: dio);
  });

  tearDown(() => db.close());

  Future<void> seedSaleOutbox({
    required String saleId,
    String status = 'pending',
  }) async {
    await db
        .into(db.outboxEntries)
        .insert(
          OutboxEntriesCompanion.insert(
            id: 'outbox-$saleId',
            entityType: 'sale',
            payloadJson: jsonEncode({
              'id': saleId,
              'storeId': 'store-1',
              'shiftId': 'shift-1',
              'soldById': 'user-1',
              'paymentMethod': 'cash',
              'cashAmount': 20000,
              'transferAmount': 0,
              'debtAmount': 0,
              'discountVnd': 0,
              'totalVnd': 20000,
              'clientCreatedAt': DateTime.utc(2026).toIso8601String(),
              'lines': [
                {
                  'productId': 'p1',
                  'qty': '2',
                  'unitPrice': 10000,
                  'lineTotal': 20000,
                },
              ],
            }),
            createdAt: DateTime(2026),
            status: Value(status),
          ),
        );
  }

  test('tick pushes shift open before its pending sale', () async {
    await db
        .into(db.outboxEntries)
        .insert(
          OutboxEntriesCompanion.insert(
            id: 'outbox-shift-1',
            entityType: 'shift_open',
            payloadJson: jsonEncode({
              'id': 'shift-1',
              'storeId': 'store-1',
              'userId': 'user-1',
              'openingCash': 100000,
              'openedAt': DateTime.utc(2026).toIso8601String(),
            }),
            createdAt: DateTime(2026),
          ),
        );
    await seedSaleOutbox(saleId: 'sale-after-shift');
    final response = MockResponse();
    when(() => response.data).thenReturn({
      'acceptedShiftIds': ['shift-1'],
      'acceptedIds': ['sale-after-shift'],
      'rejected': [],
    });
    when(
      () => dio.post<Map<String, dynamic>>(
        '/sync/push',
        data: any(named: 'data'),
      ),
    ).thenAnswer((_) async => response);

    await worker.tick();

    verify(
      () => dio.post<Map<String, dynamic>>(
        '/sync/push',
        data: any(
          named: 'data',
          that: predicate<Map<String, dynamic>>(
            (body) =>
                (body['shiftOpens'] as List).single['id'] == 'shift-1' &&
                (body['sales'] as List).single['shiftId'] == 'shift-1',
          ),
        ),
      ),
    ).called(1);
    final entries = await db.select(db.outboxEntries).get();
    expect(entries.every((entry) => entry.status == 'done'), isTrue);
  });

  test('tick pushes pending sales and marks accepted outbox done', () async {
    const saleId = 'sale-1';
    await seedSaleOutbox(saleId: saleId);

    final response = MockResponse();
    when(() => response.data).thenReturn({
      'acceptedIds': [saleId],
      'rejected': [],
    });
    when(
      () => dio.post<Map<String, dynamic>>(
        '/sync/push',
        data: any(named: 'data'),
      ),
    ).thenAnswer((_) async => response);

    await worker.tick();

    final outbox = await (db.select(
      db.outboxEntries,
    )..where((entry) => entry.id.equals('outbox-$saleId'))).getSingle();
    expect(outbox.status, 'done');

    verify(
      () => dio.post<Map<String, dynamic>>(
        '/sync/push',
        data: any(
          named: 'data',
          that: predicate<Map<String, dynamic>>(
            (body) =>
                body['sales'] is List &&
                (body['sales'] as List).length == 1 &&
                (body['sales'] as List).first['id'] == saleId,
          ),
        ),
      ),
    ).called(1);
  });

  test('tick marks rejected sales as error', () async {
    const saleId = 'sale-reject';
    await seedSaleOutbox(saleId: saleId);

    final response = MockResponse();
    when(() => response.data).thenReturn({
      'acceptedIds': [],
      'rejected': [
        {'id': saleId, 'reason': 'insufficient_stock'},
      ],
    });
    when(
      () => dio.post<Map<String, dynamic>>(
        '/sync/push',
        data: any(named: 'data'),
      ),
    ).thenAnswer((_) async => response);

    await worker.tick();

    final outbox = await (db.select(
      db.outboxEntries,
    )..where((entry) => entry.id.equals('outbox-$saleId'))).getSingle();
    expect(outbox.status, 'error');
    expect(outbox.lastError, 'insufficient_stock');
  });

  test('tick applies closed shift snapshots from push response', () async {
    const shiftId = 'shift-close-1';
    await db
        .into(db.shiftsLocal)
        .insert(
          ShiftsLocalCompanion.insert(
            id: shiftId,
            storeId: 'store-1',
            userId: 'user-1',
            openedAt: DateTime(2026),
            openingCash: 100000,
          ),
        );
    await db
        .into(db.outboxEntries)
        .insert(
          OutboxEntriesCompanion.insert(
            id: 'outbox-shift-close-1',
            entityType: 'shift_close',
            payloadJson: jsonEncode({
              'id': shiftId,
              'closingCash': 120000,
              'closedAt': DateTime.utc(2026, 1, 2).toIso8601String(),
              'expectedCashVnd': 115000,
              'varianceVnd': 5000,
              'transferInShiftVnd': 0,
            }),
            createdAt: DateTime(2026),
          ),
        );

    final response = MockResponse();
    when(() => response.data).thenReturn({
      'acceptedShiftCloseIds': [shiftId],
      'closedShifts': [
        {
          'id': shiftId,
          'expectedCashVnd': 115000,
          'varianceVnd': 5000,
          'transferInShiftVnd': 0,
          'closingCash': 120000,
          'closedAt': DateTime.utc(2026, 1, 2).toIso8601String(),
          'note': 'server close',
        },
      ],
    });
    when(
      () => dio.post<Map<String, dynamic>>(
        '/sync/push',
        data: any(named: 'data'),
      ),
    ).thenAnswer((_) async => response);

    await worker.tick();

    final shift = await (db.select(db.shiftsLocal)
          ..where((s) => s.id.equals(shiftId)))
        .getSingle();
    expect(shift.expectedCashVnd, 115000);
    expect(shift.varianceVnd, 5000);
    expect(shift.closingCash, 120000);
    expect(shift.note, 'server close');
    expect(shift.closedAt?.toUtc(), DateTime.utc(2026, 1, 2));
  });

  test('tick leaves outbox pending on DioException', () async {
    const saleId = 'sale-offline';
    await seedSaleOutbox(saleId: saleId);

    when(
      () => dio.post<Map<String, dynamic>>(
        '/sync/push',
        data: any(named: 'data'),
      ),
    ).thenThrow(
      DioException(requestOptions: RequestOptions(path: '/sync/push')),
    );

    await worker.tick();

    final outbox = await (db.select(
      db.outboxEntries,
    )..where((entry) => entry.id.equals('outbox-$saleId'))).getSingle();
    expect(outbox.status, 'pending');
  });
}
