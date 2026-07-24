import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../data/local/database.dart';

class SyncDiagnosticsPage extends StatefulWidget {
  const SyncDiagnosticsPage({
    super.key,
    required this.dio,
    required this.db,
  });

  final Dio dio;
  final AppDatabase db;

  @override
  State<SyncDiagnosticsPage> createState() => _SyncDiagnosticsPageState();
}

class _SyncDiagnosticsPageState extends State<SyncDiagnosticsPage> {
  bool _loading = true;
  String? _error;
  String? _currentDeviceId;
  List<Map<String, dynamic>> _devices = [];

  @override
  void initState() {
    super.initState();
    _load();
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
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : ListView.separated(
                  itemCount: _devices.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final d = _devices[index];
                    final deviceId = d['deviceId'] as String? ?? '';
                    final isCurrent = deviceId == _currentDeviceId;
                    final lastPull = d['lastPullAt'] as String?;
                    final stale = _isStale(lastPull);
                    return ListTile(
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
                          : (isCurrent
                              ? const Icon(Icons.phone_android)
                              : null),
                    );
                  },
                ),
    );
  }
}
