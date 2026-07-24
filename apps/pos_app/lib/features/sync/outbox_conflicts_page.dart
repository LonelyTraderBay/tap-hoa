import 'package:flutter/material.dart';

import '../../data/local/database.dart';
import 'outbox_conflict_service.dart';
import 'outbox_edit_sheet.dart';
import 'outbox_reason_labels.dart';

class OutboxConflictsPage extends StatefulWidget {
  const OutboxConflictsPage({
    super.key,
    required this.service,
    this.db,
  });

  final OutboxConflictService service;
  final AppDatabase? db;

  @override
  State<OutboxConflictsPage> createState() => _OutboxConflictsPageState();
}

class _OutboxConflictsPageState extends State<OutboxConflictsPage> {
  List<OutboxEntry> _entries = [];
  bool _isLoading = true;
  bool _isRetryingAll = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final entries = await widget.service.listErrors();
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Không tải được danh sách lỗi';
        _isLoading = false;
      });
    }
  }

  Future<void> _retryOne(OutboxEntry entry) async {
    try {
      await widget.service.retry(entry.id);
      if (!mounted) return;
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã thử đồng bộ lại')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thử lại thất bại')),
      );
    }
  }

  Future<void> _retryAll() async {
    setState(() => _isRetryingAll = true);
    try {
      await widget.service.retryAll();
      if (!mounted) return;
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã thử đồng bộ lại tất cả')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thử lại tất cả thất bại')),
      );
    } finally {
      if (mounted) {
        setState(() => _isRetryingAll = false);
      }
    }
  }

  Future<void> _edit(OutboxEntry entry) async {
    final saved = await OutboxEditSheet.show(
      context,
      service: widget.service,
      entry: entry,
      db: widget.db,
    );
    if (saved && mounted) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đồng bộ lỗi'),
        actions: [
          if (_entries.isNotEmpty)
            TextButton(
              onPressed: _isRetryingAll ? null : _retryAll,
              child: _isRetryingAll
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Thử lại tất cả'),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : _entries.isEmpty
          ? RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  Center(child: Text('Không có lỗi đồng bộ')),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _entries.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final entry = _entries[index];
                  final reason =
                      labelOutboxReason(entry.lastError) ?? entry.lastError;
                  return ListTile(
                    title: Text(labelEntityType(entry.entityType)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reason ?? '—',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_shortenId(entry.id)} · ${_formatCreatedAt(entry.createdAt)}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                    trailing: Wrap(
                      spacing: 4,
                      children: [
                        TextButton(
                          onPressed: () => _edit(entry),
                          child: const Text('Sửa'),
                        ),
                        TextButton(
                          onPressed: () => _retryOne(entry),
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                    isThreeLine: true,
                  );
                },
              ),
            ),
    );
  }
}

String _shortenId(String id) {
  final trimmed = id.trim();
  if (trimmed.length <= 8) return trimmed;
  return '${trimmed.substring(0, 8)}…';
}

String _formatCreatedAt(DateTime createdAt) {
  const offset = Duration(hours: 7);
  final ict = createdAt.toUtc().add(offset);
  final day = ict.day.toString().padLeft(2, '0');
  final month = ict.month.toString().padLeft(2, '0');
  final hour = ict.hour.toString().padLeft(2, '0');
  final minute = ict.minute.toString().padLeft(2, '0');
  return '$day/$month $hour:$minute';
}
