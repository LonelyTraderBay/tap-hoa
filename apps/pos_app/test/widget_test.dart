import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pos_app/features/auth/auth_repository.dart';
import 'package:pos_app/main.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  testWidgets('shows login form', (tester) async {
    await tester.pumpWidget(PosApp(authRepository: MockAuthRepository()));

    expect(find.text('Tap Hoa POS'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Số điện thoại'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Mật khẩu'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Đăng nhập'), findsOneWidget);
  });

  testWidgets('submits credentials and greets user', (tester) async {
    final repository = MockAuthRepository();
    when(() => repository.login('0900000001', '123456')).thenAnswer(
      (_) async => const AuthUser(
        id: 'user-1',
        name: 'Owner',
        role: 'owner',
        storeIds: ['store-1'],
      ),
    );
    await tester.pumpWidget(PosApp(authRepository: repository));

    await tester.enterText(find.byType(TextField).at(0), '0900000001');
    await tester.enterText(find.byType(TextField).at(1), '123456');
    await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
    await tester.pump();

    expect(find.text('Xin chào Owner'), findsOneWidget);
  });
}
