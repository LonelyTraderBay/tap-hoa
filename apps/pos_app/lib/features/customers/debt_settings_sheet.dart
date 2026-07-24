import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/local/database.dart';

Future<void> showDebtSettingsSheet(
  BuildContext context, {
  required AppDatabase db,
  required Dio dio,
  required String storeId,
  required String role,
}) async {
  if (role != 'owner' && role != 'store_manager') {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chỉ chủ/quản lý được sửa ngưỡng quá hạn')),
    );
    return;
  }
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _DebtSettingsSheet(
      db: db,
      dio: dio,
      storeId: storeId,
    ),
  );
}

class _DebtSettingsSheet extends StatefulWidget {
  const _DebtSettingsSheet({
    required this.db,
    required this.dio,
    required this.storeId,
  });

  final AppDatabase db;
  final Dio dio;
  final String storeId;

  @override
  State<_DebtSettingsSheet> createState() => _DebtSettingsSheetState();
}

class _DebtSettingsSheetState extends State<_DebtSettingsSheet> {
  final _daysController = TextEditingController();
  bool _busy = false;
  String? _error;
  bool _loading = true;

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
    _daysController.text = (store?.debtOverdueDays ?? 30).toString();
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _daysController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final days = int.tryParse(_daysController.text.trim());
    if (days == null || days < 1) {
      setState(() => _error = 'Nhập số ngày nguyên dương');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.dio.patch<void>(
        '/stores/${widget.storeId}/debt-overdue-days',
        data: {'debtOverdueDays': days},
      );
      await (widget.db.update(widget.db.storesLocal)
            ..where((t) => t.id.equals(widget.storeId)))
          .write(
        StoresLocalCompanion(
          debtOverdueDays: Value(days),
          updatedAt: Value(DateTime.now().toUtc()),
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã đặt ngưỡng quá hạn $days ngày')),
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
                  'Ngưỡng nợ quá hạn',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Khách nợ quá X ngày (tính từ khoản nợ cũ nhất chưa trả) sẽ hiện Quá hạn.',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _daysController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Số ngày (X)',
                  ),
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
