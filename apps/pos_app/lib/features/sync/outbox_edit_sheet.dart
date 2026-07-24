import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/local/database.dart';
import 'outbox_conflict_service.dart';
import 'outbox_reason_labels.dart';

enum _SheetMode { identity, qty, json }

class OutboxEditSheet extends StatefulWidget {
  const OutboxEditSheet({
    super.key,
    required this.service,
    required this.entry,
    this.db,
    this.initialJsonWarning,
  });

  final OutboxConflictService service;
  final OutboxEntry entry;
  final AppDatabase? db;
  final String? initialJsonWarning;

  static Future<bool> show(
    BuildContext context, {
    required OutboxConflictService service,
    required OutboxEntry entry,
    AppDatabase? db,
    String? initialJsonWarning,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => OutboxEditSheet(
        service: service,
        entry: entry,
        db: db,
        initialJsonWarning: initialJsonWarning,
      ),
    );
    return result ?? false;
  }

  @override
  State<OutboxEditSheet> createState() => _OutboxEditSheetState();
}

class _OutboxEditSheetState extends State<OutboxEditSheet> {
  late _SheetMode _mode;
  late final TextEditingController _skuController;
  late final TextEditingController _barcodeController;
  late final TextEditingController _jsonController;
  final Map<String, TextEditingController> _qtyControllers = {};
  final Map<String, String> _productLabels = {};

  bool _isSubmitting = false;
  String? _error;
  String? _warning;

  @override
  void initState() {
    super.initState();
    _warning = widget.initialJsonWarning;
    _mode = _resolveInitialMode();
    _initControllers();
  }

  _SheetMode _resolveInitialMode() {
    if (widget.initialJsonWarning != null) {
      return _SheetMode.json;
    }
    final reason = widget.entry.lastError;
    if (_isIdentityConflict(reason, widget.entry.entityType)) {
      return _SheetMode.identity;
    }
    if (_isQtyConflict(reason, widget.entry.entityType)) {
      return _SheetMode.qty;
    }
    return _SheetMode.json;
  }

  bool _isIdentityConflict(String? reason, String entityType) {
    return entityType == 'product_upsert' &&
        (reason == 'sku_conflict' || reason == 'barcode_conflict');
  }

  bool _isQtyConflict(String? reason, String entityType) {
    return reason == 'insufficient_stock' &&
        (entityType == 'sale' || entityType == 'wastage');
  }

