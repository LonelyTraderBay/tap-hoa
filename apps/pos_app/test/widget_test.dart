import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pos_app/data/sync/pull_catalog.dart';
import 'package:pos_app/features/auth/auth_repository.dart';
import 'package:pos_app/features/pos/checkout_service.dart';
import 'package:pos_app/features/products/product_repository.dart';
import 'package:pos_app/features/shifts/shift_repository.dart';
import 'package:pos_app/main.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockShiftRepository extends Mock implements ShiftRepository {}

class MockProductRepository extends Mock implements ProductRepository {}

class MockPullCatalog extends Mock implements PullCatalog {}

class MockCheckoutService extends Mock implements CheckoutService {}

void main() {
  testWidgets('shows login form', (tester) async {
    await tester.pumpWidget(
      PosApp(
        authRepository: MockAuthRepository(),
        shiftRepository: MockShiftRepository(),
        productRepository: MockProductRepository(),
        pullCatalog: MockPullCatalog(),
        checkoutService: MockCheckoutService(),
      ),
    );

    expect(find.text('Tap Hoa POS'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Số điện thoại'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Mật khẩu'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Đăng nhập'), findsOneWidget);
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
      PosApp(
        authRepository: repository,
        shiftRepository: shiftRepository,
        productRepository: MockProductRepository(),
        pullCatalog: MockPullCatalog(),
        checkoutService: MockCheckoutService(),
      ),
    );

    await tester.enterText(find.byType(TextField).at(0), '0900000001');
    await tester.enterText(find.byType(TextField).at(1), '123456');
    await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
    await tester.pumpAndSettle();

    expect(find.text('Mở ca'), findsWidgets);
    expect(find.text('Xin chào Owner'), findsOneWidget);
  });
}
