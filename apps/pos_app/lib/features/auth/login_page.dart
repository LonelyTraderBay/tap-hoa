import 'package:flutter/material.dart';

import '../../data/sync/outbox_worker.dart';
import '../../data/sync/pull_catalog.dart';
import 'auth_repository.dart';
import '../customers/customer_repository.dart';
import '../customers/debt_payment_service.dart';
import '../pos/checkout_service.dart';
import '../products/product_repository.dart';
import '../reports/day_report_repository.dart';
import '../shifts/open_shift_page.dart';
import '../shifts/shift_repository.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    required this.repository,
    required this.shiftRepository,
    required this.dayReportRepository,
    required this.productRepository,
    required this.customerRepository,
    required this.debtPaymentService,
    required this.pullCatalog,
    required this.checkoutService,
    required this.outboxWorker,
  });

  final AuthRepository repository;
  final ShiftRepository shiftRepository;
  final DayReportRepository dayReportRepository;
  final ProductRepository productRepository;
  final CustomerRepository customerRepository;
  final DebtPaymentService debtPaymentService;
  final PullCatalog pullCatalog;
  final CheckoutService checkoutService;
  final OutboxWorker outboxWorker;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _message;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });
    try {
      final user = await widget.repository.login(
        _phoneController.text.trim(),
        _passwordController.text,
      );
      if (mounted) {
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => OpenShiftPage(
              repository: widget.shiftRepository,
              user: user,
              dayReportRepository: widget.dayReportRepository,
              productRepository: widget.productRepository,
              customerRepository: widget.customerRepository,
              debtPaymentService: widget.debtPaymentService,
              pullCatalog: widget.pullCatalog,
              checkoutService: widget.checkoutService,
              outboxWorker: widget.outboxWorker,
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _message = 'Đăng nhập thất bại');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Tap Hoa POS',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Số điện thoại'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Mật khẩu'),
                  onSubmitted: (_) => _isLoading ? null : _login(),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Đăng nhập'),
                ),
                if (_message != null) ...[
                  const SizedBox(height: 12),
                  Text(_message!, textAlign: TextAlign.center),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
