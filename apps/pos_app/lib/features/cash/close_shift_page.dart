import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/local/database.dart';
import '../../data/sync/outbox_worker.dart';
import '../../data/sync/pull_catalog.dart';
import '../auth/auth_repository.dart';
import '../cash/cash_voucher_service.dart';
import '../customers/customer_repository.dart';
import '../customers/debt_payment_service.dart';
import '../pos/checkout_service.dart';
import '../products/product_repository.dart';
import '../products/product_service.dart';
import '../reports/day_report_repository.dart';
import '../reports/stock_on_hand_repository.dart';
import '../shifts/open_shift_page.dart';
import '../shifts/shift_repository.dart';
import 'expected_cash.dart';

class CloseShiftPage extends StatefulWidget {
  const CloseShiftPage({
    super.key,
    required this.shiftRepository,
    required this.storeId,
    required this.user,
    required this.dayReportRepository,
    required this.stockOnHandRepository,
    required this.productRepository,
    required this.productService,
    required this.customerRepository,
    required this.debtPaymentService,
    required this.cashVoucherService,
    required this.database,
    required this.pullCatalog,
    required this.checkoutService,
    required this.outboxWorker,
  });

  final ShiftRepository shiftRepository;
  final String storeId;
  final AuthUser user;
  final DayReportRepository dayReportRepository;
  final StockOnHandRepository stockOnHandRepository;
  final ProductRepository productRepository;
  final ProductService productService;
  final CustomerRepository customerRepository;
  final DebtPaymentService debtPaymentService;
  final CashVoucherService cashVoucherService;
  final AppDatabase database;
  final PullCatalog pullCatalog;
  final CheckoutService checkoutService;
  final OutboxWorker outboxWorker;

  @override
  State<CloseShiftPage> createState() => _CloseShiftPageState();
}

class _CloseShiftPageState extends State<CloseShiftPage> {
  final _closingCashController = TextEditingController();
  final _noteController = TextEditingController();
  ShiftCashBreakdown? _breakdown;
  String? _shiftId;
  String? _loadError;
  bool _isSubmitting = false;
  String? _submitError;

  @override
  void initState() {
    super.initState();
    _closingCashController.addListener(() => setState(() {}));
    _loadBreakdown();
  }

  @override
  void dispose() {
    _closingCashController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadBreakdown() async {
    try {
      final shift = await widget.shiftRepository.requireOpenShift(
        storeId: widget.storeId,
        userId: widget.user.id,
      );
      final breakdown = await widget.shiftRepository.breakdownForOpenShift(
        storeId: widget.storeId,
        userId: widget.user.id,
      );
      if (!mounted) return;
      setState(() {
        _shiftId = shift.id;
        _breakdown = breakdown;
        _closingCashController.text = breakdown.expectedCash.toString();
      });
    } on NoOpenShiftException {
      if (!mounted) return;
      setState(() => _loadError = 'Không có ca đang mở');
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadError = 'Không tải được dữ liệu ca');
    }
  }

  int? get _closingCash => int.tryParse(_closingCashController.text.trim());

  int? get _variance {
    final breakdown = _breakdown;
    final closing = _closingCash;
    if (breakdown == null || closing == null) return null;
    return breakdown.variance(closing);
  }

  Future<void> _confirmClose() async {
    final shiftId = _shiftId;
    final breakdown = _breakdown;
    final closingCash = _closingCash;
    if (shiftId == null || breakdown == null) return;
    if (closingCash == null || closingCash < 0) {
      setState(() => _submitError = 'Nhập tiền đếm hợp lệ');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    try {
      final variance = breakdown.variance(closingCash);
      await widget.shiftRepository.closeShift(
        shiftId: shiftId,
        closingCash: closingCash,
        expectedCashVnd: breakdown.expectedCash,
        varianceVnd: variance,
        transferInShiftVnd: breakdown.transferInShift,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => OpenShiftPage(
            repository: widget.shiftRepository,
            user: widget.user,
            dayReportRepository: widget.dayReportRepository,
            stockOnHandRepository: widget.stockOnHandRepository,
            productRepository: widget.productRepository,
            productService: widget.productService,
            customerRepository: widget.customerRepository,
            debtPaymentService: widget.debtPaymentService,
            cashVoucherService: widget.cashVoucherService,
            database: widget.database,
            pullCatalog: widget.pullCatalog,
            checkoutService: widget.checkoutService,
            outboxWorker: widget.outboxWorker,
          ),
        ),
        (_) => false,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitError = 'Đóng ca thất bại');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Widget _breakdownLine(String label, int amount, {bool bold = false}) {
    final style = bold
        ? Theme.of(context).textTheme.titleMedium
        : Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text('$amount VND', style: style),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đóng ca')),
      body: _loadError != null
          ? Center(child: Text(_loadError!))
          : _breakdown == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Đối chiếu tiền mặt',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  _breakdownLine('Mở ca', _breakdown!.openingCash),
                  _breakdownLine('Bán TM', _breakdown!.saleCash),
                  _breakdownLine('Thu nợ TM', _breakdown!.debtPaymentCash),
                  _breakdownLine('Phiếu thu TM', _breakdown!.voucherCashIn),
                  _breakdownLine('Phiếu chi TM', _breakdown!.voucherCashOut),
                  const Divider(),
                  _breakdownLine(
                    'Tiền mặt kỳ vọng',
                    _breakdown!.expectedCash,
                    bold: true,
                  ),
                  const SizedBox(height: 16),
                  _breakdownLine(
                    'CK trong ca',
                    _breakdown!.transferInShift,
                    bold: true,
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _closingCashController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Tiền đếm thực tế (VND)',
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_variance != null)
                    Text(
                      'Lệch: ${_variance! >= 0 ? '+' : ''}${_variance!} VND',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: _variance == 0 ? null : Colors.orange,
                      ),
                    ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _noteController,
                    decoration: const InputDecoration(
                      labelText: 'Ghi chú (tuỳ chọn)',
                    ),
                  ),
                  if (_submitError != null) ...[
                    const SizedBox(height: 8),
                    Text(_submitError!, textAlign: TextAlign.center),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _isSubmitting ? null : _confirmClose,
                    child: _isSubmitting
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Đóng ca'),
                  ),
                ],
              ),
            ),
    );
  }
}
