import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';

import '../../data/local/database.dart';

Future<void> showAllowNegativeStockSheet(
  BuildContext context, {
  required AppDatabase db,
  required Dio dio,
  required String storeId,
  required String role,
}) async {
  if (role != 'owner' && role != 'store_manager') {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chỉ chủ/quản lý được sửa cài đặt kho')),
    );
    return;
  }
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _AllowNegativeStockSheet(
      db: db,
      dio: dio,
      storeId: storeId,
    ),
  );
}

class _AllowNegativeStockSheet extends StatefulWidget {
  const _AllowNegativeStockSheet({
    required this.db,
    required this.dio,
    required this.storeId,
  });

  final AppDatabase db;
  final Dio dio;
  final String storeId;

  @override
  State<_AllowNegativeStockSheet> createState() =>
      _AllowNegativeStockSheetState();
}

class _AllowNegativeStockSheetState extends State<_AllowNegativeStockSheet> {
  bool _allowNegativeStock = false;
  bool _busy = false;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final store = await (widget.db.select(widget.db.storesLocal)
          ..where((t) => t.id.equals(widget.storeId)))
        .getSingleOrNull();
    if (!mounted) return;
    setState(() {
      _allowNegativeStock = store?.allowNegativeStock ?? false;
      _loading = false;
    });
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.dio.patch<void>(
        '/stores/${widget.storeId}/allow-negative-stock',
        data: {'allowNegativeStock': _allowNegativeStock},
      );
      await (widget.db.update(widget.db.storesLocal)
            ..where((t) => t.id.equals(widget.storeId)))
          .write(
        StoresLocalCompanion(
          allowNegativeStock: Value(_allowNegativeStock),
          updatedAt: Value(DateTime.now().toUtc()),
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _allowNegativeStock
                ? 'Đã cho phép âm tồn khi bán/xuất tại máy này'
                : 'Đã tắt cho phép âm tồn tại máy này',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Lưu thất bại (cần online)');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Cho phép âm tồn',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Khi bật, bán hàng/xuất kho tại cửa hàng này vẫn được '
                  'thực hiện dù không đủ tồn (tồn có thể âm). '
                  'Không ảnh hưởng duyệt chuyển kho/xuất hủy trên server — '
                  'server luôn từ chối nếu không đủ tồn.',
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Cho phép âm tồn khi bán/xuất kho'),
                  value: _allowNegativeStock,
                  onChanged: (v) => setState(() => _allowNegativeStock = v),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!),
                ],
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _busy ? null : _save,
                  child: const Text('Lưu'),
                ),
              ],
            ),
    );
  }
}
