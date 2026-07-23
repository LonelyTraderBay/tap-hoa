import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/data/local/database.dart';
import 'package:pos_app/features/sync_status/sync_status_banner.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('shows pending outbox count', (tester) async {
    await db.into(db.outboxEntries).insert(
      OutboxEntriesCompanion.insert(
        id: 'outbox-1',
        entityType: 'sale',
        payloadJson: '{"id":"sale-1"}',
        createdAt: DateTime.now(),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: SyncStatusBanner(db: db))),
    );
    await tester.pump();

    expect(find.text('1 đang chờ đồng bộ'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('shows last sync error', (tester) async {
    await db.into(db.outboxEntries).insert(
      OutboxEntriesCompanion.insert(
        id: 'outbox-2',
        entityType: 'sale',
        payloadJson: '{"id":"sale-2"}',
        createdAt: DateTime.now(),
        status: const Value('error'),
        lastError: const Value('insufficient_stock'),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: SyncStatusBanner(db: db))),
    );
    await tester.pump();

    expect(find.textContaining('insufficient_stock'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('hides when outbox is clear', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: SyncStatusBanner(db: db))),
    );
    await tester.pump();

    expect(find.byType(SyncStatusBanner), findsOneWidget);
    expect(find.textContaining('đồng bộ'), findsNothing);
    expect(find.textContaining('Lỗi:'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
