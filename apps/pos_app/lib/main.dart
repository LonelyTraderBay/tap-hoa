import 'package:flutter/material.dart';

import 'data/local/database.dart';
import 'data/remote/api_client.dart';
import 'data/sync/outbox_worker.dart';
import 'data/sync/pull_catalog.dart';
import 'data/sync/sync_scheduler.dart';
import 'features/auth/auth_repository.dart';
import 'features/auth/login_page.dart';
import 'features/cash/cash_voucher_service.dart';
import 'features/customers/customer_repository.dart';
import 'features/customers/debt_payment_service.dart';
import 'features/pos/checkout_service.dart';
import 'features/products/product_repository.dart';
import 'features/products/product_service.dart';
import 'features/reports/day_report_repository.dart';
import 'features/shifts/shift_repository.dart';
import 'features/sync_status/sync_status_banner.dart';

void main() {
  final database = AppDatabase();
  const tokenStorage = SecureTokenStorage();
  final apiClient = ApiClient(tokenStorage: tokenStorage);
  final repository = AuthRepository(
    dio: apiClient.dio,
    secureStorage: tokenStorage,
    db: database,
  );
  final shiftRepository = ShiftRepository(dio: apiClient.dio, db: database);
  final dayReportRepository = DayReportRepository(
    dio: apiClient.dio,
    db: database,
  );
  final productRepository = ProductRepository(database);
  final productService = ProductService(database);
  final customerRepository = CustomerRepository(
    db: database,
    dio: apiClient.dio,
  );
  final debtPaymentService = DebtPaymentService(
    db: database,
    shiftRepository: shiftRepository,
  );
  final cashVoucherService = CashVoucherService(
    db: database,
    shiftRepository: shiftRepository,
  );
  final pullCatalog = PullCatalog(db: database, dio: apiClient.dio);
  final outboxWorker = OutboxWorker(db: database, dio: apiClient.dio);
  final checkoutService = CheckoutService(
    db: database,
    shiftRepository: shiftRepository,
  );
  runApp(
    SyncScheduler(
      outboxWorker: outboxWorker,
      child: PosApp(
        database: database,
        authRepository: repository,
        shiftRepository: shiftRepository,
        dayReportRepository: dayReportRepository,
        productRepository: productRepository,
        productService: productService,
        customerRepository: customerRepository,
        debtPaymentService: debtPaymentService,
        cashVoucherService: cashVoucherService,
        pullCatalog: pullCatalog,
        checkoutService: checkoutService,
        outboxWorker: outboxWorker,
      ),
    ),
  );
}

class PosApp extends StatelessWidget {
  const PosApp({
    super.key,
    required this.database,
    required this.authRepository,
    required this.shiftRepository,
    required this.dayReportRepository,
    required this.productRepository,
    required this.productService,
    required this.customerRepository,
    required this.debtPaymentService,
    required this.cashVoucherService,
    required this.pullCatalog,
    required this.checkoutService,
    required this.outboxWorker,
  });

  final AppDatabase database;
  final AuthRepository authRepository;
  final ShiftRepository shiftRepository;
  final DayReportRepository dayReportRepository;
  final ProductRepository productRepository;
  final ProductService productService;
  final CustomerRepository customerRepository;
  final DebtPaymentService debtPaymentService;
  final CashVoucherService cashVoucherService;
  final PullCatalog pullCatalog;
  final CheckoutService checkoutService;
  final OutboxWorker outboxWorker;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tap Hoa POS',
      builder: (context, child) => Column(
        children: [
          SafeArea(
            bottom: false,
            child: SyncStatusBanner(db: database),
          ),
          Expanded(child: child ?? const SizedBox.shrink()),
        ],
      ),
      home: LoginPage(
        repository: authRepository,
        shiftRepository: shiftRepository,
        dayReportRepository: dayReportRepository,
        productRepository: productRepository,
        productService: productService,
        customerRepository: customerRepository,
        debtPaymentService: debtPaymentService,
        cashVoucherService: cashVoucherService,
        database: database,
        pullCatalog: pullCatalog,
        checkoutService: checkoutService,
        outboxWorker: outboxWorker,
      ),
    );
  }
}
