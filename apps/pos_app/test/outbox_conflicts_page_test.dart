import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pos_app/data/local/database.dart';
import 'package:pos_app/data/sync/outbox_worker.dart';
import 'package:pos_app/features/sync/outbox_conflict_service.dart';
import 'package:pos_app/features/sync/outbox_conflicts_page.dart';

class MockOutboxWorker extends Mock implements OutboxWorker {}

void main() {
  late AppDatabase database;
  late MockOutboxWorker outboxWorker;
  late OutboxConflictService service;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    outboxWorker = MockOutboxWorker();
    when(() => outboxWorker.tick()).thenAnswer((_) async {});
    service = OutboxConflictService(db: database, worker: outboxWorker);
  });

  tearDown(() => database.close());

  Future<void> seedEntry({
    required String id,
    required String status,
    String? lastError,
    int retryCount = 0,
    String entityType = 'sale',
    DateTime? createdAt,
  }) async {
    await database
        .into(database.outboxEntries)
        .insert(
          OutboxEntriesCompanion.insert(
            id: id,
            entityType: entityType,
            payloadJson: '{}',
            createdAt: createdAt ?? DateTime(2026, 1, 1),
            status: Value(status),
            lastError: Value(lastError),
            retryCount: Value(retryCount),
          ),
        );
  }

  Future<OutboxEntry> readEntry(String id) => (database.select(
    database.outboxEntries,
  )..where((row) => row.id.equals(id))).getSingle();

  Future<void> pumpPage(WidgetTester tester, {required String role}) async {
    await tester.pumpWidget(
      MaterialApp(
        home: OutboxConflictsPage(service: service, role: role, db: database),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('outboxDeadLetterActionsAllowedForRole', () {
    test('owner and store_manager allowed; cashier and others are not', () {
      expect(outboxDeadLetterActionsAllowedForRole('owner'), isTrue);
      expect(outboxDeadLetterActionsAllowedForRole('store_manager'), isTrue);
      expect(outboxDeadLetterActionsAllowedForRole('cashier'), isFalse);
      expect(outboxDeadLetterActionsAllowedForRole('unknown'), isFalse);
    });
  });

  group('OutboxConflictsPage — dead_letter role gate (G6, §6.3)', () {
    testWidgets(
      'cashier sees the "Cần chủ xử lý" badge but Sửa/Thử lại are locked '
      'on a dead_letter row',
      (tester) async {
        await seedEntry(
          id: 'dl-1',
          status: 'dead_letter',
          lastError: outboxSyncRetryExhaustedReason,
          retryCount: 5,
        );

        await pumpPage(tester, role: 'cashier');

        expect(find.text('Cần chủ xử lý'), findsOneWidget);

        final editButton = tester.widget<TextButton>(
          find.widgetWithText(TextButton, 'Sửa'),
        );
        final retryButton = tester.widget<TextButton>(
          find.widgetWithText(TextButton, 'Thử lại'),
        );
        expect(editButton.onPressed, isNull);
        expect(retryButton.onPressed, isNull);

        // Disabled buttons are a no-op when tapped: nothing changes, no
        // crash, no OutboxEditSheet opened.
        await tester.tap(find.widgetWithText(TextButton, 'Thử lại'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(TextButton, 'Sửa'));
        await tester.pumpAndSettle();

        final row = await readEntry('dl-1');
        expect(row.status, 'dead_letter');
        expect(find.text('Sửa JSON'), findsNothing);
        verifyNever(() => outboxWorker.tick());
      },
    );

    testWidgets('owner can retry a dead_letter row directly', (tester) async {
      await seedEntry(
        id: 'dl-2',
        status: 'dead_letter',
        lastError: outboxSyncRetryExhaustedReason,
      );

      await pumpPage(tester, role: 'owner');

      // Owner also sees the badge — it flags severity, not permission.
      expect(find.text('Cần chủ xử lý'), findsOneWidget);
      final retryButton = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Thử lại'),
      );
      expect(retryButton.onPressed, isNotNull);

      await tester.tap(find.widgetWithText(TextButton, 'Thử lại'));
      await tester.pumpAndSettle();

      final row = await readEntry('dl-2');
      expect(row.status, 'pending');
      expect(find.text('Đã thử đồng bộ lại'), findsOneWidget);
    });

    testWidgets('store_manager can open Sửa (edit) on a dead_letter row', (
      tester,
    ) async {
      await seedEntry(
        id: 'dl-3',
        status: 'dead_letter',
        lastError: outboxSyncRetryExhaustedReason,
      );

      await pumpPage(tester, role: 'store_manager');

      final editButton = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Sửa'),
      );
      expect(editButton.onPressed, isNotNull);

      await tester.tap(find.widgetWithText(TextButton, 'Sửa'));
      await tester.pumpAndSettle();

      expect(find.text('Sửa JSON'), findsOneWidget);
    });

    testWidgets(
      'error rows have no badge and keep old behavior for every role, '
      'including cashier',
      (tester) async {
        await seedEntry(
          id: 'err-1',
          status: 'error',
          lastError: 'insufficient_stock',
        );

        await pumpPage(tester, role: 'cashier');

        expect(find.text('Cần chủ xử lý'), findsNothing);
        final editButton = tester.widget<TextButton>(
          find.widgetWithText(TextButton, 'Sửa'),
        );
        final retryButton = tester.widget<TextButton>(
          find.widgetWithText(TextButton, 'Thử lại'),
        );
        expect(editButton.onPressed, isNotNull);
        expect(retryButton.onPressed, isNotNull);

        await tester.tap(find.widgetWithText(TextButton, 'Thử lại'));
        await tester.pumpAndSettle();

        final row = await readEntry('err-1');
        expect(row.status, 'pending');
        expect(find.text('Đã thử đồng bộ lại'), findsOneWidget);
      },
    );
  });

  group('OutboxConflictsPage — "Thử lại tất cả" bulk button (G6, §6.3)', () {
    testWidgets(
      'cashier bulk retry skips dead_letter rows but still retries error '
      'rows (bulk button must not bypass the per-row lock)',
      (tester) async {
        await seedEntry(
          id: 'err-2',
          status: 'error',
          lastError: 'insufficient_stock',
          createdAt: DateTime(2026, 1, 2),
        );
        await seedEntry(
          id: 'dl-4',
          status: 'dead_letter',
          lastError: outboxSyncRetryExhaustedReason,
          createdAt: DateTime(2026, 1, 1),
        );

        await pumpPage(tester, role: 'cashier');

        await tester.tap(find.widgetWithText(TextButton, 'Thử lại tất cả'));
        await tester.pumpAndSettle();

        final errRow = await readEntry('err-2');
        final dlRow = await readEntry('dl-4');
        expect(errRow.status, 'pending');
        expect(dlRow.status, 'dead_letter');
      },
    );

    testWidgets(
      'cashier bulk button is locked entirely when only dead_letter rows '
      'remain',
      (tester) async {
        await seedEntry(
          id: 'dl-5',
          status: 'dead_letter',
          lastError: outboxSyncRetryExhaustedReason,
        );

        await pumpPage(tester, role: 'cashier');

        final bulkButton = tester.widget<TextButton>(
          find.widgetWithText(TextButton, 'Thử lại tất cả'),
        );
        expect(bulkButton.onPressed, isNull);
      },
    );

    testWidgets('owner bulk retry still covers dead_letter rows (old behavior '
        'unchanged for allowed roles)', (tester) async {
      await seedEntry(
        id: 'dl-6',
        status: 'dead_letter',
        lastError: outboxSyncRetryExhaustedReason,
      );

      await pumpPage(tester, role: 'owner');

      final bulkButton = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Thử lại tất cả'),
      );
      expect(bulkButton.onPressed, isNotNull);

      await tester.tap(find.widgetWithText(TextButton, 'Thử lại tất cả'));
      await tester.pumpAndSettle();

      final row = await readEntry('dl-6');
      expect(row.status, 'pending');
    });
  });
}
