import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/sync/outbox_worker.dart';
import '../../data/sync/pull_catalog.dart';
import '../auth/auth_repository.dart';
import '../pos/pos_page.dart';
import '../pos/checkout_service.dart';
import '../products/product_repository.dart';
import 'shift_repository.dart';

class OpenShiftPage extends StatefulWidget {
  const OpenShiftPage({
    super.key,
    required this.repository,
    required this.user,
    required this.productRepository,
    required this.pullCatalog,
    required this.checkoutService,
    required this.outboxWorker,
  });

  final ShiftRepository repository;
  final AuthUser user;
  final ProductRepository productRepository;
  final PullCatalog pullCatalog;
  final CheckoutService checkoutService;
  final OutboxWorker outboxWorker;

  @override
  State<OpenShiftPage> createState() => _OpenShiftPageState();
}

class _OpenShiftPageState extends State<OpenShiftPage> {
  final _openingCashController = TextEditingController();
  List<StoreOption> _stores = [];
  StoreOption? _selectedStore;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _loadStores();
  }

  @override
  void dispose() {
    _openingCashController.dispose();
    super.dispose();
  }

  Future<void> _loadStores() async {
    try {
      final stores = await widget.repository.fetchStores();
      if (!mounted) return;
      setState(() {
        _stores = stores;
        _selectedStore = stores.isNotEmpty ? stores.first : null;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _message = 'Không tải được danh sách cửa hàng';
        _isLoading = false;
      });
    }
  }

  Future<void> _openShift() async {
    final store = _selectedStore;
    final openingCash = int.tryParse(_openingCashController.text.trim());
    if (store == null) {
      setState(() => _message = 'Chọn cửa hàng');
      return;
    }
    if (openingCash == null || openingCash < 0) {
      setState(() => _message = 'Nhập tiền mở ca hợp lệ');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _message = null;
    });

    try {
      await widget.repository.openShift(
        storeId: store.id,
        openingCash: openingCash,
        userId: widget.user.id,
      );
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => PosPage(
            productRepository: widget.productRepository,
            checkoutService: widget.checkoutService,
            pullCatalog: widget.pullCatalog,
            outboxWorker: widget.outboxWorker,
            storeId: store.id,
          ),
        ),
      );
    } on ShiftAlreadyOpenException {
      if (!mounted) return;
      setState(() => _message = 'Đã có ca đang mở tại cửa hàng này');
    } catch (_) {
      if (!mounted) return;
      setState(() => _message = 'Mở ca thất bại');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mở ca')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _isLoading
                ? const CircularProgressIndicator()
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Xin chào ${widget.user.name}',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 24),
                      DropdownButtonFormField<StoreOption>(
                        initialValue: _selectedStore,
                        decoration: const InputDecoration(
                          labelText: 'Cửa hàng',
                        ),
                        items: _stores
                            .map(
                              (store) => DropdownMenuItem(
                                value: store,
                                child: Text('${store.code} — ${store.name}'),
                              ),
                            )
                            .toList(),
                        onChanged: _isSubmitting
                            ? null
                            : (store) => setState(() => _selectedStore = store),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _openingCashController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(
                          labelText: 'Tiền mở ca (VND)',
                        ),
                        onSubmitted: (_) => _isSubmitting ? null : _openShift(),
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: _isSubmitting ? null : _openShift,
                        child: _isSubmitting
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Mở ca'),
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
