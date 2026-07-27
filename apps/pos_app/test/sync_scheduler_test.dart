import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pos_app/data/local/local_backup_service.dart';
import 'package:pos_app/data/sync/outbox_worker.dart';
import 'package:pos_app/data/sync/pull_catalog.dart';
import 'package:pos_app/data/sync/sync_scheduler.dart';

class MockOutboxWorker extends Mock implements OutboxWorker {}

class MockLocalBackupService extends Mock implements LocalBackupService {}

class MockPullCatalog extends Mock implements PullCatalog {}

void main() {
  late MockOutboxWorker outboxWorker;
  late MockLocalBackupService backupService;
  late MockPullCatalog pullCatalog;
  // Records storeId for every PullCatalog.pullCatalog() call in order —
  // simpler and less ambiguous than chained mocktail verify() counts when
  // asserting how many times a periodic Timer has fired.
  late List<String> pullCalls;

  setUp(() {
    outboxWorker = MockOutboxWorker();
    backupService = MockLocalBackupService();
    pullCatalog = MockPullCatalog();
    pullCalls = [];
    when(() => outboxWorker.tick()).thenAnswer((_) async {});
    when(() => backupService.backupIfDue()).thenAnswer((_) async => null);
    when(() => pullCatalog.pullCatalog(any())).thenAnswer((invocation) async {
      pullCalls.add(invocation.positionalArguments.first as String);
    });
  });

  Future<GlobalKey<SyncSchedulerState>> pumpScheduler(
    WidgetTester tester,
  ) async {
    final key = GlobalKey<SyncSchedulerState>();
    await tester.pumpWidget(
      SyncScheduler(
        key: key,
        outboxWorker: outboxWorker,
        backupService: backupService,
        pullCatalog: pullCatalog,
        child: const SizedBox.shrink(),
      ),
    );
    // Flush the unawaited initial push/backup ticks fired from initState.
    await tester.pump();
    return key;
  }

  // Disposing cancels the 15s push timer, hourly backup timer and the pull
  // timer — without this, flutter_test fails the test for leaving pending
  // Timers behind when it tears down the fake async zone.
  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  }

  testWidgets(
    'setActiveStore pulls immediately, then again every catalogPullInterval',
    (tester) async {
      final key = await pumpScheduler(tester);

      key.currentState!.setActiveStore('store-1');
      await tester.pump();
      expect(pullCalls, ['store-1']);

      await tester.pump(catalogPullInterval);
      expect(pullCalls, ['store-1', 'store-1']);

      await tester.pump(catalogPullInterval);
      expect(pullCalls, ['store-1', 'store-1', 'store-1']);

      // Well under a full interval since the last tick: no extra pull yet.
      await tester.pump(const Duration(seconds: 5));
      expect(pullCalls, ['store-1', 'store-1', 'store-1']);

      await unmount(tester);
    },
  );

  testWidgets('no background pull happens before a store is registered', (
    tester,
  ) async {
    await pumpScheduler(tester);

    await tester.pump(catalogPullInterval * 3);
    expect(pullCalls, isEmpty);

    await unmount(tester);
  });

  testWidgets(
    'app resume triggers an extra pull only once a store is active',
    (tester) async {
      final key = await pumpScheduler(tester);

      key.currentState!.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await tester.pump();
      expect(pullCalls, isEmpty);

      key.currentState!.setActiveStore('store-1');
      await tester.pump();
      expect(pullCalls, ['store-1']);

      key.currentState!.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await tester.pump();
      expect(pullCalls, ['store-1', 'store-1']);

      await unmount(tester);
    },
  );

  testWidgets(
    'setActiveStore with a new store re-targets background pull to it',
    (tester) async {
      final key = await pumpScheduler(tester);

      key.currentState!.setActiveStore('store-1');
      await tester.pump();
      expect(pullCalls, ['store-1']);

      key.currentState!.setActiveStore('store-2');
      await tester.pump();
      expect(pullCalls, ['store-1', 'store-2']);

      // Only the new store's periodic pull should keep firing.
      await tester.pump(catalogPullInterval);
      expect(pullCalls, ['store-1', 'store-2', 'store-2']);

      await unmount(tester);
    },
  );

  testWidgets(
    'a failed pull is swallowed (no crash) and the next periodic tick still fires',
    (tester) async {
      var attempts = 0;
      when(() => pullCatalog.pullCatalog(any())).thenAnswer((
        invocation,
      ) async {
        attempts++;
        pullCalls.add(invocation.positionalArguments.first as String);
        throw Exception('network down');
      });

      final key = await pumpScheduler(tester);
      key.currentState!.setActiveStore('store-1');

      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(attempts, 1);

      await tester.pump(catalogPullInterval);
      expect(tester.takeException(), isNull);
      expect(attempts, 2);

      await unmount(tester);
    },
  );
}
