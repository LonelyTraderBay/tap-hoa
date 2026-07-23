import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/main.dart';

void main() {
  testWidgets('shows Tap Hoa POS', (WidgetTester tester) async {
    await tester.pumpWidget(const PosApp());
    expect(find.text('Tap Hoa POS'), findsOneWidget);
  });
}
