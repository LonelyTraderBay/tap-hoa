import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../data/local/database.dart';
import '../../data/local/local_backup_service.dart';

class SyncDiagnosticsPage extends StatefulWidget {
  const SyncDiagnosticsPage({super.key, required this.dio, required this.db});

  final Dio dio;
  final AppDatabase db;

  @override
  State<SyncDiagnosticsPage> createState() => _SyncDiagnosticsPageState();
}

class _SyncDiagnosticsPageState extends State<SyncDiagnosticsPage> {
  bool _loading = true;
  bool _backupLoading = true;
  bool _backupRunning = false;
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
            const SizedBox(height: 8),
            const Text(
              'Không tự khôi phục. Nếu cần restore: đóng ứng dụng, chọn một '
              'thư mục backup, rồi chép tap_hoa_pos.sqlite đè lên file dữ '
              'liệu hiện tại.',
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
            FilledButton.icon(
              onPressed: _backupRunning ? null : _createBackup,
              icon: _backupRunning
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_alt_outlined),
              label: const Text('Sao lưu ngay'),
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
