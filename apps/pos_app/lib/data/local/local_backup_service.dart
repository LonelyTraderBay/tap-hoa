import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import 'database.dart';

const localBackupRetentionCount = 7;
const localBackupStaleAfter = Duration(hours: 24);
const localBackupCheckInterval = Duration(hours: 1);
const localBackupRootFolderName = 'tap_hoa_pos_backups';
const localBackupDatabaseFileName = 'tap_hoa_pos.sqlite';

typedef DirectoryProvider = Future<Directory> Function();

class LocalBackupService {
  LocalBackupService({
    required this.db,
    DirectoryProvider? documentsDirectoryProvider,
  }) : _documentsDirectoryProvider =
           documentsDirectoryProvider ?? getApplicationDocumentsDirectory;

  final AppDatabase db;
  final DirectoryProvider _documentsDirectoryProvider;

  Future<LocalBackupSnapshot> snapshot({DateTime? now}) async {
    final root = await backupRootDirectory();
    final lastBackupAt = await db.lastBackupAt();
    return LocalBackupSnapshot(
      lastBackupAt: lastBackupAt,
      backupRootPath: root.path,
      now: now ?? DateTime.now(),
    );
  }

  Future<bool> isBackupDue({DateTime? now}) async {
    final status = await snapshot(now: now);
    return status.isStale;
  }

  Future<LocalBackupResult?> backupIfDue({DateTime? now}) async {
    if (!await isBackupDue(now: now)) {
      return null;
    }
    return createBackup(now: now);
  }

  Future<LocalBackupResult> createBackup({DateTime? now}) async {
    final backupAt = now ?? DateTime.now();
    final root = await backupRootDirectory();
    await root.create(recursive: true);

    final backupDirectory = Directory(
      path.join(root.path, localBackupDirectoryName(backupAt)),
    );
    await backupDirectory.create(recursive: true);

    final target = File(
      path.join(backupDirectory.path, localBackupDatabaseFileName),
    );
    if (await target.exists()) {
      throw FileSystemException('Backup target already exists', target.path);
    }

    await _writeConsistentSqliteBackup(target);
    final deletedCount = await rotateLocalBackups(root);
    await db.setLastBackupAt(backupAt);

    return LocalBackupResult(
      backupAt: backupAt,
      backupDirectoryPath: backupDirectory.path,
      backupFilePath: target.path,
      deletedCount: deletedCount,
    );
  }

  Future<Directory> databaseDirectory() => _documentsDirectoryProvider();

  Future<File> databaseFile() async {
    final directory = await databaseDirectory();
    return File(path.join(directory.path, localBackupDatabaseFileName));
  }

  Future<Directory> backupRootDirectory() async {
    final directory = await databaseDirectory();
    return Directory(path.join(directory.path, localBackupRootFolderName));
  }

  Future<void> _writeConsistentSqliteBackup(File target) async {
    try {
      await db.customStatement('VACUUM INTO ?', [target.path]);
      return;
    } catch (_) {
      if (await target.exists()) {
        await target.delete();
      }
    }

    final source = await databaseFile();
    if (!await source.exists()) {
      throw FileSystemException('SQLite database file not found', source.path);
    }
    await db.customStatement('PRAGMA wal_checkpoint(TRUNCATE)');
    await source.copy(target.path);
  }
}

class LocalBackupSnapshot {
  const LocalBackupSnapshot({
    required this.lastBackupAt,
    required this.backupRootPath,
    required this.now,
  });

  final DateTime? lastBackupAt;
  final String backupRootPath;
  final DateTime now;

  bool get isStale {
    final last = lastBackupAt;
    if (last == null) {
      return true;
    }
    return now.toUtc().difference(last.toUtc()) >= localBackupStaleAfter;
  }
}

class LocalBackupResult {
  const LocalBackupResult({
    required this.backupAt,
    required this.backupDirectoryPath,
    required this.backupFilePath,
    required this.deletedCount,
  });

  final DateTime backupAt;
  final String backupDirectoryPath;
  final String backupFilePath;
  final int deletedCount;
}

String localBackupDirectoryName(DateTime at) {
  final local = at.toLocal();
  return 'backup_${_four(local.year)}${_two(local.month)}${_two(local.day)}_'
      '${_two(local.hour)}${_two(local.minute)}${_two(local.second)}';
}

bool isLocalBackupDirectoryName(String name) {
  return RegExp(r'^backup_\d{8}_\d{6}$').hasMatch(name);
}

List<String> localBackupNamesToDelete(
  Iterable<String> names, {
  int keepCount = localBackupRetentionCount,
}) {
  final backupNames = names.where(isLocalBackupDirectoryName).toList()
    ..sort((a, b) => b.compareTo(a));
  if (backupNames.length <= keepCount) {
    return const [];
  }
  return backupNames.skip(keepCount).toList();
}

Future<int> rotateLocalBackups(
  Directory root, {
  int keepCount = localBackupRetentionCount,
}) async {
  if (!await root.exists()) {
    return 0;
  }

  final directories = <String, Directory>{};
  await for (final entity in root.list(followLinks: false)) {
    if (entity is Directory) {
      directories[path.basename(entity.path)] = entity;
    }
  }

  var deletedCount = 0;
  for (final name in localBackupNamesToDelete(
    directories.keys,
    keepCount: keepCount,
  )) {
    final directory = directories[name];
    if (directory == null) {
      continue;
    }
    await directory.delete(recursive: true);
    deletedCount++;
  }
  return deletedCount;
}

String _two(int value) => value.toString().padLeft(2, '0');

String _four(int value) => value.toString().padLeft(4, '0');
