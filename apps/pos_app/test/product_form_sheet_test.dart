import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pos_app/data/local/database.dart';
import 'package:pos_app/features/products/product_form_sheet.dart';
import 'package:pos_app/features/products/product_repository.dart';
import 'package:pos_app/features/products/product_service.dart';

// Regression cho G4: ô "Tồn tối thiểu" từng chỉ hiện lúc tạo mới sản phẩm
// (widget.isCreate), khiến không thể sửa minQty của sản phẩm đã tồn tại từ
// UI. Các test dưới đây pump ProductFormSheet.show(...) y hệt cách
// product_list_page.dart gọi trong thực tế, để bug tái diễn (nếu có) sẽ lộ
// ra qua đúng luồng người dùng thật, không chỉ qua gọi thẳng ProductService.
void main() {
  late AppDatabase db;
  late ProductRepository repository;
  late ProductService service;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = ProductRepository(db);
    service = ProductService(db);
  });

  tearDown(() => db.close());

  Future<ProductWithStock> seedExisting({required String minQty}) async {
    final id = await service.create(
      storeId: 's1',
      sku: 'SKU-1',
      name: 'Mì gói',
      unit: 'gói',
      isWeighted: false,
      basePriceVnd: 5000,
      initialQty: '20',
      minQty: minQty,
    );
    return ProductWithStock(
      id: id,
      name: 'Mì gói',
      sku: 'SKU-1',
      unit: 'gói',
      isWeighted: false,
      basePriceVnd: 5000,
      qty: '20',
    );
  }

  Future<void> openForm(
    WidgetTester tester, {
    required ProductWithStock existing,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => ProductFormSheet.show(
              context,
              productService: service,
              repository: repository,
              storeId: 's1',
              existing: existing,
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'sửa sản phẩm đã tồn tại vẫn hiện ô "Tồn tối thiểu", nạp sẵn giá trị hiện tại',
    (tester) async {
      final existing = await seedExisting(minQty: '4');

      await openForm(tester, existing: existing);

      expect(find.text('Sửa hàng hóa'), findsOneWidget);
      // "Tồn ban đầu" chỉ dành cho lúc tạo mới, không hiện khi sửa.
      expect(find.text('Tồn ban đầu'), findsNothing);

      final minQtyField = tester.widget<TextField>(
        find.widgetWithText(TextField, 'Tồn tối thiểu'),
      );
      expect(minQtyField.controller!.text, '4');
    },
  );

  testWidgets(
    'lưu minQty mới trên sản phẩm đã có tồn kho thì đọc lại đúng giá trị mới '
    '(round-trip qua UI thật)',
    (tester) async {
      final existing = await seedExisting(minQty: '4');

      await openForm(tester, existing: existing);

      await tester.enterText(
        find.widgetWithText(TextField, 'Tồn tối thiểu'),
        '9',
      );

      // Sheet dài hơn viewport test mặc định — cuộn nút "Lưu" vào tầm nhìn
      // trước khi tap, nếu không tester.tap() sẽ nhắm trúng toạ độ off-screen.
      final saveButton = find.widgetWithText(FilledButton, 'Lưu');
      await tester.ensureVisible(saveButton);
      await tester.pumpAndSettle();
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Sheet đóng lại sau khi lưu thành công (không còn báo lỗi/kẹt form).
      expect(find.text('Sửa hàng hóa'), findsNothing);

      final after = await repository.getForEdit(existing.id, 's1');
      expect(after, isNotNull);
      expect(after!.minQty, '9');
      // Tồn thực tế (qty) không bị đụng — form sửa không có ô "Tồn ban đầu".
      expect(after.qty, '20');
    },
  );
}
