import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:pos_app/data/local/database.dart';
import 'package:pos_app/data/local/local_backup_service.dart';

void main() {
  test('formats dated backup directory names', () {
    final name = localBackupDirectoryName(DateTime(2026, 7, 25, 14, 23, 5));

    expect(name, 'backup_20260725_142305');
    expect(isLocalBackupDirectoryName(name), isTrue);
    expect(isLocalBackupDirectoryName('notes_20260725_142305'), isFalse);
  });

  test('parses timestamps back out of backup directory names', () {
    final name = localBackupDirectoryName(DateTime(2026, 7, 25, 14, 23, 5));
    final parsed = parseLocalBackupDirectoryTimestamp(name);

    expect(parsed, isNotNull);
    expect(parsed!.year, 2026);
    expect(parsed.month, 7);
    expect(parsed.day, 25);
    expect(parsed.hour, 14);
    expect(parsed.minute, 23);
    expect(parsed.second, 5);
    expect(parseLocalBackupDirectoryTimestamp('not-a-backup'), isNull);
  });

  test('selects oldest backup directories for rotation', () {
    final deletions = localBackupNamesToDelete([
      'backup_20260725_010000',
      'backup_20260725_020000',
      'backup_20260725_030000',
      'backup_20260725_040000',
      'backup_20260725_050000',
      'backup_20260725_060000',
      'backup_20260725_070000',
      'backup_20260725_080000',
      'README.txt',
    ]);

    expect(deletions, ['backup_20260725_010000']);
  });

  test('marks snapshots stale after 24 hours', () {
    final now = DateTime.utc(2026, 7, 25, 14);

    expect(
      LocalBackupSnapshot(
        lastBackupAt: DateTime.utc(2026, 7, 24, 13, 59),
        backupRootPath: 'backups',
        now: now,
      ).isStale,
      isTrue,
    );
    expect(
      LocalBackupSnapshot(
        lastBackupAt: DateTime.utc(2026, 7, 24, 14, 1),
        backupRootPath: 'backups',
        now: now,
      ).isStale,
      isFalse,
    );
  });

  // Real file-backed, real WAL-mode round-trip (not a mocked file-copy
  // assertion) — restoreBackup's whole point is safely swapping SQLite
  // files while WAL sidecars are involved, so an in-memory database
  // (NativeDatabase.memory(), used by the rest of this test suite) can't
  // exercise it: in-memory databases never produce -wal/-shm files.
  group('restoreBackup (real WAL round-trip)', () {
    late Directory tempDir;
    late File dbFile;
    late AppDatabase db;
    late LocalBackupService service;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('tap_hoa_backup_test_');
      dbFile = File(p.join(tempDir.path, localBackupDatabaseFileName));
      db = AppDatabase(NativeDatabase(dbFile));
      // Force WAL mode so writes actually land in -wal/-shm sidecar files —
      // mirrors what a real desktop install would do, and is required to
      // meaningfully exercise the checkpoint+delete-sidecars logic below.
      await db.customStatement('PRAGMA journal_mode=WAL');
      service = LocalBackupService(
        db: db,
        documentsDirectoryProvider: () async => tempDir,
      );
    });

    tearDown(() async {
      try {
        await db.close();
      } catch (_) {
        // restoreBackup() closes `db` itself on the success path — closing
        // an already-closed connection is a no-op we don't care about here.
      }
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test(
      'restores pre-mutation state and removes stale WAL sidecars',
      () async {
        await db.setMetaValue('probe', 'before-backup');
        // Use a timestamp far enough in the past that it can never collide
        // (same-second directory name) with the auto pre-restore backup
        // restoreBackup() below takes with a real DateTime.now().
        final backup = await service.createBackup(
          now: DateTime.now().subtract(const Duration(days: 1)),
        );
        final backupDirName = p.basename(backup.backupDirectoryPath);

        await db.setMetaValue('probe', 'after-backup-mutated');
        final walFile = File('${dbFile.path}-wal');
        expect(
          await walFile.exists(),
          isTrue,
          reason:
              'sanity check: the mutation above must actually land in the '
              'WAL sidecar (uncheckpointed) for this to be a real WAL '
              'round-trip test',
        );

        final result = await service.restoreBackup(backupDirName);

        expect(result.restoredFromDirectoryName, backupDirName);
        expect(await File('${dbFile.path}-wal').exists(), isFalse);
        expect(await File('${dbFile.path}-shm').exists(), isFalse);

        // `db` (and therefore `service`) is closed by restoreBackup() per
        // its no-self-restart contract — verify the restored file with a
        // fresh connection, the way the app would after being reopened.
        final reopened = AppDatabase(NativeDatabase(dbFile));
        addTearDown(() => reopened.close());
        expect(await reopened.metaValue('probe'), 'before-backup');
      },
    );

    test('auto-backs-up current (about-to-be-overwritten) state before '
        'restoring', () async {
      await db.setMetaValue('probe', 'v1');
      final firstBackup = await service.createBackup(
        now: DateTime.now().subtract(const Duration(days: 1)),
      );
      final firstBackupDirName = p.basename(firstBackup.backupDirectoryPath);

      await db.setMetaValue('probe', 'v2');
      final backupsBefore = (await service.listBackups()).toSet();

      final result = await service.restoreBackup(firstBackupDirName);

      final backupsAfter = await service.listBackups();
      expect(backupsAfter.length, backupsBefore.length + 1);
      final newBackups = backupsAfter.toSet().difference(backupsBefore);
      expect(newBackups, {result.preRestoreBackupDirectoryName});

      // The auto pre-restore backup must have captured the MUTATED
      // ('v2') state — it has to run while `db` still holds the
      // about-to-be-discarded data, before the live file gets
      // overwritten with the restore target's ('v1') content. Open it
      // directly as a plain SQLite file (not via another restoreBackup
      // call — chaining two restores back-to-back could collide on
      // createBackup()'s 1-second-resolution directory names) to prove
      // it's real, readable, uncorrupted data and not just bookkeeping.
      final preRestoreFile = File(
        p.join(
          tempDir.path,
          localBackupRootFolderName,
          result.preRestoreBackupDirectoryName,
          localBackupDatabaseFileName,
        ),
      );
      final preRestoreDb = AppDatabase(NativeDatabase(preRestoreFile));
      addTearDown(() => preRestoreDb.close());
      expect(await preRestoreDb.metaValue('probe'), 'v2');

      // And the live file itself now holds the restored ('v1') state.
      final restoredDb = AppDatabase(NativeDatabase(dbFile));
      addTearDown(() => restoredDb.close());
      expect(await restoredDb.metaValue('probe'), 'v1');
    });

    test('throws clearly for a missing or invalid backup name without side '
        'effects', () async {
      await db.setMetaValue('probe', 'untouched');

      await expectLater(
        () => service.restoreBackup('not-a-backup-directory-name'),
        throwsA(isA<ArgumentError>()),
      );
      await expectLater(
        () => service.restoreBackup('backup_20200101_000000'),
        throwsA(isA<FileSystemException>()),
      );

      // Neither failed attempt should have closed the connection or
      // touched the live database file.
      expect(await db.metaValue('probe'), 'untouched');
    });
  });
}
