import 'package:flutter/material.dart';

import '../../data/local/database.dart';
import 'outbox_conflict_service.dart';
import 'outbox_edit_sheet.dart';
import 'outbox_reason_labels.dart';

/// §6.3 — xung đột đồng bộ nghiêm trọng phải "giữ local, đánh dấu cần chủ xử
/// lý". `dead_letter` (đã hết lượt retry hạ tầng, xem `outboxMaxRetries`) là
/// mốc "nghiêm trọng" theo đúng tinh thần đó — chỉ owner/store_manager được
/// tự Sửa/Thử lại các dòng này; cashier chỉ xem, phải báo chủ. Dòng `error`
/// (chưa hết lượt retry, còn tự thử lại được) KHÔNG bị ảnh hưởng bởi hàm
/// này — mọi role thao tác như cũ (xem `outbox_conflicts_page.dart` phần
/// build danh sách).
bool outboxDeadLetterActionsAllowedForRole(String role) =>
    role == 'owner' || role == 'store_manager';

class OutboxConflictsPage extends StatefulWidget {
  const OutboxConflictsPage({
    super.key,
    required this.service,
    required this.role,
    this.db,
  });

  final OutboxConflictService service;

  /// Role của người dùng hiện tại — gate thao tác trên dòng `dead_letter`
  /// (xem [outboxDeadLetterActionsAllowedForRole]). Không ảnh hưởng dòng
  /// `error`.
  final String role;
  final AppDatabase? db;

  @override
  State<OutboxConflictsPage> createState() => _OutboxConflictsPageState();
}

class _OutboxConflictsPageState extends State<OutboxConflictsPage> {
  List<OutboxEntry> _entries = [];
  bool _isLoading = true;
  bool _isRetryingAll = false;
  String? _error;

  bool get _canActOnDeadLetter =>
      outboxDeadLetterActionsAllowedForRole(widget.role);

  /// Có ít nhất 1 dòng mà role hiện tại được phép "Thử lại tất cả" hay
  /// không — owner/store_manager luôn được (mọi status); cashier chỉ được
  /// khi còn dòng `error` (không tính `dead_letter`). Dùng để khoá hẳn nút
  /// bulk khi tất cả các dòng còn lại đều là `dead_letter` và role không đủ
  /// — tránh nút bấm "thành công" giả (không có gì được thử lại thật).
  bool get _hasBulkRetryableEntries => _canActOnDeadLetter
      ? _entries.isNotEmpty
      : _entries.any((entry) => entry.status != 'dead_letter');

  void _denyDeadLetterAction() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Lỗi này cần chủ hoặc quản lý xử lý — thu ngân không thao tác được',
        ),
      ),
    );
  }

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
    // Phòng thủ kép: nút "Thử lại" trên dòng dead_letter đã bị khoá
    // (`onPressed: null`) cho cashier ở `build()`, nhưng vẫn kiểm lại role
    // tại đây theo đúng house style owner-only khác trong app
    // (`sync_diagnostics_page.dart::_openRestoreFlow`) thay vì tin tưởng
    // tuyệt đối vào việc khoá nút.
    if (entry.status == 'dead_letter' && !_canActOnDeadLetter) {
      _denyDeadLetterAction();
      return;
    }
    try {
      await widget.service.retry(entry.id);
      if (!mounted) return;
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã thử đồng bộ lại')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Thử lại thất bại')));
    }
  }

  Future<void> _retryAll() async {
    setState(() => _isRetryingAll = true);
    try {
      // Cashier: loại dead_letter khỏi lượt bulk — nếu không, nút này sẽ là
      // lối vòng qua khoá per-row (xem `OutboxConflictService.retryAll`).
      await widget.service.retryAll(includeDeadLetter: _canActOnDeadLetter);
      if (!mounted) return;
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã thử đồng bộ lại tất cả')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Thử lại tất cả thất bại')));
    } finally {
      if (mounted) {
        setState(() => _isRetryingAll = false);
      }
    }
  }

  Future<void> _edit(OutboxEntry entry) async {
    // Cùng lý do phòng thủ kép như `_retryOne` — nút "Sửa" mở
    // `OutboxEditSheet`, nơi nút "Lưu và thử lại" cũng requeue outbox y hệt
    // Thử lại (chỉ khác kèm sửa payload), nên phải khoá cùng điều kiện.
    if (entry.status == 'dead_letter' && !_canActOnDeadLetter) {
      _denyDeadLetterAction();
      return;
    }
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
              // Khoá hẳn nút bulk khi cashier không còn dòng nào retry được
              // (toàn bộ danh sách còn lại là dead_letter) — tránh bấm
              // "thành công" giả không thử lại được gì (xem
              // `_hasBulkRetryableEntries`).
              onPressed: (_isRetryingAll || !_hasBulkRetryableEntries)
                  ? null
                  : _retryAll,
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
                  final isDeadLetter = entry.status == 'dead_letter';
                  // §6.3 — chỉ dead_letter (nghiêm trọng) bị khoá; error
                  // (còn tự retry được ở hạ tầng) giữ nguyên hành vi cũ cho
                  // MỌI role, kể cả cashier.
                  final isLockedForRole = isDeadLetter && !_canActOnDeadLetter;
                  final reason =
                      labelOutboxReason(entry.lastError) ?? entry.lastError;
                  final accentColor = isDeadLetter
                      ? theme.colorScheme.tertiary
                      : theme.colorScheme.error;
                  return ListTile(
                    leading: Icon(
                      // dead_letter = hết lượt retry hạ tầng (mạng/server),
                      // payload không có gì sai; error = server từ chối
                      // nghiệp vụ, cần sửa dữ liệu. Hai icon khác hẳn nhau để
                      // người dùng không nhầm "phải sửa gì đó" khi thực ra
                      // chỉ cần chờ mạng ổn rồi thử lại.
                      isDeadLetter ? Icons.wifi_off : Icons.error_outline,
                      color: accentColor,
                    ),
                    title: Text(labelEntityType(entry.entityType)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Badge "Cần chủ xử lý": hiện cho MỌI role khi
                        // dead_letter (không riêng cashier) — đây là thuộc
                        // tính của bản ghi (mức độ nghiêm trọng), không phải
                        // của quyền hạn người xem; owner/store_manager cũng
                        // cần biết dòng nào đã hết retry hạ tầng để ưu tiên
                        // xử lý.
                        if (isDeadLetter) ...[
                          Chip(
                            label: const Text('Cần chủ xử lý'),
                            labelStyle: TextStyle(
                              color: theme.colorScheme.onTertiaryContainer,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                            backgroundColor:
                                theme.colorScheme.tertiaryContainer,
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          const SizedBox(height: 4),
                        ],
                        Text(
                          reason ?? '—',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: accentColor,
                          ),
                        ),
                        if (isDeadLetter)
                          Text(
                            'Đã tự thử lại ${entry.retryCount} lần',
                            style: theme.textTheme.bodySmall,
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
                          onPressed: isLockedForRole
                              ? null
                              : () => _edit(entry),
                          child: const Text('Sửa'),
                        ),
                        TextButton(
                          onPressed: isLockedForRole
                              ? null
                              : () => _retryOne(entry),
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
