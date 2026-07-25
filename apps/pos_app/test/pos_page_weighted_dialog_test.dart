import 'package:decimal/decimal.dart';
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
import 'package:pos_app/features/pos/pos_page.dart';
import 'package:pos_app/features/products/product_repository.dart';
import 'package:pos_app/features/products/product_service.dart';
import 'package:pos_app/features/reports/day_report_repository.dart';
import 'package:pos_app/features/reports/stock_on_hand_repository.dart';
import 'package:pos_app/features/shifts/shift_repository.dart';

class MockProductRepository extends Mock implements ProductRepository {}

class MockProductService extends Mock implements ProductService {}

class MockPullCatalog extends Mock implements PullCatalog {}

class MockCheckoutService extends Mock implements CheckoutService {}

class MockOutboxWorker extends Mock implements OutboxWorker {}

class MockDayReportRepository extends Mock implements DayReportRepository {}

class MockStockOnHandRepository extends Mock implements StockOnHandRepository {}

class MockCustomerRepository extends Mock implements CustomerRepository {}

class MockDebtPaymentService extends Mock implements DebtPaymentService {}

class MockShiftRepository extends Mock implements ShiftRepository {}

class MockCashVoucherService extends Mock implements CashVoucherService {}

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  Future<void> pumpPosPage(
    WidgetTester tester, {
    required List<ProductWithStock> products,
  }) async {
    await tester.binding.setSurfaceSize(const Size(1600, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final productRepository = MockProductRepository();
    when(
      () => productRepository.watchGroups(),
    ).thenAnswer((_) => Stream.value(const <ProductGroupRow>[]));
    when(
      () => productRepository.watchByStore('store-1', groupId: null),
    ).thenAnswer((_) => Stream.value(products));

    await tester.pumpWidget(
      MaterialApp(
        home: PosPage(
          productRepository: productRepository,
          productService: MockProductService(),
          checkoutService: MockCheckoutService(),
          customerRepository: MockCustomerRepository(),
          debtPaymentService: MockDebtPaymentService(),
          pullCatalog: MockPullCatalog(),
          outboxWorker: MockOutboxWorker(),
          dayReportRepository: MockDayReportRepository(),
          stockOnHandRepository: MockStockOnHandRepository(),
          shiftRepository: MockShiftRepository(),
          cashVoucherService: MockCashVoucherService(),
          database: database,
          user: const AuthUser(
            id: 'user-1',
            name: 'Owner',
            role: 'owner',
            storeIds: ['store-1'],
          ),
          storeId: 'store-1',
          storeName: 'Cửa hàng 1',
          role: 'owner',
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  }

  testWidgets('weighted product asks for kg before adding', (tester) async {
    await pumpPosPage(
      tester,
      products: [
        _product(
          id: 'banana',
          name: 'Chuối cân',
          unit: 'kg',
          isWeighted: true,
          basePriceVnd: 15500,
        ),
      ],
    );

    await tester.tap(find.text('Chuối cân'));
    await tester.pumpAndSettle();

    expect(find.text('Nhập kg: Chuối cân'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Số kg'), '0');
    await tester.tap(find.widgetWithText(FilledButton, 'Thêm'));
    await tester.pump();

    expect(find.text('Số lượng phải lớn hơn 0'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Số kg'), '0.333');
    await tester.tap(find.widgetWithText(FilledButton, 'Thêm'));
    await tester.pumpAndSettle();

    expect(find.textContaining('0.333 kg × 15500 VND'), findsOneWidget);
    expect(find.text('5162 VND'), findsOneWidget);

    await unmount(tester);
  });

  testWidgets('non-weighted product still adds immediately', (tester) async {
    await pumpPosPage(
      tester,
      products: [
        _product(
          id: 'water',
          name: 'Nước suối',
          unit: 'chai',
          isWeighted: false,
          basePriceVnd: 5000,
        ),
      ],
    );

    await tester.tap(find.text('Nước suối'));
    await tester.pumpAndSettle();

    expect(find.text('Nhập kg: Nước suối'), findsNothing);
    expect(find.textContaining('1 chai × 5000 VND'), findsOneWidget);
    expect(find.text('5000 VND'), findsOneWidget);

    await unmount(tester);
  });

  testWidgets('exact barcode add asks for weighted kg', (tester) async {
    await pumpPosPage(
      tester,
      products: [
        _product(
          id: 'sugar',
          name: 'Đường cân',
          barcode: '893SUGAR',
          unit: 'kg',
          isWeighted: true,
          basePriceVnd: 25000,
        ),
      ],
    );

    await tester.enterText(
      find.widgetWithText(TextField, 'Tìm tên, mã SKU hoặc barcode'),
      '893sugar',
    );
    await tester.pumpAndSettle();

    expect(find.text('Nhập kg: Đường cân'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Số kg'), '0,5');
    await tester.tap(find.widgetWithText(FilledButton, 'Thêm'));
    await tester.pumpAndSettle();

    expect(find.textContaining('0.500 kg × 25000 VND'), findsOneWidget);
    expect(find.text('12500 VND'), findsOneWidget);

    await unmount(tester);
  });
}

ProductWithStock _product({
  required String id,
  required String name,
  String? barcode,
  required String unit,
  required bool isWeighted,
  required int basePriceVnd,
}) {
  return ProductWithStock(
    id: id,
    name: name,
    sku: 'SKU-$id',
    barcode: barcode,
    unit: unit,
    isWeighted: isWeighted,
    basePriceVnd: basePriceVnd,
    qty: Decimal.fromInt(10).toString(),
  );
}
