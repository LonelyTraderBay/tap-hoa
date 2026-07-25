import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/data/local/local_backup_service.dart';

void main() {
  test('formats dated backup directory names', () {
    final name = localBackupDirectoryName(DateTime(2026, 7, 25, 14, 23, 5));

    expect(name, 'backup_20260725_142305');
    expect(isLocalBackupDirectoryName(name), isTrue);
    expect(isLocalBackupDirectoryName('notes_20260725_142305'), isFalse);
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
}
