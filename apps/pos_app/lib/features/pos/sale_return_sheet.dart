import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/local/database.dart';
import 'sale_return_refund.dart';
import 'sale_return_service.dart';

Future<void> showSaleReturnSheet(
  BuildContext context, {
  required AppDatabase db,
  required SaleReturnService service,
  required String storeId,
  required String role,
  required DateTime date,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _SaleReturnSheet(
      db: db,
      service: service,
      storeId: storeId,
      role: role,
    ),
  );
}

class _SaleReturnSheet extends StatefulWidget {
  const _SaleReturnSheet({
    required this.db,
    required this.service,
    required this.storeId,
    required this.role,
  });

  final AppDatabase db;
  final SaleReturnService service;
  final String storeId;
  final String role;

  @override
  State<_SaleReturnSheet> createState() => _SaleReturnSheetState();
}

class _SaleReturnSheetState extends State<_SaleReturnSheet> {
  final _saleIdController = TextEditingController();
  final _cashController = TextEditingController(text: '0');
  final _transferController = TextEditingController(text: '0');
  final _debtCreditController = TextEditingController(text: '0');
  String? _error;
  bool _busy = false;
  List<SaleLinesLocalData> _lines = [];
  final _qtyControllers = <String, TextEditingController>{};
  final _productNames = <String, String>{};
  String? _customerId;
  int _lineRefundTotal = 0;

  @override
  void dispose() {
    _saleIdController.dispose();
    _cashController.dispose();
    _transferController.dispose();
    _debtCreditController.dispose();
    for (final c in _qtyControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadSale() async {
    final id = _saleIdController.text.trim();
    if (id.isEmpty) return;
    final sales = await (widget.db.select(
      widget.db.salesLocal,
    )..where((t) => t.storeId.equals(widget.storeId))).get();
    final sale = sales.where((s) => s.id.startsWith(id)).toList();
    if (sale.isEmpty) {
      setState(() => _error = 'Không tìm thấy đơn');
      return;
    }
    final match = sale.first;
    final lines = await (widget.db.select(
      widget.db.saleLinesLocal,
    )..where((t) => t.saleId.equals(match.id))).get();
    final productIds = lines.map((l) => l.productId).toSet().toList();
    final products = productIds.isEmpty
        ? <Product>[]
        : await (widget.db.select(
            widget.db.products,
          )..where((t) => t.id.isIn(productIds))).get();
    final names = {for (final p in products) p.id: p.name};
    for (final c in _qtyControllers.values) {
      c.dispose();
    }
    _qtyControllers
      ..clear()
      ..addEntries(
        lines.map(
          (l) => MapEntry(l.productId, TextEditingController(text: l.qty)),
        ),
      );
    setState(() {
      _lines = lines;
      _productNames
        ..clear()
        ..addAll(names);
      _customerId = match.customerId;
      _error = null;
      _saleIdController.text = match.id;
      _recomputeRefundDefaults();
    });
  }

  void _recomputeRefundDefaults() {
    var total = 0;
    for (final line in _lines) {
      final raw = _qtyControllers[line.productId]?.text.trim() ?? '0';
      final qty = Decimal.tryParse(raw) ?? Decimal.zero;
      if (qty <= Decimal.zero) continue;
      total += discountedReturnLineRefundVnd(
        soldQty: Decimal.parse(line.qty),
        returnQty: qty,
        soldLineTotalVnd: line.lineTotal,
      );
    }
    _lineRefundTotal = total;
    _cashController.text = total.toString();
    _transferController.text = '0';
    _debtCreditController.text = '0';
  }

  Future<void> _submit() async {
    if (_lines.isEmpty) return;
    setState(() => _busy = true);
    try {
      final inputs = <SaleReturnLineInput>[];
      var total = 0;
      for (final line in _lines) {
        final raw = _qtyControllers[line.productId]?.text.trim() ?? '0';
        final qty = Decimal.parse(raw);
        if (qty <= Decimal.zero) continue;
        final refund = discountedReturnLineRefundVnd(
          soldQty: Decimal.parse(line.qty),
          returnQty: qty,
          soldLineTotalVnd: line.lineTotal,
        );
        total += refund;
        inputs.add(
          SaleReturnLineInput(
            productId: line.productId,
            qty: qty,
            unitPrice: line.unitPrice,
            lineRefundVnd: refund,
          ),
        );
      }
      if (inputs.isEmpty) {
        setState(() => _error = 'Nhập số lượng trả');
        return;
      }

      final cash = int.tryParse(_cashController.text.trim()) ?? -1;
      final transfer = int.tryParse(_transferController.text.trim()) ?? -1;
      final debtCredit = int.tryParse(_debtCreditController.text.trim()) ?? -1;
      final splitError = validateSaleReturnRefundSplit(
        lineRefundTotal: total,
        cashRefundVnd: cash,
        transferRefundVnd: transfer,
        debtCreditVnd: debtCredit,
        originalSaleHasCustomer:
            _customerId != null && _customerId!.trim().isNotEmpty,
      );
      if (splitError != null) {
        setState(() {
          _error = switch (splitError) {
            'refund_mismatch' => 'Tổng hoàn phải bằng $total VND',
            'debt_credit_requires_customer' =>
              'Giảm nợ chỉ khi đơn gốc có khách',
            'negative_refund' => 'Số tiền hoàn không hợp lệ',
            _ => 'Phân bổ hoàn không hợp lệ',
          };
        });
        return;
      }

      await widget.service.createReturn(
        originalSaleId: _saleIdController.text.trim(),
        lines: inputs,
        cashRefundVnd: cash,
        transferRefundVnd: transfer,
        debtCreditVnd: debtCredit,
        role: widget.role,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã ghi đổi trả')));
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasCustomer = _customerId != null && _customerId!.trim().isNotEmpty;
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Đổi trả', style: Theme.of(context).textTheme.titleLarge),
            TextField(
              controller: _saleIdController,
              decoration: const InputDecoration(
                labelText: 'Mã đơn (hoặc prefix)',
              ),
            ),
            TextButton(onPressed: _loadSale, child: const Text('Tải đơn')),
            ..._lines.map(
              (line) => TextField(
                controller: _qtyControllers[line.productId],
                decoration: InputDecoration(
                  labelText:
                      '${_productNames[line.productId] ?? line.productId} (đã bán ${line.qty})',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (_) => setState(_recomputeRefundDefaults),
              ),
            ),
            if (_lines.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Hoàn: $_lineRefundTotal VND'),
              TextField(
                controller: _cashController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(labelText: 'Hoàn tiền mặt'),
              ),
              TextField(
                controller: _transferController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Hoàn chuyển khoản',
                ),
              ),
              TextField(
                controller: _debtCreditController,
                enabled: hasCustomer,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: hasCustomer
                      ? 'Giảm nợ khách'
                      : 'Giảm nợ (cần khách trên đơn gốc)',
                ),
              ),
            ],
            if (_error != null) Text(_error!),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: const Text('Xác nhận đổi trả'),
            ),
          ],
        ),
      ),
    );
  }
}
