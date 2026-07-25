import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../../data/local/database.dart';
import '../../data/sync/outbox_worker.dart';
import '../../data/sync/pull_catalog.dart';
import '../auth/auth_repository.dart';
import '../cash/cash_ledger_page.dart';
import '../cash/cash_voucher_service.dart';
import '../cash/close_shift_page.dart';
import '../customers/customer_repository.dart';
import '../customers/debt_customer_list_page.dart';
import '../customers/debt_payment_service.dart';
import '../reports/day_report_page.dart';
import '../reports/day_report_repository.dart';
import '../reports/stock_on_hand_repository.dart';
import '../inventory/inventory_hub_page.dart';
import '../inventory/inventory_service.dart';
import '../ledger/ledger_page.dart';
import '../suppliers/suppliers_page.dart';
import '../einvoice/einvoice_page.dart';
import '../cash/bank_recon_page.dart';
import '../cash/cash_fund_page.dart';
import '../sync/outbox_conflict_service.dart';
import '../sync/outbox_conflicts_page.dart';
import '../sync/sync_diagnostics_page.dart';
import '../products/product_list_page.dart';
import '../products/product_repository.dart';
import '../products/product_service.dart';
import '../push/push_service.dart';
import '../shifts/shift_repository.dart';
import 'cart.dart';
import 'checkout_service.dart';
import 'payment_sheet.dart';
import 'receipt_print_settings_page.dart';
import 'sale_return_service.dart';
import 'sale_return_sheet.dart';

class PosPage extends StatefulWidget {
  const PosPage({
    super.key,
    required this.productRepository,
    required this.productService,
    required this.checkoutService,
    required this.customerRepository,
    required this.debtPaymentService,
    required this.pullCatalog,
    required this.outboxWorker,
    required this.dayReportRepository,
    required this.stockOnHandRepository,
    required this.shiftRepository,
    required this.cashVoucherService,
    required this.database,
    required this.user,
    required this.storeId,
    required this.storeName,
    required this.role,
  });

  final ProductRepository productRepository;
  final ProductService productService;
  final CheckoutService checkoutService;
  final CustomerRepository customerRepository;
  final DebtPaymentService debtPaymentService;
  final PullCatalog pullCatalog;
  final OutboxWorker outboxWorker;
  final DayReportRepository dayReportRepository;
  final StockOnHandRepository stockOnHandRepository;
  final ShiftRepository shiftRepository;
  final CashVoucherService cashVoucherService;
  final AppDatabase database;
  final AuthUser user;
  final String storeId;
  final String storeName;
  final String role;

  @override
  State<PosPage> createState() => _PosPageState();
}

class _PosPageState extends State<PosPage> {
  final _searchController = TextEditingController();
  final _cart = Cart();
  String _query = '';
  String? _message;
  bool _isSyncing = false;
  String? _groupFilterId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _addProduct(ProductWithStock product) {
    setState(() {
      final existing = _cart.lines.indexWhere(
        (line) => line.productId == product.id,
      );
      if (existing >= 0) {
        final line = _cart.lines[existing];
        _cart.update(product.id, line.qty + Decimal.one);
      } else {
        _cart.add(
          CartLine(
            productId: product.id,
            name: product.name,
            unitPrice: product.basePriceVnd,
            qty: Decimal.one,
          ),
        );
      }
      _message = null;
    });
  }

  void _openPayment() {
    if (_cart.lines.isEmpty) {
      setState(() => _message = 'Giỏ hàng trống');
      return;
    }
    PaymentSheet.show(
      context,
      cart: _cart,
      checkoutService: widget.checkoutService,
      customerRepository: widget.customerRepository,
      storeName: widget.storeName,
      database: widget.database,
      onCompleted: () {
        setState(() {
          _cart.lines.clear();
          _cart.discountVnd = 0;
          _message = 'Đã bán thành công';
        });
      },
    );
  }

  void _openSaleReturn() {
    if (widget.role != 'owner' && widget.role != 'store_manager') {
      setState(() => _message = 'Chỉ chủ/quản lý được đổi trả');
      return;
    }
    showSaleReturnSheet(
      context,
      db: widget.database,
      service: SaleReturnService(
        db: widget.database,
        shiftRepository: widget.shiftRepository,
      ),
      storeId: widget.storeId,
      role: widget.role,
      date: DateTime.now(),
    );
  }

