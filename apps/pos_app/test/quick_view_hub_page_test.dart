import 'dart:async';

import 'package:dio/dio.dart';
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
import 'package:pos_app/features/quick_view/quick_view_hub_page.dart';
import 'package:pos_app/features/reports/day_report_repository.dart';
import 'package:pos_app/features/reports/stock_on_hand_repository.dart';
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

class MockDio extends Mock implements Dio {}

const _owner = AuthUser(
  id: 'user-owner',
  name: 'Owner',
  role: 'owner',
  storeIds: ['store-1', 'store-2'],
  canLedger: true,
  canEinvoice: true,
);

const _manager = AuthUser(
  id: 'user-mgr',
  name: 'Manager',
  role: 'store_manager',
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
  late MockDio dio;

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
    dio = MockDio();

    when(() => dayReportRepository.dio).thenReturn(dio);
    when(
      () => customerRepository.watchWithDebt(),
    ).thenAnswer((_) => Stream.value(const <CustomerRecord>[]));
  });

  tearDown(() => database.close());

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    // Drift stream cancel schedules a zero-duration timer; flush it.
    await tester.pump(const Duration(milliseconds: 1));
  }

  Future<void> pumpHub(WidgetTester tester, {required AuthUser user}) async {
    await tester.pumpWidget(
      MaterialApp(
        home: QuickViewHubPage(
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
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('quickViewAllowedForRole', () {
    test('owner and store_manager are allowed, cashier is not', () {
      expect(quickViewAllowedForRole('owner'), isTrue);
      expect(quickViewAllowedForRole('store_manager'), isTrue);
      expect(quickViewAllowedForRole('cashier'), isFalse);
    });
  });

  group('QuickViewHubPage', () {
    testWidgets('owner sees the aggregate note and all 3 entry tiles', (
      tester,
    ) async {
      when(() => shiftRepository.fetchStores()).thenAnswer(
        (_) async => const [
          StoreOption(id: 'store-1', code: 'CH1', name: 'Cửa hàng 1'),
          StoreOption(id: 'store-2', code: 'CH2', name: 'Cửa hàng 2'),
        ],
      );

      await pumpHub(tester, user: _owner);

      expect(find.text('Xem nhanh'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Mở ca bán hàng'), findsOneWidget);
      expect(find.text('Báo cáo doanh thu nhanh'), findsOneWidget);
      expect(find.text('Kiểm kho / quét mã xem tồn'), findsOneWidget);
      expect(find.text('Công nợ khách hàng'), findsOneWidget);
      // Owner-only note: report/công nợ đều xem tổng hợp mọi điểm.
      expect(
        find.textContaining('xem tổng hợp tất cả'),
        findsOneWidget,
      );
      await unmount(tester);
    });

    testWidgets(
      'store_manager does not see the owner aggregate note',
      (tester) async {
        when(() => shiftRepository.fetchStores()).thenAnswer(
          (_) async => const [
            StoreOption(id: 'store-1', code: 'CH1', name: 'Cửa hàng 1'),
          ],
        );

        await pumpHub(tester, user: _manager);

        expect(find.text('Xem nhanh'), findsOneWidget);
        expect(find.textContaining('xem tổng hợp tất cả'), findsNothing);
        expect(find.text('Báo cáo doanh thu nhanh'), findsOneWidget);
        await unmount(tester);
      },
    );

    testWidgets('"Mở ca bán hàng" is reachable even while stores are loading', (
      tester,
    ) async {
      final completer = Completer<List<StoreOption>>();
      when(
        () => shiftRepository.fetchStores(),
      ).thenAnswer((_) => completer.future);

      await tester.pumpWidget(
        MaterialApp(
          home: QuickViewHubPage(
            user: _owner,
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
          ),
        ),
      );
      // Stores are still loading (spinner in the lower half) — the escape
      // hatch to "Mở ca bán hàng" must already be visible and tappable.
      expect(find.widgetWithText(FilledButton, 'Mở ca bán hàng'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      completer.complete(const [
        StoreOption(id: 'store-1', code: 'CH1', name: 'Cửa hàng 1'),
      ]);
      await tester.pumpAndSettle();
      await unmount(tester);
    });

    testWidgets('tapping "Mở ca bán hàng" reaches OpenShiftPage', (
      tester,
    ) async {
      when(() => shiftRepository.fetchStores()).thenAnswer(
        (_) async => const [
          StoreOption(id: 'store-1', code: 'CH1', name: 'Cửa hàng 1'),
        ],
      );

      await pumpHub(tester, user: _owner);
      await tester.tap(find.widgetWithText(FilledButton, 'Mở ca bán hàng'));
      await tester.pumpAndSettle();

      expect(find.text('Mở ca'), findsWidgets);
      expect(find.text('Xin chào Owner'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets(
      'tapping "Kiểm kho / quét mã xem tồn" reaches InventoryHubPage',
      (tester) async {
        when(() => shiftRepository.fetchStores()).thenAnswer(
          (_) async => const [
            StoreOption(id: 'store-1', code: 'CH1', name: 'Cửa hàng 1'),
          ],
        );

        await pumpHub(tester, user: _owner);
        await tester.tap(find.text('Kiểm kho / quét mã xem tồn'));
        await tester.pumpAndSettle();

        expect(find.text('Kho'), findsOneWidget);
        expect(find.text('Chứng từ'), findsOneWidget);
        await unmount(tester);
      },
    );

    testWidgets(
      'tapping "Công nợ khách hàng" reaches DebtCustomerListPage',
      (tester) async {
        when(() => shiftRepository.fetchStores()).thenAnswer(
          (_) async => const [
            StoreOption(id: 'store-1', code: 'CH1', name: 'Cửa hàng 1'),
          ],
        );

        await pumpHub(tester, user: _owner);
        await tester.tap(find.text('Công nợ khách hàng'));
        await tester.pumpAndSettle();

        expect(find.text('Khách nợ'), findsOneWidget);
        await unmount(tester);
      },
    );
  });
}
