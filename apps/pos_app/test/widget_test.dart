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
import 'package:pos_app/features/shifts/shift_repository.dart';
import 'package:pos_app/features/sync_status/sync_status_banner.dart';
import 'package:pos_app/main.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockShiftRepository extends Mock implements ShiftRepository {}

class MockProductRepository extends Mock implements ProductRepository {}

class MockProductService extends Mock implements ProductService {}

class MockPullCatalog extends Mock implements PullCatalog {}

class MockCheckoutService extends Mock implements CheckoutService {}

class MockOutboxWorker extends Mock implements OutboxWorker {}

class MockDayReportRepository extends Mock implements DayReportRepository {}

class MockStockOnHandRepository extends Mock implements StockOnHandRepository {}

class MockCustomerRepository extends Mock implements CustomerRepository {}

class MockDebtPaymentService extends Mock implements DebtPaymentService {}

class MockCashVoucherService extends Mock implements CashVoucherService {}

PosApp _buildApp({
  required AppDatabase database,
  AuthRepository? authRepository,
  ShiftRepository? shiftRepository,
}) {
  return PosApp(
    database: database,
    authRepository: authRepository ?? MockAuthRepository(),
    shiftRepository: shiftRepository ?? MockShiftRepository(),
    productRepository: MockProductRepository(),
    productService: MockProductService(),
    pullCatalog: MockPullCatalog(),
    checkoutService: MockCheckoutService(),
    customerRepository: MockCustomerRepository(),
    debtPaymentService: MockDebtPaymentService(),
    cashVoucherService: MockCashVoucherService(),
    outboxWorker: MockOutboxWorker(),
    dayReportRepository: MockDayReportRepository(),
    stockOnHandRepository: MockStockOnHandRepository(),
  );
}
void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    // Drift stream cancel schedules a zero-duration timer; flush it.
    await tester.pump(const Duration(milliseconds: 1));
  }

  testWidgets('wraps sync banner in top safe area', (tester) async {
    await tester.pumpWidget(_buildApp(database: database));

    expect(
      find.descendant(
        of: find.byType(SafeArea),
        matching: find.byType(SyncStatusBanner),
      ),
      findsOneWidget,
    );
    final safeArea = tester.widget<SafeArea>(find.byType(SafeArea));
    expect(safeArea.bottom, isFalse);
    await unmount(tester);
  });

  testWidgets('shows login form', (tester) async {
    await tester.pumpWidget(_buildApp(database: database));

    expect(find.text('Tap Hoa POS'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Số điện thoại'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Mật khẩu'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Đăng nhập'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('navigates to open shift after login', (tester) async {
    final repository = MockAuthRepository();
    final shiftRepository = MockShiftRepository();
    when(() => repository.login('0900000001', '123456')).thenAnswer(
      (_) async => const AuthUser(
        id: 'user-1',
        name: 'Owner',
        role: 'owner',
        storeIds: ['store-1'],
      ),
    );
    when(() => shiftRepository.fetchStores()).thenAnswer(
      (_) async => const [
        StoreOption(id: 'store-1', code: 'CH1', name: 'Cửa hàng 1'),
      ],
    );
    await tester.pumpWidget(
      _buildApp(
        database: database,
        authRepository: repository,
        shiftRepository: shiftRepository,
      ),
    );

    await tester.enterText(find.byType(TextField).at(0), '0900000001');
    await tester.enterText(find.byType(TextField).at(1), '123456');
    await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
    await tester.pumpAndSettle();

    expect(find.text('Mở ca'), findsWidgets);
    expect(find.text('Xin chào Owner'), findsOneWidget);
    await unmount(tester);
  });
}
