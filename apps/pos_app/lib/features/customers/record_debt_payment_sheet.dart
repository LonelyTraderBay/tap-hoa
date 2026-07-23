import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'debt_payment_service.dart';

class RecordDebtPaymentSheet extends StatefulWidget {
  const RecordDebtPaymentSheet({
    super.key,
    required this.customerId,
    required this.balanceVnd,
    required this.debtPaymentService,
  });

  final String customerId;
  final int balanceVnd;
  final DebtPaymentService debtPaymentService;

  static Future<bool> show(
    BuildContext context, {
    required String customerId,
    required int balanceVnd,
    required DebtPaymentService debtPaymentService,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => RecordDebtPaymentSheet(
        customerId: customerId,
        balanceVnd: balanceVnd,
        debtPaymentService: debtPaymentService,
      ),
    );
    return result ?? false;
  }

  @override
  State<RecordDebtPaymentSheet> createState() => _RecordDebtPaymentSheetState();
}

class _RecordDebtPaymentSheetState extends State<RecordDebtPaymentSheet> {
  late final TextEditingController _amountController;
  final _noteController = TextEditingController();
  String _paymentMethod = 'cash';
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.balanceVnd.toString(),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final amount = int.tryParse(_amountController.text.trim()) ?? 0;
    if (amount <= 0) {
      setState(() => _error = 'Nhập số tiền hợp lệ');
      return;
    }
    if (amount > widget.balanceVnd) {
      setState(() => _error = 'Không thu quá số dư ${widget.balanceVnd} VND');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      await widget.debtPaymentService.recordPayment(
        customerId: widget.customerId,
        amountVnd: amount,
        paymentMethod: _paymentMethod,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on StateError catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Thu nợ thất bại');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Thu nợ',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Còn nợ: ${widget.balanceVnd} VND',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(labelText: 'Số tiền'),
          ),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'cash', label: Text('Tiền mặt')),
              ButtonSegment(value: 'transfer', label: Text('Chuyển khoản')),
            ],
            selected: {_paymentMethod},
            onSelectionChanged: _isSubmitting
                ? null
                : (selected) => setState(() => _paymentMethod = selected.first),
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
            onPressed: _isSubmitting ? null : _confirm,
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
