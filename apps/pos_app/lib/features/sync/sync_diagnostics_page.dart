import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../data/local/database.dart';
import '../../data/local/local_backup_service.dart';

/// Cụm từ người dùng phải gõ đúng (không chỉ bấm nút) trước khi khôi phục —
/// ma sát cố ý cho một hành động phá huỷ dữ liệu hiện tại (dù bước tự sao
/// lưu trước khi khôi phục cho một đường quay lại thật, người dùng lúc thao
/// tác vẫn phải coi đây là không thể hoàn tác).
const restoreBackupConfirmPhrase = 'KHÔI PHỤC';

class SyncDiagnosticsPage extends StatefulWidget {
  const SyncDiagnosticsPage({
    super.key,
    required this.dio,
    required this.db,
    required this.role,
  });

  final Dio dio;
  final AppDatabase db;

  /// Chỉ `owner` được thấy/khởi động luồng khôi phục — đây là hành động phá
  /// huỷ (ghi đè toàn bộ database sống), gate theo đúng house style các
  /// hành động owner-only khác (`allow_negative_stock_sheet.dart`,
  /// `showVatSettingsSheet`: kiểm role tại điểm vào, hiện snackbar giải
  /// thích thay vì ẩn hẳn nút khi role không đủ).
  final String role;

  @override
  State<SyncDiagnosticsPage> createState() => _SyncDiagnosticsPageState();
}

class _SyncDiagnosticsPageState extends State<SyncDiagnosticsPage> {
  bool _loading = true;
  bool _backupLoading = true;
  bool _backupRunning = false;
  bool _restoring = false;
  String? _error;
  String? _backupMessage;
  String? _backupError;
  String? _currentDeviceId;
  late final LocalBackupService _backupService;
  LocalBackupSnapshot? _backupSnapshot;
  List<Map<String, dynamic>> _devices = [];

  @override
  void initState() {
    super.initState();
    _backupService = LocalBackupService(db: widget.db);
    _refresh();
  }