  void _openReceiptSettings() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReceiptPrintSettingsPage(db: widget.database),
      ),
    );
  }

  void _openOutboxConflicts() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OutboxConflictsPage(
          service: OutboxConflictService(
            db: widget.database,
            worker: widget.outboxWorker,
          ),
          db: widget.database,
        ),
      ),
    );
  }

  Future<void> _sync() async {
    setState(() {
      _isSyncing = true;
      _message = null;
    });
    try {
      await widget.outboxWorker.tick();
      await widget.pullCatalog.pullCatalog(widget.storeId);
      await PushService(
        db: widget.database,
        dio: widget.dayReportRepository.dio,
      ).checkLowStock(widget.storeId);
      if (!mounted) return;
      setState(() => _message = 'Đã đồng bộ');
    } catch (_) {
      if (!mounted) return;
      setState(() => _message = 'Đồng bộ thất bại');
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  bool _matches(ProductWithStock product) {
    if (_query.isEmpty) {
      return true;
    }
    final q = _query.toLowerCase();
    return product.name.toLowerCase().contains(q) ||
        product.sku.toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bán hàng'),
        actions: [
          IconButton(
            onPressed: _isSyncing ? null : _sync,
            icon: _isSyncing
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.cloud_upload_outlined),
            tooltip: 'Đồng bộ',
          ),
          StreamBuilder<int>(
            stream: widget.database.watchOutboxErrorCount(),
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;
              if (count <= 0) {
                return const SizedBox.shrink();
              }
              return IconButton(
                onPressed: _openOutboxConflicts,
                tooltip: 'Đồng bộ lỗi',
                icon: Badge(
                  label: Text('$count'),
                  child: const Icon(Icons.sync_problem),
                ),
              );
            },
          ),
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => DayReportPage(
                    repository: widget.dayReportRepository,
                    stockOnHandRepository: widget.stockOnHandRepository,
                    storeId: widget.storeId,
                    role: widget.role,
                    database: widget.database,
                    shiftRepository: widget.shiftRepository,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.bar_chart_outlined),
            tooltip: 'Báo cáo ngày',
          ),
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => CashLedgerPage(
                    db: widget.database,
                    cashVoucherService: widget.cashVoucherService,
                    shiftRepository: widget.shiftRepository,
                    pullCatalog: widget.pullCatalog,
                    storeId: widget.storeId,
                    userId: widget.user.id,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.account_balance_wallet_outlined),
            tooltip: 'Thu chi',
          ),
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => CloseShiftPage(
                    shiftRepository: widget.shiftRepository,
                    storeId: widget.storeId,
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
              );
            },
            icon: const Icon(Icons.lock_clock_outlined),
            tooltip: 'Đóng ca',
          ),
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => DebtCustomerListPage(
                    repository: widget.customerRepository,
                    debtPaymentService: widget.debtPaymentService,
                    database: widget.database,
                    storeId: widget.storeId,
                    dio: widget.dayReportRepository.dio,
                    role: widget.role,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.people_outline),
            tooltip: 'Khách nợ',
          ),
          TextButton(
            onPressed: _openOutboxConflicts,
            child: const Text('Đồng bộ lỗi'),
          ),
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => SyncDiagnosticsPage(
                    dio: widget.dayReportRepository.dio,
                    db: widget.database,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.devices_other_outlined),
            tooltip: 'Diagnostics sync',
          ),
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => InventoryHubPage(
                    db: widget.database,
                    inventoryService: InventoryService(db: widget.database),
                    productRepository: widget.productRepository,
                    stockOnHandRepository: widget.stockOnHandRepository,
                    storeId: widget.storeId,
                    role: widget.role,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.warehouse_outlined),
            tooltip: 'Kho',
          ),
          IconButton(
            onPressed: _openReceiptSettings,
            icon: const Icon(Icons.print_outlined),
            tooltip: 'Cấu hình in',
          ),
          if (widget.role == 'owner')
            IconButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => LedgerHomePage(
                      repository: LedgerRepository(
                        dio: widget.dayReportRepository.dio,
                      ),
                      isOwner: true,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.menu_book_outlined),
              tooltip: 'Sổ kế toán',
            ),
          if (widget.role == 'owner' || widget.role == 'store_manager')
            IconButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => CashFundPage(
                      repository: CashFundRepository(
                        dio: widget.dayReportRepository.dio,
                      ),
                      storeId: widget.storeId,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.account_balance_wallet_outlined),
              tooltip: 'Sổ quỹ kỳ',
            ),
          if (widget.role == 'owner' || widget.role == 'store_manager')
            IconButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => BankReconPage(
                      repository: BankReconRepository(
                        dio: widget.dayReportRepository.dio,
                      ),
                      storeId: widget.storeId,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.compare_arrows_outlined),
              tooltip: 'Đối chiếu CK',
            ),
          if (widget.role == 'owner' || widget.role == 'store_manager')
            IconButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => EInvoiceIssuePage(
                      repository: EInvoiceRepository(
                        dio: widget.dayReportRepository.dio,
                      ),
                      database: widget.database,
                      storeId: widget.storeId,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.receipt_long_outlined),
              tooltip: 'Xuất HĐĐT',
            ),
          if (widget.role == 'owner' || widget.role == 'store_manager')
            IconButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => SuppliersPage(
                      repository: SuppliersRepository(
                        dio: widget.dayReportRepository.dio,
                      ),
                      storeId: widget.storeId,
                      isOwner: widget.role == 'owner',
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.local_shipping_outlined),
              tooltip: 'Công nợ NCC',
            ),
          if (widget.role == 'owner' || widget.role == 'store_manager')
            IconButton(
              onPressed: _openSaleReturn,
              icon: const Icon(Icons.assignment_return_outlined),
              tooltip: 'Đổi trả',
            ),
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ProductListPage(
                    repository: widget.productRepository,
                    pullCatalog: widget.pullCatalog,
                    storeId: widget.storeId,
                    productService: widget.productService,
                    groupService: ProductGroupService(widget.database),
                    canEditCatalog: widget.role == 'owner' ||
                        widget.role == 'store_manager',
                  ),
                ),
              );
            },
            icon: const Icon(Icons.inventory_2_outlined),
            tooltip: 'Hàng hóa',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Tìm tên hoặc mã SKU',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => setState(() => _query = value.trim()),
            ),
          ),
          SizedBox(
            height: 40,
            child: StreamBuilder<List<ProductGroupRow>>(
              stream: widget.productRepository.watchGroups(),
              builder: (context, snapshot) {
                final groups = snapshot.data ?? [];
                return ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: const Text('Tất cả'),
                        selected: _groupFilterId == null,
                        onSelected: (_) =>
                            setState(() => _groupFilterId = null),
                      ),
                    ),
                    ...groups.map(
                      (g) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(g.name),
                          selected: _groupFilterId == g.id,
                          onSelected: (_) =>
                              setState(() => _groupFilterId = g.id),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          if (_message != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(_message!, textAlign: TextAlign.center),
            ),
          Expanded(
            flex: 2,
            child: StreamBuilder<List<ProductWithStock>>(
              stream: widget.productRepository.watchByStore(
                widget.storeId,
                groupId: _groupFilterId,
              ),
              builder: (context, snapshot) {
                final products = (snapshot.data ?? []).where(_matches).toList();
                if (products.isEmpty) {
                  return const Center(child: Text('Không có hàng phù hợp'));
                }
                return ListView.separated(
                  itemCount: products.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return ListTile(
                      title: Text(product.name),
                      subtitle: Text(
                        '${product.sku} · ${product.displayUnit} · ${product.basePriceVnd} VND · Tồn: ${product.qty}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.add_shopping_cart),
                        onPressed: () => _addProduct(product),
                      ),
                      onTap: () => _addProduct(product),
                    );
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _cart.lines.isEmpty
                ? const Center(child: Text('Chưa có sản phẩm trong giỏ'))
                : ListView.separated(
                    itemCount: _cart.lines.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final line = _cart.lines[index];
                      return ListTile(
                        title: Text(line.name),
                        subtitle: Text('${line.qty} × ${line.unitPrice} VND'),
                        trailing: Text('${line.lineTotal} VND'),
                      );
                    },
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Tổng: ${_cart.totalVnd} VND',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  FilledButton(
                    onPressed: _openPayment,
                    child: const Text('Thanh toán'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
