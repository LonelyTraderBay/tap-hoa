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

  /// Danh sách thư mục backup hợp lệ (đúng định dạng
  /// `backup_YYYYMMDD_HHMMSS`), mới nhất trước — dùng cho UI chọn bản để
  /// khôi phục. Không phân biệt bản đã hết hạn rotation hay chưa (thư mục
  /// nào còn tồn tại trên đĩa đều liệt kê).
  Future<List<String>> listBackups() async {
    final root = await backupRootDirectory();
    if (!await root.exists()) {
      return const [];
    }
    final names = <String>[];
    await for (final entity in root.list(followLinks: false)) {
      if (entity is Directory &&
          isLocalBackupDirectoryName(path.basename(entity.path))) {
        names.add(path.basename(entity.path));
      }
    }
    names.sort((a, b) => b.compareTo(a));
    return names;
  }

  /// Khôi phục database sống từ một thư mục backup đã có (xem [listBackups]).
  ///
  /// Thứ tự các bước (đọc kỹ trước khi sửa — thứ tự sai sẽ mất dữ liệu hoặc
  /// làm hỏng file SQLite khi mở lại):
  ///
  /// 1. Validate tên thư mục + file backup thực sự tồn tại, ném lỗi rõ ràng
  ///    nếu không (KHÔNG âm thầm bỏ qua) — để UI hiện lỗi thật thay vì im
  ///    lặng không làm gì.
  /// 2. **Tự sao lưu trạng thái hiện tại TRƯỚC khi ghi đè** (đường quay lại
  ///    nếu người dùng chọn nhầm bản backup) — gọi [createBackup] trong khi
  ///    kết nối `db` còn mở (bắt buộc, vì `VACUUM INTO`/`wal_checkpoint` cần
  ///    kết nối sống). Cố tình dùng CHUNG rotation 7-bản với backup thường
  ///    (không đặt tên riêng để "miễn nhiễm" xoay vòng) — bản mới nhất luôn
  ///    được giữ lại đầu tiên trong `localBackupNamesToDelete`, nên bản vừa
  ///    tạo ở đây chỉ bị xoá sau khi có thêm 7 lượt backup kế tiếp (lịch tự
  ///    động mỗi 24h hoặc bấm tay) — đủ nhiều ngày để người dùng phát hiện
  ///    lỡ khôi phục nhầm. Đổi lại là đơn giản hơn hẳn so với thêm một sơ đồ
  ///    đặt tên/loại trừ riêng cho một tình huống hiếm gặp.
  /// 3. Checkpoint WAL vào file chính rồi ĐÓNG kết nối `db` — bắt buộc trước
  ///    khi đụng vào file trên đĩa: Windows khoá file đang mở (không cho ghi
  ///    đè/xoá), và nếu không đóng, kết nối cũ có thể ghi tiếp vào
  ///    `-wal`/`-shm` sau khi bước 4 đã xoá chúng.
  /// 4. Xoá `-wal`/`-shm` còn sót lại cạnh file database sống — nếu không
  ///    xoá, lần mở database tiếp theo (sau khi app khởi động lại) sẽ thấy
  ///    một file `-wal` ứng với dữ liệu CŨ (trước khi ghi đè) nhưng file
  ///    chính đã là dữ liệu MỚI (từ backup) → SQLite cố "replay" WAL không
  ///    khớp lên file mới, có thể làm hỏng database vừa khôi phục. File
  ///    backup nguồn LUÔN sạch (không có sidecar) vì
  ///    [_writeConsistentSqliteBackup] đã đảm bảo điều đó lúc tạo backup.
  /// 5. Ghi đè file database sống bằng file backup.
  ///
  /// KHÔNG mở lại `db` sau bước 5 — app Flutter desktop không có API restart
  /// tiến trình sạch/đáng tin cậy; UI gọi hàm này phải hiện màn hình chặn
  /// yêu cầu người dùng tự đóng hẳn và mở lại ứng dụng (xem
  /// `sync_diagnostics_page.dart`), không được để người dùng tiếp tục thao
  /// tác trên kết nối `db` đã đóng.
  Future<LocalRestoreResult> restoreBackup(String backupDirectoryName) async {
    if (!isLocalBackupDirectoryName(backupDirectoryName)) {
      throw ArgumentError.value(
        backupDirectoryName,
        'backupDirectoryName',
        'Không phải tên thư mục backup hợp lệ',
      );
    }
    final root = await backupRootDirectory();
    final sourceDirectory = Directory(
      path.join(root.path, backupDirectoryName),
    );
    final source = File(
      path.join(sourceDirectory.path, localBackupDatabaseFileName),
    );
    if (!await source.exists()) {
      throw FileSystemException(
        'Không tìm thấy file database trong thư mục backup',
        source.path,
      );
    }

    final preRestoreBackup = await createBackup();

    try {
      await db.customStatement('PRAGMA wal_checkpoint(TRUNCATE)');
    } catch (_) {
      // Best-effort: một số driver/trạng thái có thể từ chối pragma này
      // (vd. không ở chế độ WAL) — không phải lý do để dừng khôi phục, vẫn
      // tiếp tục đóng kết nối + dọn sidecar bên dưới.
    }
    await db.close();

    final target = await databaseFile();
    for (final suffix in const ['-wal', '-shm']) {
      final sidecar = File('${target.path}$suffix');
      if (await sidecar.exists()) {
        await sidecar.delete();
      }
    }

    await source.copy(target.path);

    return LocalRestoreResult(
      restoredAt: DateTime.now(),
      restoredFromDirectoryName: backupDirectoryName,
      preRestoreBackupDirectoryName: path.basename(
        preRestoreBackup.backupDirectoryPath,
      ),
    );
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

class LocalRestoreResult {
  const LocalRestoreResult({
    required this.restoredAt,
    required this.restoredFromDirectoryName,
    required this.preRestoreBackupDirectoryName,
  });

  /// Thời điểm thao tác khôi phục hoàn tất (không phải thời điểm dữ liệu
  /// trong backup được tạo ra).
  final DateTime restoredAt;

  /// Tên thư mục backup đã dùng làm nguồn khôi phục.
  final String restoredFromDirectoryName;

  /// Tên thư mục backup TỰ ĐỘNG tạo ra ngay trước khi ghi đè (snapshot của
  /// trạng thái ngay trước lúc khôi phục) — đường quay lại nếu người dùng
  /// phát hiện chọn nhầm bản.
  final String preRestoreBackupDirectoryName;
}

String localBackupDirectoryName(DateTime at) {
  final local = at.toLocal();
  return 'backup_${_four(local.year)}${_two(local.month)}${_two(local.day)}_'
      '${_two(local.hour)}${_two(local.minute)}${_two(local.second)}';
}

bool isLocalBackupDirectoryName(String name) {
  return RegExp(r'^backup_\d{8}_\d{6}$').hasMatch(name);
}

/// Đảo ngược [localBackupDirectoryName] — đọc lại mốc thời gian (giờ local,
/// không phải UTC) từ tên thư mục để hiển thị trong danh sách chọn khôi
/// phục. Trả `null` nếu [name] không đúng định dạng.
DateTime? parseLocalBackupDirectoryTimestamp(String name) {
  if (!isLocalBackupDirectoryName(name)) {
    return null;
  }
  final digits = name.substring('backup_'.length);
  final year = int.parse(digits.substring(0, 4));
  final month = int.parse(digits.substring(4, 6));
  final day = int.parse(digits.substring(6, 8));
  final hour = int.parse(digits.substring(9, 11));
  final minute = int.parse(digits.substring(11, 13));
  final second = int.parse(digits.substring(13, 15));
  return DateTime(year, month, day, hour, minute, second);
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
