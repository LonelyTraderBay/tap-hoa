import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

String _normalizeBarcodeQuery(String value) => value.trim().toLowerCase();

bool posProductMatchesQuery(ProductWithStock product, String rawQuery) {
  final q = rawQuery.trim().toLowerCase();
  if (q.isEmpty) {
    return true;
  }
  final barcode = product.barcode;
  return product.name.toLowerCase().contains(q) ||
      product.sku.toLowerCase().contains(q) ||
      (barcode != null && _normalizeBarcodeQuery(barcode).contains(q));
}

ProductWithStock? posExactBarcodeMatch(
  Iterable<ProductWithStock> products,
  String rawQuery,
) {
  final q = _normalizeBarcodeQuery(rawQuery);
  if (q.isEmpty) {
    return null;
  }

  ProductWithStock? match;
  for (final product in products) {
    final barcode = product.barcode;
    if (barcode == null || _normalizeBarcodeQuery(barcode) != q) {
      continue;
    }
    if (match != null) {
      return null;
    }
    match = product;
  }
  return match;
}

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
  static final Decimal _weightedQtyStep = Decimal.parse('0.001');

  final _searchController = TextEditingController();
  final _cart = Cart();
  String _query = '';
  String? _message;
  bool _isSyncing = false;
  String? _groupFilterId;
  String? _pendingAutoAddBarcodeQuery;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _addProductToCart(ProductWithStock product, {required Decimal qty}) {
    final existing = _cart.lines.indexWhere(
      (line) => line.productId == product.id,
    );
    if (existing >= 0) {
      final line = _cart.lines[existing];
      _cart.update(product.id, line.qty + qty);
    } else {
      _cart.add(
        CartLine(
          productId: product.id,
          name: product.name,
          unitPrice: product.basePriceVnd,
          qty: qty,
          unitLabel: product.displayUnit,
          isWeighted: product.isWeighted,
        ),
      );
    }
  }

  Future<Decimal?> _showWeightedQtyDialog(ProductWithStock product) async {
    String errorText = '';
    String input = '';
    return showDialog<Decimal>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Nhập kg: ${product.name}'),
              content: TextField(
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                ],
                decoration: InputDecoration(
                  labelText: 'Số kg',
                  helperText: 'Hàng cân: tối đa 3 chữ số thập phân',
                  errorText: errorText.isEmpty ? null : errorText,
                ),
                onChanged: (value) => input = value,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Hủy'),
                ),
                FilledButton(
                  onPressed: () {
                    final raw = input.trim().replaceAll(',', '.');
                    final qty = Decimal.tryParse(raw);
                    if (qty == null || qty <= Decimal.zero) {
                      setDialogState(() {
                        errorText = 'Số lượng phải lớn hơn 0';
                      });
                      return;
                    }
                    if (_decimalPlaces(raw) > 3) {
                      setDialogState(() {
                        errorText = 'Tối đa 3 chữ số thập phân';
                      });
                      return;
                    }
                    Navigator.of(context).pop(qty);
                  },
                  child: const Text('Thêm'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _addProduct(ProductWithStock product) async {
    final qty = product.isWeighted
        ? await _showWeightedQtyDialog(product)
        : Decimal.one;
    if (qty == null || !mounted) return;
    setState(() {
      _addProductToCart(product, qty: qty);
      _message = null;
    });
  }

  void _scheduleExactBarcodeAdd(List<ProductWithStock> products) {
    final normalizedQuery = _normalizeBarcodeQuery(_query);
    if (normalizedQuery.isEmpty ||
        _pendingAutoAddBarcodeQuery == normalizedQuery) {
      return;
    }

    final product = posExactBarcodeMatch(products, normalizedQuery);
    if (product == null) {
      return;
    }

    _pendingAutoAddBarcodeQuery = normalizedQuery;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }
      if (_normalizeBarcodeQuery(_query) != normalizedQuery) {
        _pendingAutoAddBarcodeQuery = null;
        return;
      }
      final qty = product.isWeighted
          ? await _showWeightedQtyDialog(product)
          : Decimal.one;
      if (!mounted) {
        return;
      }
      setState(() {
        if (qty != null) {
          _addProductToCart(product, qty: qty);
          _message = null;
        }
        _searchController.clear();
        _query = '';
        _pendingAutoAddBarcodeQuery = null;
      });
    });
  }

  Decimal _qtyStep(CartLine line) =>
      line.isWeighted ? _weightedQtyStep : Decimal.one;

  String _formatLineQty(CartLine line) {
    if (line.isWeighted) {
      return line.qty.toStringAsFixed(3);
    }
    return line.qty.truncate().toString();
  }

  int _decimalPlaces(String raw) {
    final normalized = raw.replaceAll(',', '.');
    final dotIndex = normalized.indexOf('.');
    if (dotIndex == -1) return 0;
    return normalized.length - dotIndex - 1;
  }

  void _adjustLineQty(CartLine line, Decimal delta) {
    final nextQty = line.qty + delta;
    if (nextQty <= Decimal.zero) return;
    setState(() => _cart.update(line.productId, nextQty));
  }

  Future<void> _editLineQty(CartLine line) async {
    final controller = TextEditingController(text: _formatLineQty(line));
    String errorText = '';
    try {
      final value = await showDialog<Decimal>(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: Text('Sửa SL: ${line.name}'),
                content: TextField(
                  controller: controller,
                  autofocus: true,
                  keyboardType: line.isWeighted
                      ? const TextInputType.numberWithOptions(decimal: true)
                      : TextInputType.number,
                  inputFormatters: [
                    line.isWeighted
                        ? FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))
                        : FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: InputDecoration(
                    labelText: 'Số lượng',
                    helperText: line.isWeighted
                        ? 'Hàng cân: tối đa 3 chữ số thập phân'
                        : 'Hàng thường: số nguyên',
                    errorText: errorText.isEmpty ? null : errorText,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Hủy'),
                  ),
                  FilledButton(
                    onPressed: () {
                      final raw = controller.text.trim().replaceAll(',', '.');
                      final qty = Decimal.tryParse(raw);
                      if (qty == null || qty <= Decimal.zero) {
                        setDialogState(() {
                          errorText = 'Số lượng phải lớn hơn 0';
                        });
                        return;
                      }
                      if (!line.isWeighted && qty != qty.truncate()) {
                        setDialogState(() {
                          errorText = 'Hàng thường phải là số nguyên';
                        });
                        return;
                      }
                      if (line.isWeighted && _decimalPlaces(raw) > 3) {
                        setDialogState(() {
                          errorText = 'Tối đa 3 chữ số thập phân';
                        });
                        return;
                      }
                      Navigator.of(context).pop(qty);
                    },
                    child: const Text('Lưu'),
                  ),
                ],
              );
            },
          );
        },
      );
      if (value == null || !mounted) return;
      setState(() => _cart.update(line.productId, value));
    } finally {
      controller.dispose();
    }
  }

  Future<void> _removeLine(CartLine line) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa dòng?'),
        content: Text('Xóa ${line.name} khỏi giỏ hàng?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _cart.remove(line.productId));
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

  Future<int?> _showDiscountDialog({
    required String title,
    required int initialVnd,
    required int maxVnd,
  }) async {
    final controller = TextEditingController(text: initialVnd.toString());
    var errorText = '';
    try {
      return await showDialog<int>(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: Text(title),
                content: TextField(
                  controller: controller,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: 'Giảm giá (VND)',
                    helperText: 'Tối đa $maxVnd VND',
                    errorText: errorText.isEmpty ? null : errorText,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Hủy'),
                  ),
                  FilledButton(
                    onPressed: () {
                      final value = int.tryParse(controller.text.trim()) ?? 0;
                      if (value > maxVnd) {
                        setDialogState(() {
                          errorText = 'Không được vượt quá $maxVnd VND';
                        });
                        return;
                      }
                      Navigator.of(context).pop(value);
                    },
                    child: const Text('Lưu'),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      controller.dispose();
    }
  }

  Future<void> _editLineDiscount(CartLine line) async {
    final value = await _showDiscountDialog(
      title: 'Giảm dòng: ${line.name}',
      initialVnd: line.discountVnd,
      maxVnd: line.grossTotalVnd,
    );
    if (value == null || !mounted) return;
    setState(() => _cart.updateLineDiscount(line.productId, value));
  }

  Future<void> _editInvoiceDiscount() async {
    final value = await _showDiscountDialog(
      title: 'Giảm hóa đơn',
      initialVnd: _cart.discountVnd,
      maxVnd: _cart.subtotalVnd,
    );
    if (value == null || !mounted) return;
    setState(() => _cart.discountVnd = value);
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
    return posProductMatchesQuery(product, _query);
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
                      storeId: widget.storeId,
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
                    canEditCatalog:
                        widget.role == 'owner' ||
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
                labelText: 'Tìm tên, mã SKU hoặc barcode',
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
                final allProducts = snapshot.data ?? [];
                _scheduleExactBarcodeAdd(allProducts);
                final products = allProducts.where(_matches).toList();
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
                      final qtyLabel = _formatLineQty(line);
                      final qtyWithUnit = line.unitLabel.isEmpty
                          ? qtyLabel
                          : '$qtyLabel ${line.unitLabel}';
                      return ListTile(
                        title: Text(line.name),
                        subtitle: Text(
                          line.discountVnd > 0
                              ? '$qtyWithUnit × ${line.unitPrice} VND = ${line.grossTotalVnd} VND\nGiảm dòng: ${line.discountVnd} VND'
                              : '$qtyWithUnit × ${line.unitPrice} VND',
                        ),
                        isThreeLine: line.discountVnd > 0,
                        trailing: Wrap(
                          spacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          alignment: WrapAlignment.end,
                          children: [
                            Text('${line.lineTotal} VND'),
                            IconButton(
                              tooltip: 'Giảm SL',
                              visualDensity: VisualDensity.compact,
                              onPressed:
                                  line.qty - _qtyStep(line) <= Decimal.zero
                                  ? null
                                  : () => _adjustLineQty(line, -_qtyStep(line)),
                              icon: const Icon(Icons.remove),
                            ),
                            TextButton(
                              onPressed: () => _editLineQty(line),
                              child: Text(qtyLabel),
                            ),
                            IconButton(
                              tooltip: 'Tăng SL',
                              visualDensity: VisualDensity.compact,
                              onPressed: () =>
                                  _adjustLineQty(line, _qtyStep(line)),
                              icon: const Icon(Icons.add),
                            ),
                            TextButton(
                              onPressed: () => _editLineDiscount(line),
                              child: const Text('Giảm'),
                            ),
                            IconButton(
                              tooltip: 'Xóa dòng',
                              visualDensity: VisualDensity.compact,
                              onPressed: () => _removeLine(line),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ),
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
                      _cart.discountVnd > 0
                          ? 'Tạm tính: ${_cart.subtotalVnd} VND\nGiảm HĐ: ${_cart.discountVnd} VND\nTổng: ${_cart.totalVnd} VND'
                          : 'Tổng: ${_cart.totalVnd} VND',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  TextButton(
                    onPressed: _cart.lines.isEmpty
                        ? null
                        : _editInvoiceDiscount,
                    child: const Text('Giảm HĐ'),
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
