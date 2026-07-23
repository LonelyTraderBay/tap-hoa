import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/local/database.dart';
import '../shifts/shift_repository.dart';
import 'cash_voucher_service.dart';

class RecordCashVoucherSheet extends StatefulWidget {
  const RecordCashVoucherSheet({
    super.key,
    required this.direction,
    required this.db,
    required this.cashVoucherService,
  });

  final String direction;
  final AppDatabase db;
  final CashVoucherService cashVoucherService;

  static Future<bool> show(
    BuildContext context, {
    required String direction,
    required AppDatabase db,
    required CashVoucherService cashVoucherService,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => RecordCashVoucherSheet(
        direction: direction,
        db: db,
        cashVoucherService: cashVoucherService,
      ),
    );
    return result ?? false;
  }

  @override
  State<RecordCashVoucherSheet> createState() => _RecordCashVoucherSheetState();
}

class _RecordCashVoucherSheetState extends State<RecordCashVoucherSheet> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String _channel = 'cash';
  String? _categoryId;
  List<CashCategoriesLocalData> _categories = [];
  bool _isLoadingCategories = true;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final rows = await (widget.db.select(widget.db.cashCategoriesLocal)
          ..where((c) => c.direction.equals(widget.direction))
          ..orderBy([(c) => OrderingTerm.asc(c.sortOrder)]))
        .get();
    if (!mounted) return;
    setState(() {
      _categories = rows;
      _categoryId = rows.isNotEmpty ? rows.first.id : null;
      _isLoadingCategories = false;
    });
  }

  Future<void> _confirm() async {
    final categoryId = _categoryId;
    if (categoryId == null) {
      setState(() => _error = 'Chọn danh mục');
      return;
    }
    final amount = int.tryParse(_amountController.text.trim()) ?? 0;
    if (amount <= 0) {
      setState(() => _error = 'Nhập số tiền hợp lệ');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      await widget.cashVoucherService.recordVoucher(
        direction: widget.direction,
        categoryId: categoryId,
        channel: _channel,
        amountVnd: amount,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on NoOpenShiftException {
      if (!mounted) return;
      setState(() => _error = 'Không có ca đang mở');
    } on StateError catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Ghi phiếu thất bại');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String get _title => widget.direction == 'in' ? 'Phiếu thu' : 'Phiếu chi';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _title,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          if (_isLoadingCategories)
            const Center(child: CircularProgressIndicator())
          else if (_categories.isEmpty)
            const Text('Chưa có danh mục', textAlign: TextAlign.center)
          else
            DropdownButtonFormField<String>(
              initialValue: _categoryId,
              decoration: const InputDecoration(labelText: 'Danh mục'),
              items: _categories
                  .map(
                    (category) => DropdownMenuItem(
                      value: category.id,
                      child: Text(category.name),
                    ),
                  )
                  .toList(),
              onChanged: _isSubmitting
                  ? null
                  : (value) => setState(() => _categoryId = value),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(labelText: 'Số tiền (VND)'),
          ),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'cash', label: Text('Tiền mặt')),
              ButtonSegment(value: 'transfer', label: Text('Chuyển khoản')),
            ],
            selected: {_channel},
            onSelectionChanged: _isSubmitting
                ? null
                : (selected) => setState(() => _channel = selected.first),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(labelText: 'Ghi chú (tuỳ chọn)'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, textAlign: TextAlign.center),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _isSubmitting || _categories.isEmpty ? null : _confirm,
            child: _isSubmitting
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }
}
