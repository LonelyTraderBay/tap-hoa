import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pos_app/data/local/database.dart';
import 'package:pos_app/features/customers/customer_repository.dart';
import 'package:pos_app/features/pos/cart.dart';
import 'package:pos_app/features/pos/checkout_service.dart';
import 'package:pos_app/features/pos/payment_sheet.dart';
import 'package:pos_app/features/shifts/shift_repository.dart';

class MockDio extends Mock implements Dio {}

// Regression cho G5 (spec §6.2): "cho bán nếu cấu hình cho phép" đã có sẵn
// (allowNegativeStock=true không chặn giao dịch) nhưng thiếu đúng phần
// "Cảnh báo" — đơn đi qua hoàn toàn im lặng, thu ngân không biết tồn đã về
// âm. Các test dưới đây pump PaymentSheet.show(...) y hệt cách
// pos_page.dart._openPayment() mở trong thực tế, tap "Hoàn tất" thật, để
// cảnh báo (hoặc việc thiếu cảnh báo) lộ ra qua đúng luồng UI thật, không
// chỉ qua gọi thẳng CheckoutService.
void main() {
  late AppDatabase db;
  late ShiftRepository shiftRepository;
  late CheckoutService checkoutService;
  late CustomerRepository customerRepository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    shiftRepository = ShiftRepository(dio: MockDio(), db: db);
    checkoutService = CheckoutService(
      db: db,
      shiftRepository: shiftRepository,
    );
    customerRepository = CustomerRepository(db: db, dio: MockDio());
  });

  tearDown(() => db.close());

  Future<void> seedProductStock({
    String qty = '10',
    required bool allowNegativeStock,
  }) async {
    await db.into(db.products).insert(
      ProductsCompanion.insert(
        id: 'p1',
        sku: 'STING-330',
        name: 'Sting',
        unit: 'chai',
        basePriceVnd: 10000,
        updatedAt: DateTime(2026),
      ),
    );
    await db.into(db.productStocks).insert(
      ProductStocksCompanion.insert(
        productId: 'p1',
        storeId: 'store-1',
        qty: qty,
        minQty: '0',
        updatedAt: DateTime(2026),
      ),
    );
    await db.into(db.storesLocal).insert(
      StoresLocalCompanion.insert(
        id: 'store-1',
        code: 'CH1',
        name: 'Cua hang 1',
        allowNegativeStock: Value(allowNegativeStock),
        updatedAt: DateTime(2026),
      ),
    );
  }

  Future<void> seedSession() async {
    await db.setMetaValue('currentStoreId', 'store-1');
    await db.setMetaValue(
      'currentUser',
      jsonEncode({
        'id': 'user-1',
        'name': 'Cashier',
        'role': 'cashier',
        'storeIds': ['store-1'],
      }),
    );
    await shiftRepository.openShift(
      storeId: 'store-1',
      openingCash: 500000,
      userId: 'user-1',
    );
  }

  Cart cartSellingQty2() {
    final cart = Cart();
    cart.add(
      CartLine(
        productId: 'p1',
        name: 'Sting',
        unitPrice: 10000,
        qty: Decimal.parse('2'),
      ),
    );
    return cart;
  }

  // pos_page.dart mở PaymentSheet.show(context, ...) từ 1 context nằm trong
  // Scaffold của chính nó — bọc Scaffold ở đây để giống hệt cây widget thật,
  // vì ScaffoldMessenger.showSnackBar() cần ít nhất 1 Scaffold con để hiện
  // SnackBar (nếu không sẽ throw assertion, không liên quan gì tới đúng/sai
  // của cảnh báo âm tồn).
  Future<void> openPaymentSheet(WidgetTester tester, Cart cart) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => PaymentSheet.show(
                context,
                cart: cart,
                checkoutService: checkoutService,
                customerRepository: customerRepository,
                storeName: 'Cua hang 1',
                onCompleted: () {},
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  // Trong lúc _complete() await promptAndPrintReceipt() (chờ người dùng bấm
  // nút trong dialog "Hóa đơn"), nút "Hoàn tất" vẫn hiện
  // CircularProgressIndicator — 1 animation VÔ HẠN — nên KHÔNG được dùng
  // pumpAndSettle() ở bước này (sẽ treo tới khi hết timeout: "pumpAndSettle
  // timed out"). Dùng pump() có giới hạn để chỉ tiến đủ tới khi dialog hiện
  // ra, rồi mới tương tác.
  Future<void> tapCompleteAndReachReceiptDialog(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(FilledButton, 'Hoàn tất'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Hóa đơn'), findsOneWidget);
  }

  // Sau khi checkout hoàn tất, promptAndPrintReceipt luôn hỏi in/gửi hóa
  // đơn trước — bỏ qua để luồng tiếp tục tới bước cảnh báo âm tồn. Từ đây
  // trở đi nút "Hoàn tất" (và spinner của nó) đã/sắp bị pop khỏi cây widget
  // nên pumpAndSettle() an toàn để dùng lại.
  Future<void> dismissReceiptDialog(WidgetTester tester) async {
    await tester.tap(find.text('Bỏ qua'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'ban khien ton ve am khi allowNegativeStock=true hien canh bao dung san pham/so luong',
    (tester) async {
      await seedProductStock(qty: '1', allowNegativeStock: true);
      await seedSession();

      await openPaymentSheet(tester, cartSellingQty2());

      await tapCompleteAndReachReceiptDialog(tester);
      await dismissReceiptDialog(tester);

      // Giao dịch không bị chặn: sheet đã đóng lại (đơn hoàn tất bình
      // thường) — cảnh báo chỉ là thông báo thêm, không phải confirm dialog.
      expect(find.text('Thanh toán'), findsNothing);

      expect(find.textContaining('Sting: còn -1'), findsOneWidget);
      expect(
        find.textContaining('Cảnh báo: tồn kho đã về âm'),
        findsOneWidget,
      );

      // Xả hết Timer tự ẩn của SnackBar (duration 8s) trước khi test kết
      // thúc, tránh rò Timer sang test sau.
      await tester.pump(const Duration(seconds: 9));
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'ban trong pham vi ton du khong hien canh bao am ton',
    (tester) async {
      await seedProductStock(qty: '10', allowNegativeStock: true);
      await seedSession();

      await openPaymentSheet(tester, cartSellingQty2());

      await tapCompleteAndReachReceiptDialog(tester);
      await dismissReceiptDialog(tester);

      expect(find.text('Thanh toán'), findsNothing);
      expect(
        find.textContaining('Cảnh báo: tồn kho đã về âm'),
        findsNothing,
      );
    },
  );
}
