import 'package:flutter/material.dart';

import '../../data/local/database.dart';
import '../../data/sync/outbox_worker.dart';
import '../../data/sync/pull_catalog.dart';
import '../../data/sync/sync_scheduler.dart';
import '../auth/auth_repository.dart';
import '../cash/cash_voucher_service.dart';
import '../customers/customer_repository.dart';
import '../customers/debt_customer_list_page.dart';
import '../customers/debt_payment_service.dart';
import '../inventory/inventory_hub_page.dart';
import '../inventory/inventory_service.dart';
import '../pos/checkout_service.dart';
import '../products/product_repository.dart';
import '../products/product_service.dart';
import '../reports/day_report_page.dart';
import '../reports/day_report_repository.dart';
import '../reports/stock_on_hand_repository.dart';
import '../users/user_management_page.dart' show userRoleLabel;
import '../shifts/open_shift_page.dart';
import '../shifts/shift_repository.dart';

/// §4.8 "App điện thoại (ngoài quầy)" — owner/store_manager được xem báo
/// cáo/tồn/công nợ mà KHÔNG cần mở ca bán hàng tại quầy. Cashier luôn phải
/// mở ca (việc chính là bán hàng tại quầy) nên không bao giờ được cấp lối
/// vào trang này — mọi nơi điều hướng tới [QuickViewHubPage]
/// (`entry_choice_page.dart`, `open_shift_page.dart`) phải tự kiểm tra hàm
/// này trước.
bool quickViewAllowedForRole(String role) =>
    role == 'owner' || role == 'store_manager';

/// Hub "Xem nhanh, không mở ca": tái sử dụng nguyên vẹn các trang báo cáo/
/// kiểm tồn/công nợ đã có (DayReportPage, InventoryHubPage,
/// DebtCustomerListPage) — trang này chỉ là một màn điều hướng thuần
/// (không tự đọc/ghi dữ liệu gì), nên "read-only" theo đúng nghĩa DoD G3:
/// không có form, không ghi Drift/outbox trực tiếp tại đây. Các trang đích
/// vẫn giữ nguyên khả năng ghi của chúng (vd thu nợ tại chỗ từ
/// DebtCustomerListPage → CustomerDetailPage → RecordDebtPaymentSheet).
class QuickViewHubPage extends StatefulWidget {
  const QuickViewHubPage({
    super.key,
    required this.user,
    required this.shiftRepository,
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
    this.syncSchedulerKey,
  });

  final AuthUser user;
  final ShiftRepository shiftRepository;
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
  final GlobalKey<SyncSchedulerState>? syncSchedulerKey;

  @override
  State<QuickViewHubPage> createState() => _QuickViewHubPageState();
}

class _QuickViewHubPageState extends State<QuickViewHubPage> {
  List<StoreOption> _stores = [];
  StoreOption? _selectedStore;
  bool _isLoading = true;
  String? _message;

  bool get _isOwner => widget.user.role == 'owner';

  @override
  void initState() {
    super.initState();
    _loadStores();
  }

  Future<void> _loadStores() async {
    try {
      final stores = await widget.shiftRepository.fetchStores();
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

  void _openShiftFlow() {
    Navigator.of(context).pushReplacement(
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
          syncSchedulerKey: widget.syncSchedulerKey,
        ),
      ),
    );
  }

  void _openDayReport() {
    final store = _selectedStore;
    if (store == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DayReportPage(
          repository: widget.dayReportRepository,
          stockOnHandRepository: widget.stockOnHandRepository,
          storeId: store.id,
          role: widget.user.role,
        ),
      ),
    );
  }

  void _openInventory() {
    final store = _selectedStore;
    if (store == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => InventoryHubPage(
          db: widget.database,
          dio: widget.dayReportRepository.dio,
          inventoryService: InventoryService(db: widget.database),
          productRepository: widget.productRepository,
          stockOnHandRepository: widget.stockOnHandRepository,
          storeId: store.id,
          role: widget.user.role,
        ),
      ),
    );
  }

  void _openDebtList() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DebtCustomerListPage(
          repository: widget.customerRepository,
          debtPaymentService: widget.debtPaymentService,
          database: widget.database,
          storeId: _selectedStore?.id,
          dio: widget.dayReportRepository.dio,
          role: widget.user.role,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Xem nhanh')),
      body: SafeArea(
        child: Column(
          children: [
            // Lối thoát "mở ca bán hàng" luôn hiện, không phụ thuộc trạng
            // thái tải danh sách cửa hàng bên dưới — DoD G3: "Có đường quay
            // lại/điều hướng sang mở ca bán hàng bình thường bất cứ lúc nào
            // từ màn Xem nhanh".
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Xin chào ${widget.user.name}',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${userRoleLabel(widget.user.role)} · Xem nhanh, không mở ca',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _openShiftFlow,
                    icon: const Icon(Icons.point_of_sale_outlined),
                    label: const Text('Mở ca bán hàng'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (_message != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(_message!, textAlign: TextAlign.center),
                          ),
                        if (_stores.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: DropdownButtonFormField<StoreOption>(
                              initialValue: _selectedStore,
                              decoration: InputDecoration(
                                labelText: _isOwner ? 'Điểm kiểm kho' : 'Cửa hàng',
                              ),
                              items: _stores
                                  .map(
                                    (store) => DropdownMenuItem(
                                      value: store,
                                      child: Text('${store.code} — ${store.name}'),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (store) =>
                                  setState(() => _selectedStore = store),
                            ),
                          ),
                        if (_isOwner)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              'Báo cáo doanh thu và công nợ xem tổng hợp tất cả '
                              'điểm bán. Điểm chọn ở trên chỉ dùng để kiểm kho.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        Card(
                          child: ListTile(
                            enabled: _selectedStore != null,
                            leading: const Icon(Icons.bar_chart_outlined),
                            title: const Text('Báo cáo doanh thu nhanh'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: _selectedStore == null ? null : _openDayReport,
                          ),
                        ),
                        Card(
                          child: ListTile(
                            enabled: _selectedStore != null,
                            leading: const Icon(Icons.warehouse_outlined),
                            title: const Text('Kiểm kho / quét mã xem tồn'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: _selectedStore == null ? null : _openInventory,
                          ),
                        ),
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.people_outline),
                            title: const Text('Công nợ khách hàng'),
                            subtitle: const Text('Xem danh sách và thu nợ tại chỗ'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: _openDebtList,
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