  Future<void> _refresh() async {
    await Future.wait([_load(), _loadBackupStatus()]);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _currentDeviceId = await widget.db.metaValue('deviceId');
      final response = await widget.dio.get<Map<String, dynamic>>(
        '/sync/diagnostics',
      );
      final data = response.data;
      final list = (data?['devices'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      if (!mounted) return;
      setState(() {
        _devices = list;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Không tải được diagnostics (cần quyền quản lý/chủ)';
        _loading = false;
      });
    }
  }

  Future<void> _loadBackupStatus() async {
    setState(() {
      _backupLoading = true;
      _backupError = null;
    });
    try {
      final snapshot = await _backupService.snapshot();
      if (!mounted) return;
      setState(() {
        _backupSnapshot = snapshot;
        _backupLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _backupError = 'Không đọc được trạng thái sao lưu local';
        _backupLoading = false;
      });
    }
  }

  Future<void> _createBackup() async {
    setState(() {
      _backupRunning = true;
      _backupMessage = null;
      _backupError = null;
    });
    try {
      final result = await _backupService.createBackup();
      final snapshot = await _backupService.snapshot();
      if (!mounted) return;
      setState(() {
        _backupSnapshot = snapshot;
        _backupMessage =
            'Đã sao lưu: ${result.backupFilePath} '
            '(xóa ${result.deletedCount} bản cũ)';
        _backupRunning = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _backupError = 'Sao lưu thất bại; dữ liệu bán hàng vẫn giữ nguyên';
        _backupRunning = false;
      });
    }
  }

  /// Điểm vào luồng khôi phục — chỉ owner mới thấy nút gọi tới đây (xem
  /// `_buildBackupCard`), nhưng vẫn kiểm lại role tại đây theo đúng house
  /// style owner-only khác trong app (`allow_negative_stock_sheet.dart`,
  /// `showVatSettingsSheet`) thay vì tin tưởng tuyệt đối vào việc ẩn nút.
  Future<void> _openRestoreFlow() async {
    if (widget.role != 'owner') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chỉ chủ được khôi phục dữ liệu từ bản sao lưu'),
        ),
      );
      return;
    }
    final backups = await _backupService.listBackups();
    if (!mounted) return;
    if (backups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa có bản sao lưu nào để khôi phục')),
      );
      return;
    }
    final picked = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Chọn bản sao lưu để khôi phục',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            for (final name in backups)
              ListTile(
                leading: const Icon(Icons.restore_outlined),
                title: Text(_formatBackupLabel(name)),
                onTap: () => Navigator.of(ctx).pop(name),
              ),
          ],
        ),
      ),
    );
    if (picked == null || !mounted) return;
    await _confirmAndRestore(picked);
  }

  String _formatBackupLabel(String backupDirectoryName) {
    final parsed = parseLocalBackupDirectoryTimestamp(backupDirectoryName);
    if (parsed == null) return backupDirectoryName;
    return parsed.toString().split('.').first;
  }

  Future<void> _confirmAndRestore(String backupDirectoryName) async {
    final label = _formatBackupLabel(backupDirectoryName);
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final matches =
              controller.text.trim().toUpperCase() ==
              restoreBackupConfirmPhrase;
          return AlertDialog(
            title: const Text('Xác nhận khôi phục'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sẽ khôi phục dữ liệu về thời điểm: $label.'),
                const SizedBox(height: 8),
                const Text(
                  'Toàn bộ dữ liệu hiện tại trên máy này sẽ bị THAY THẾ. '
                  'Một bản sao lưu của trạng thái hiện tại sẽ được tạo tự '
                  'động ngay trước khi khôi phục, để còn đường quay lại nếu '
                  'chọn nhầm — nhưng hãy coi thao tác này là không thể '
                  'hoàn tác.',
                ),
                const SizedBox(height: 12),
                Text('Nhập "$restoreBackupConfirmPhrase" để xác nhận:'),
                const SizedBox(height: 8),
                TextField(
                  controller: controller,
                  autofocus: true,
                  textCapitalization: TextCapitalization.characters,
                  onChanged: (_) => setDialogState(() {}),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Hủy'),
              ),
              FilledButton(
                onPressed: matches ? () => Navigator.of(ctx).pop(true) : null,
                child: const Text('Khôi phục'),
              ),
            ],
          );
        },
      ),
    );
    controller.dispose();
    if (confirmed != true || !mounted) return;
    await _runRestore(backupDirectoryName);
  }

  Future<void> _runRestore(String backupDirectoryName) async {
    setState(() {
      _restoring = true;
      _backupError = null;
    });
    try {
      await _backupService.restoreBackup(backupDirectoryName);
      if (!mounted) return;
      await _showRestoreSuccessBlockingDialog();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _restoring = false;
        _backupError =
            'Khôi phục thất bại. Đóng và mở lại ứng dụng để kiểm tra dữ '
            'liệu hiện tại; nếu cần, khôi phục thủ công từ thư mục sao lưu.';
      });
    }
  }

  /// Màn hình chặn sau khi khôi phục thành công — không tự restart app
  /// (Flutter desktop không có API restart tiến trình sạch/đáng tin cậy),
  /// và không cho người dùng đóng dialog rồi tiếp tục thao tác trên kết nối
  /// `db` đã bị `restoreBackup` đóng (mọi thao tác đọc/ghi tiếp theo trên
  /// đó sẽ ném lỗi). `barrierDismissible: false` + `PopScope(canPop: false)`
  /// chặn cả tap-outside lẫn nút back — không có nút "Đóng" nào trong dialog
  /// này, cố ý.
  Future<void> _showRestoreSuccessBlockingDialog() {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: const Text('Đã khôi phục xong'),
          content: const Text(
            'Dữ liệu đã được khôi phục. Hãy ĐÓNG HẲN ứng dụng này (không '
            'chỉ quay lại màn hình trước) rồi MỞ LẠI để tiếp tục sử dụng. '
            'Không thao tác gì thêm trên màn hình này.',
          ),
        ),
      ),
    );
  }

  bool _isStale(String? lastPullAt) {
    if (lastPullAt == null) return true;
    final t = DateTime.tryParse(lastPullAt);
    if (t == null) return true;
    return DateTime.now().toUtc().difference(t.toUtc()).inHours >= 1;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnostics đồng bộ'),
        actions: [
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _buildBackupCard(context),
          const SizedBox(height: 12),
          Text(
            'Thiết bị đồng bộ',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text(_error!)),
            )
          else
            ..._devices.map(_buildDeviceTile),
        ],
      ),
    );
  }

  Widget _buildBackupCard(BuildContext context) {
    final snapshot = _backupSnapshot;
    final stale = snapshot?.isStale ?? false;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.backup_outlined),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Sao lưu SQLite local',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (stale)
                  const Chip(
                    label: Text('Cần sao lưu'),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            if (_backupLoading) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
            ],
            const SizedBox(height: 12),
            Text('Lần cuối: ${_formatBackupAt(snapshot?.lastBackupAt)}'),
            const SizedBox(height: 4),
            Text(
              'Thư mục giữ $localBackupRetentionCount bản: '
              '${snapshot?.backupRootPath ?? '—'}',
            ),
            if (_backupMessage != null) ...[
              const SizedBox(height: 8),
              Text(_backupMessage!),
            ],
            if (_backupError != null) ...[
              const SizedBox(height: 8),
              Text(
                _backupError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: (_backupRunning || _restoring)
                      ? null
                      : _createBackup,
                  icon: _backupRunning
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_alt_outlined),
                  label: const Text('Sao lưu ngay'),
                ),
                if (widget.role == 'owner')
                  OutlinedButton.icon(
                    onPressed: (_backupRunning || _restoring)
                        ? null
                        : _openRestoreFlow,
                    icon: _restoring
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.restore_outlined),
                    label: const Text('Khôi phục từ bản sao lưu'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceTile(Map<String, dynamic> d) {
    final deviceId = d['deviceId'] as String? ?? '';
    final isCurrent = deviceId == _currentDeviceId;
    final lastPull = d['lastPullAt'] as String?;
    final stale = _isStale(lastPull);
    return Column(
      children: [
        ListTile(
          selected: isCurrent,
          title: Text(d['userName'] as String? ?? deviceId),
          subtitle: Text(
            'device: $deviceId\n'
            'pull: ${lastPull ?? '—'}\n'
            'push: ${d['lastPushAt'] ?? '—'}',
          ),
          isThreeLine: true,
          trailing: stale
              ? const Chip(
                  label: Text('>1h'),
                  visualDensity: VisualDensity.compact,
                )
              : (isCurrent ? const Icon(Icons.phone_android) : null),
        ),
        const Divider(height: 1),
      ],
    );
  }

  String _formatBackupAt(DateTime? value) {
    if (value == null) {
      return 'Chưa có';
    }
    final local = value.toLocal();
    return local.toString().split('.').first;
  }
}
