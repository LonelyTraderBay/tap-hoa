import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pos_app/data/local/database.dart';
import 'package:pos_app/data/sync/outbox_worker.dart';
import 'package:pos_app/data/sync/pull_catalog.dart';
import 'package:pos_app/features/auth/auth_repository.dart';
import 'package:pos_app/features/cash/cash_voucher_service.dart';
import 'package:pos_app/features/customers/customer_repository.dart';
import 'package:pos_app/features/customers/debt_payment_service.dart';
import 'package:pos_app/features/pos/checkout_service.dart';
import 'package:pos_app/features/products/product_repository.dart';
import 'package:pos_app/features/products/product_service.dart';
import 'package:pos_app/features/reports/day_report_repository.dart';
import 'package:pos_app/features/reports/stock_on_hand_repository.dart';
import 'package:pos_app/features/shifts/open_shift_page.dart';
import 'package:pos_app/features/shifts/shift_repository.dart';

class MockShiftRepository extends Mock implements ShiftRepository {}

class MockDayReportRepository extends Mock implements DayReportRepository {}

class MockStockOnHandRepository extends Mock
    implements StockOnHandRepository {}

class MockProductRepository extends Mock implements ProductRepository {}

class MockProductService extends Mock implements ProductService {}

class MockCustomerRepository extends Mock implements CustomerRepository {}

class MockDebtPaymentService extends Mock implements DebtPaymentService {}

class MockCashVoucherService extends Mock implements CashVoucherService {}

class MockPullCatalog extends Mock implements PullCatalog {}

class MockCheckoutService extends Mock implements CheckoutService {}

class MockOutboxWorker extends Mock implements OutboxWorker {}

const _owner = AuthUser(
  id: 'user-owner',
  name: 'Owner',
  role: 'owner',
  storeIds: ['store-1'],
  canLedger: true,
  canEinvoice: true,
);

const _cashier = AuthUser(
  id: 'user-cashier',
  name: 'Cashier',
  role: 'cashier',
  storeIds: ['store-1'],
  canLedger: false,
  canEinvoice: false,
);

void main() {
  late AppDatabase database;
  late MockShiftRepository shiftRepository;
  late MockDayReportRepository dayReportRepository;
  late MockStockOnHandRepository stockOnHandRepository;
  late MockProductRepository productRepository;
  late MockProductService productService;
  late MockCustomerRepository customerRepository;
  late MockDebtPaymentService debtPaymentService;
  late MockCashVoucherService cashVoucherService;
  late MockPullCatalog pullCatalog;
  late MockCheckoutService checkoutService;
  late MockOutboxWorker outboxWorker;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    shiftRepository = MockShiftRepository();
    dayReportRepository = MockDayReportRepository();
    stockOnHandRepository = MockStockOnHandRepository();
    productRepository = MockProductRepository();
    productService = MockProductService();
    customerRepository = MockCustomerRepository();
    debtPaymentService = MockDebtPaymentService();
    cashVoucherService = MockCashVoucherService();
    pullCatalog = MockPullCatalog();
    checkoutService = MockCheckoutService();
    outboxWorker = MockOutboxWorker();

    when(() => shiftRepository.fetchStores()).thenAnswer(
      (_) async => const [
        StoreOption(id: 'store-1', code: 'CH1', name: 'Cửa hàng 1'),
      ],
    );
    when(
      () => shiftRepository.openShift(
        storeId: any(named: 'storeId'),
        openingCash: any(named: 'openingCash'),
        userId: any(named: 'userId'),
      ),
    ).thenThrow(const ShiftAlreadyOpenException());
  });

  tearDown(() => database.close());

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    // Drift stream cancel schedules a zero-duration timer; flush it.
    await tester.pump(const Duration(milliseconds: 1));
  }

  Future<void> pumpAndTriggerAlreadyOpen(
    WidgetTester tester, {
    required AuthUser user,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: OpenShiftPage(
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
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '500000');
    await tester.tap(find.widgetWithText(FilledButton, 'Mở ca'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'owner gets a "Xem nhanh" escape hatch when the shift is already open '
    'elsewhere, and it leads to the quick-view hub',
    (tester) async {
      await pumpAndTriggerAlreadyOpen(tester, user: _owner);

      expect(find.text('Đã có ca đang mở tại cửa hàng này'), findsOneWidget);
      expect(
        find.widgetWithText(OutlinedButton, 'Xem nhanh (không mở ca)'),
        findsOneWidget,
      );

      await tester.tap(
        find.widgetWithText(OutlinedButton, 'Xem nhanh (không mở ca)'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Xem nhanh'), findsOneWidget);
      await unmount(tester);
    },
  );

  testWidgets(
    'cashier does NOT get a "Xem nhanh" escape hatch on the same error '
    '(vẫn luôn phải mở ca)',
    (tester) async {
      await pumpAndTriggerAlreadyOpen(tester, user: _cashier);

      expect(find.text('Đã có ca đang mở tại cửa hàng này'), findsOneWidget);
      expect(find.text('Xem nhanh (không mở ca)'), findsNothing);
      await unmount(tester);
    },
  );
}
