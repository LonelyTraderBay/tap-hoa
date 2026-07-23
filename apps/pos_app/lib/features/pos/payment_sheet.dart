import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../customers/credit_limit.dart';
import '../customers/customer_picker_sheet.dart';
import '../customers/customer_repository.dart';
import 'cart.dart';
import 'checkout_service.dart';

class PaymentSheet extends StatefulWidget {
  const PaymentSheet({
    super.key,
    required this.cart,
    required this.checkoutService,
    required this.customerRepository,
    required this.onCompleted,
  });

  final Cart cart;
  final CheckoutService checkoutService;
  final CustomerRepository customerRepository;
  final VoidCallback onCompleted;

  static Future<void> show(
    BuildContext context, {
    required Cart cart,
    required CheckoutService checkoutService,
    required CustomerRepository customerRepository,
    required VoidCallback onCompleted,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => PaymentSheet(
        cart: cart,
        checkoutService: checkoutService,
        customerRepository: customerRepository,
        onCompleted: onCompleted,
      ),
    );
  }

  @override
  State<PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<PaymentSheet> {
  final _cashController = TextEditingController();
  final _transferController = TextEditingController();
  final _debtController = TextEditingController();
  bool _isSubmitting = false;
  String? _error;
  CustomerRecord? _selectedCustomer;

  int get _totalVnd => widget.cart.totalVnd;

  int get _paidVnd {
    final cash = int.tryParse(_cashController.text.trim()) ?? 0;
    final transfer = int.tryParse(_transferController.text.trim()) ?? 0;
    final debt = int.tryParse(_debtController.text.trim()) ?? 0;
    return cash + transfer + debt;
  }

  int get _debtVnd => int.tryParse(_debtController.text.trim()) ?? 0;

  @override
  void initState() {
    super.initState();
    _cashController.text = _totalVnd.toString();
    _cashController.addListener(_onAmountChanged);
    _transferController.addListener(_onAmountChanged);
    _debtController.addListener(_onAmountChanged);
  }

  @override
  void dispose() {
    _cashController.dispose();
    _transferController.dispose();
    _debtController.dispose();
    super.dispose();
  }

  void _onAmountChanged() => setState(() {});

  Future<void> _pickCustomer() async {
    final customer = await CustomerPickerSheet.show(
      context,
      repository: widget.customerRepository,
    );
    if (!mounted || customer == null) return;
    setState(() => _selectedCustomer = customer);
  }

  Future<void> _complete() async {
    final cash = int.tryParse(_cashController.text.trim()) ?? 0;
    final transfer = int.tryParse(_transferController.text.trim()) ?? 0;
    final debt = int.tryParse(_debtController.text.trim()) ?? 0;
    final payment = PaymentSplit(cash: cash, transfer: transfer, debt: debt);

    if (debt > 0 && _selectedCustomer == null) {
      setState(() => _error = 'Chọn khách hàng cho công nợ');
      return;
    }

    if (debt > 0 &&
        _selectedCustomer != null &&
        exceedsCreditLimit(
          balanceVnd: _selectedCustomer!.balanceVnd,
          debtAmount: debt,
          creditLimitVnd: _selectedCustomer!.creditLimitVnd,
        )) {
      final limit = _selectedCustomer!.creditLimitVnd!;
      final remaining = limit - _selectedCustomer!.balanceVnd;
      setState(() {
        _error =
            'Vượt hạn mức nợ (còn được nợ: ${remaining < 0 ? 0 : remaining} VND)';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      await widget.checkoutService.complete(
        cart: widget.cart,
        payment: payment,
        customerId: _selectedCustomer?.id,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onCompleted();
    } on PaymentMismatchException {
      if (!mounted) return;
      setState(() => _error = 'Tổng thanh toán phải bằng $_totalVnd VND');
    } on InsufficientStockException {
      if (!mounted) return;
      setState(() => _error = 'Không đủ tồn kho');
    } on CreditLimitExceededException catch (error) {
      if (!mounted) return;
      final remaining = error.creditLimitVnd - error.balanceVnd;
      setState(() {
        _error =
            'Vượt hạn mức nợ (còn được nợ: ${remaining < 0 ? 0 : remaining} VND)';
      });
    } on StateError catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Thanh toán thất bại');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final remaining = _totalVnd - _paidVnd;
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
            'Thanh toán',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Tổng: $_totalVnd VND',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          _amountField('Tiền mặt', _cashController),
          const SizedBox(height: 12),
          _amountField('Chuyển khoản', _transferController),
          const SizedBox(height: 12),
          _amountField('Công nợ', _debtController),
          if (_debtVnd > 0) ...[
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                _selectedCustomer == null
                    ? 'Chưa chọn khách hàng'
                    : _selectedCustomer!.name,
              ),
              subtitle: _selectedCustomer?.phone != null
                  ? Text(_selectedCustomer!.phone!)
                  : null,
              trailing: TextButton(
                onPressed: _isSubmitting ? null : _pickCustomer,
                child: const Text('Chọn khách'),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            remaining == 0
                ? 'Đủ tiền'
                : remaining > 0
                ? 'Còn thiếu: $remaining VND'
                : 'Thừa: ${-remaining} VND',
            textAlign: TextAlign.center,
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, textAlign: TextAlign.center),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _isSubmitting || remaining != 0 ? null : _complete,
            child: _isSubmitting
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Hoàn tất'),
          ),
        ],
      ),
    );
  }

  Widget _amountField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(labelText: label),
    );
  }
}
