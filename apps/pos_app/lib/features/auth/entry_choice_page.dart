import 'package:flutter/material.dart';

import '../../data/local/database.dart';
import '../../data/sync/outbox_worker.dart';
import '../../data/sync/pull_catalog.dart';
import '../../data/sync/sync_scheduler.dart';
import 'auth_repository.dart';
import '../cash/cash_voucher_service.dart';
import '../customers/customer_repository.dart';
import '../customers/debt_payment_service.dart';
import '../pos/checkout_service.dart';
import '../products/product_repository.dart';
import '../products/product_service.dart';
import '../quick_view/quick_view_hub_page.dart';
import '../reports/day_report_repository.dart';
import '../reports/stock_on_hand_repository.dart';
import '../shifts/open_shift_page.dart';
import '../shifts/shift_repository.dart';
import '../users/user_management_page.dart' show userRoleLabel;

/// §4.8 "App điện thoại (ngoài quầy)": sau đăng nhập, owner/store_manager
/// chọn giữa mở ca bán hàng tại quầy (luồng cũ, không đổi) hoặc "Xem nhanh"
/// báo cáo/tồn/công nợ mà không cần mở ca (luồng mới — xem
/// `quick_view_hub_page.dart`). `login_page.dart` chỉ điều hướng tới trang
/// này khi `quickViewAllowedForRole(user.role)` đúng; cashier không bao giờ
/// thấy trang này — vẫn thẳng `OpenShiftPage` như trước G3.
class EntryChoicePage extends StatelessWidget {
  const EntryChoicePage({
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

  void _openShift(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => OpenShiftPage(
          repository: shiftRepository,
          user: user,
          dayReportRepository: dayReportRepository,
          stockOnHandRepository: stockOnHandRepository,
          productRepository: productRepository,
          productService: productService,
          customerRepository: customerRepository,
          debtPaymentService: debtPaymentService,
          cashVoucherService: cashVoucherService,
          database: database,
          pullCatalog: pullCatalog,
          checkoutService: checkoutService,
          outboxWorker: outboxWorker,
          syncSchedulerKey: syncSchedulerKey,
        ),
      ),
    );
  }

  void _openQuickView(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => QuickViewHubPage(
          user: user,
          shiftRepository: shiftRepository,
          dayReportRepository: dayReportRepository,
          stockOnHandRepository: stockOnHandRepository,
          productRepository: productRepository,
          productService: productService,
          customerRepository: customerRepository,
          debtPaymentService: debtPaymentService,
          cashVoucherService: cashVoucherService,
          database: database,
          pullCatalog: pullCatalog,
          checkoutService: checkoutService,
          outboxWorker: outboxWorker,
          syncSchedulerKey: syncSchedulerKey,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bắt đầu')),
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
                  'Xin chào ${user.name}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  userRoleLabel(user.role),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => _openShift(context),
                  icon: const Icon(Icons.point_of_sale_outlined),
                  label: const Text('Mở ca bán hàng'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _openQuickView(context),
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('Xem nhanh (không mở ca)'),
                ),
                const SizedBox(height: 12),
                Text(
                  'Xem nhanh: báo cáo doanh thu, kiểm kho, công nợ — không '
                  'cần mở ca bán hàng tại quầy.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