  void _initControllers() {
    final payload =
        jsonDecode(widget.entry.payloadJson) as Map<String, dynamic>;

    _skuController = TextEditingController(text: payload['sku'] as String? ?? '');
    _barcodeController =
        TextEditingController(text: payload['barcode'] as String? ?? '');

    final pretty = const JsonEncoder.withIndent('  ').convert(payload);
    _jsonController = TextEditingController(text: pretty);

    final lines = (payload['lines'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    for (final line in lines) {
      final productId = line['productId'] as String?;
      if (productId == null) continue;
      _qtyControllers[productId] =
          TextEditingController(text: line['qty']?.toString() ?? '');
      _productLabels[productId] = productId;
    }
    _loadProductNames();
  }

  Future<void> _loadProductNames() async {
    final db = widget.db;
    if (db == null || _productLabels.isEmpty) return;

    for (final productId in _productLabels.keys.toList()) {
      final row = await (db.select(db.products)
            ..where((p) => p.id.equals(productId)))
          .getSingleOrNull();
      if (row != null && mounted) {
        setState(() => _productLabels[productId] = row.name);
      }
    }
  }

  @override
  void dispose() {
    _skuController.dispose();
    _barcodeController.dispose();
    _jsonController.dispose();
    for (final controller in _qtyControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _openJsonMode({String? warning}) {
    setState(() {
      _mode = _SheetMode.json;
      _error = null;
      if (warning != null) {
        _warning = warning;
      }
    });
  }

  Future<void> _save() async {
    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final saved = switch (_mode) {
        _SheetMode.identity => await _saveIdentity(),
        _SheetMode.qty => await _saveQty(),
        _SheetMode.json => await _saveJson(),
      };
      if (!saved || !mounted) return;
      Navigator.of(context).pop(true);
    } on StateError catch (error) {
      if (!mounted) return;
      if (error.message == 'use_raw_json') {
        setState(() => _isSubmitting = false);
        _openJsonMode(
          warning:
              'Không thể sửa tồn kho tự động. Chỉ sửa payload; kiểm tra tồn local thủ công.',
        );
        return;
      }
      if (error.message == 'invalid_qty') {
        setState(() => _error = 'Số lượng phải lớn hơn 0');
      } else {
        setState(() => _error = error.message);
      }
    } on FormatException {
      if (!mounted) return;
      setState(() => _error = 'JSON không hợp lệ');
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Lưu thất bại');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<bool> _saveIdentity() async {
    final sku = _skuController.text.trim();
    if (sku.isEmpty) {
      setState(() => _error = 'Nhập mã SKU');
      return false;
    }
    final barcodeText = _barcodeController.text.trim();
    await widget.service.saveProductUpsertIdentity(
      outboxRowId: widget.entry.id,
      sku: sku,
      barcode: barcodeText.isEmpty ? null : barcodeText,
    );
    return true;
  }

  Future<bool> _saveQty() async {
    final productIdToQty = <String, String>{};
    for (final entry in _qtyControllers.entries) {
      final text = entry.value.text.trim();
      if (text.isEmpty) {
        setState(() => _error = 'Nhập số lượng cho mọi dòng');
        return false;
      }
      final qty = Decimal.tryParse(text);
      if (qty == null || qty <= Decimal.zero) {
        setState(() => _error = 'Số lượng phải lớn hơn 0');
        return false;
      }
      productIdToQty[entry.key] = text;
    }

    final localSynced = await widget.service.saveInsufficientStockQtys(
      outboxRowId: widget.entry.id,
      productIdToQty: productIdToQty,
    );
    if (!localSynced && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Đã lưu payload; một số dòng local không cập nhật — kiểm tra tồn thủ công.',
          ),
        ),
      );
    }
    return true;
  }

  Future<bool> _saveJson() async {
    await widget.service.saveRawJson(widget.entry.id, _jsonController.text);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Đã lưu JSON. Bảng local khác không được cập nhật tự động.',
          ),
        ),
      );
    }
    return true;
  }

  String get _title {
    return switch (_mode) {
      _SheetMode.identity => 'Sửa SKU / mã vạch',
      _SheetMode.qty => 'Sửa số lượng',
      _SheetMode.json => 'Sửa JSON',
    };
  }

  bool get _canShowJsonShortcut =>
      _mode != _SheetMode.json &&
      (_isIdentityConflict(widget.entry.lastError, widget.entry.entityType) ||
          _isQtyConflict(widget.entry.lastError, widget.entry.entityType));

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _title,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              labelEntityType(widget.entry.entityType),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (_warning != null) ...[
              const SizedBox(height: 12),
              Material(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    _warning!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (_mode == _SheetMode.identity) ...[
              TextField(
                controller: _skuController,
                decoration: const InputDecoration(labelText: 'Mã SKU'),
                enabled: !_isSubmitting,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _barcodeController,
                decoration: const InputDecoration(labelText: 'Mã vạch'),
                enabled: !_isSubmitting,
              ),
            ] else if (_mode == _SheetMode.qty) ...[
              if (_qtyControllers.isEmpty)
                const Text(
                  'Không có dòng hàng trong payload — dùng Sửa JSON.',
                  textAlign: TextAlign.center,
                )
              else
                for (final entry in _qtyControllers.entries) ...[
                  TextField(
                    controller: entry.value,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                    ],
                    decoration: InputDecoration(
                      labelText: _productLabels[entry.key] ?? entry.key,
                    ),
                    enabled: !_isSubmitting,
                  ),
                  const SizedBox(height: 12),
                ],
            ] else ...[
              TextField(
                controller: _jsonController,
                maxLines: 12,
                decoration: const InputDecoration(
                  labelText: 'payloadJson',
                  alignLabelWithHint: true,
                ),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                enabled: !_isSubmitting,
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _isSubmitting ? null : _save,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Lưu và thử lại'),
            ),
            if (_canShowJsonShortcut) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: _isSubmitting
                    ? null
                    : () => _openJsonMode(
                          warning:
                              'Chỉ sửa payload; kiểm tra dữ liệu local thủ công.',
                        ),
                child: const Text('Sửa JSON'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
