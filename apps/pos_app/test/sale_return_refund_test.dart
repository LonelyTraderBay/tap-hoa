import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pos_app/data/local/database.dart';
import 'package:pos_app/features/pos/sale_return_refund.dart';
import 'package:pos_app/features/pos/sale_return_sheet.dart';
import 'package:pos_app/features/pos/sale_return_service.dart';
import 'package:pos_app/features/products/product_repository.dart';
import 'package:pos_app/features/products/product_service.dart';
import 'package:pos_app/features/shifts/shift_repository.dart';

class MockDio extends Mock implements Dio {}

class MockSaleReturnService extends Mock implements SaleReturnService {}

void main() {
  setUpAll(() {
    registerFallbackValue([
      SaleReturnLineInput(
        productId: 'fallback',
        qty: Decimal.zero,
        unitPrice: 0,
        lineRefundVnd: 0,
      ),
    ]);
  });

  group('validateSaleReturnRefundSplit', () {
    test('accepts matching split with debt when customer present', () {
      expect(
        validateSaleReturnRefundSplit(
          lineRefundTotal: 100,
          cashRefundVnd: 40,
          transferRefundVnd: 30,
          debtCreditVnd: 30,
          originalSaleHasCustomer: true,
        ),
        isNull,
      );
    });

    test('rejects mismatch and debt without customer', () {
      expect(
        validateSaleReturnRefundSplit(
          lineRefundTotal: 100,
          cashRefundVnd: 50,
          transferRefundVnd: 40,
          debtCreditVnd: 0,
          originalSaleHasCustomer: false,
        ),
        'refund_mismatch',
      );
      expect(
        validateSaleReturnRefundSplit(
          lineRefundTotal: 100,
          cashRefundVnd: 70,
          transferRefundVnd: 0,
          debtCreditVnd: 30,
          originalSaleHasCustomer: false,
        ),
        'debt_credit_requires_customer',
      );
    });
  });

  test(
    'discountedReturnLineRefundVnd uses sold net line total proportionally',
    () {
      expect(
        discountedReturnLineRefundVnd(
          soldQty: Decimal.parse('2'),
          returnQty: Decimal.parse('2'),
          soldLineTotalVnd: 17000,
        ),
        17000,
      );
      expect(
        discountedReturnLineRefundVnd(
          soldQty: Decimal.parse('2'),
          returnQty: Decimal.parse('1'),
          soldLineTotalVnd: 17000,
        ),
        8500,
      );
    },
  );

  testWidgets('sale return sheet defaults and submits discounted net refund', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await db
        .into(db.salesLocal)
        .insert(
          SalesLocalCompanion.insert(
            id: 'sale-discounted',
            storeId: 'store-1',
            shiftId: 'shift-1',
            paymentMethod: 'cash',
            totalVnd: 17000,
            cashAmount: 17000,
            transferAmount: 0,
            debtAmount: 0,
            clientCreatedAt: DateTime(2026),
          ),
        );
    await db
        .into(db.products)
        .insert(
          ProductsCompanion.insert(
            id: 'p1',
            sku: 'SKU-1',
            name: 'Discounted product',
            unit: 'cái',
            basePriceVnd: 10000,
            updatedAt: DateTime(2026),
          ),
        );
    await db
        .into(db.saleLinesLocal)
        .insert(
          SaleLinesLocalCompanion.insert(
            id: 'line-1',
            saleId: 'sale-discounted',
            productId: 'p1',
            qty: '2',
            unitPrice: 10000,
            discountVnd: const Value(3000),
            lineTotal: 17000,
          ),
        );

    final service = MockSaleReturnService();
    when(
      () => service.createReturn(
        originalSaleId: any(named: 'originalSaleId'),
        lines: any(named: 'lines'),
        cashRefundVnd: any(named: 'cashRefundVnd'),
        transferRefundVnd: any(named: 'transferRefundVnd'),
        debtCreditVnd: any(named: 'debtCreditVnd'),
        role: any(named: 'role'),
      ),
    ).thenAnswer((_) async => 'return-1');

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showSaleReturnSheet(
              context,
              db: db,
              service: service,
              storeId: 'store-1',
              role: 'store_manager',
              date: DateTime(2026),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'sale-discounted');
    await tester.tap(find.text('Tải đơn'));
    await tester.pumpAndSettle();

    expect(find.text('Hoàn: 17000 VND'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(1), '1');
    await tester.pumpAndSettle();

    expect(find.text('Hoàn: 8500 VND'), findsOneWidget);

    await tester.tap(find.text('Xác nhận đổi trả'));
    await tester.pumpAndSettle();

    final captured =
        verify(
              () => service.createReturn(
                originalSaleId: 'sale-discounted',
                lines: captureAny(named: 'lines'),
                cashRefundVnd: 8500,
                transferRefundVnd: 0,
                debtCreditVnd: 0,
                role: 'store_manager',
              ),
            ).captured.single
            as List<SaleReturnLineInput>;
    expect(captured.single.productId, 'p1');
    expect(captured.single.qty, Decimal.one);
    expect(captured.single.lineRefundVnd, 8500);
  });

  test('canReturnRole allows owner/manager only', () {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final service = SaleReturnService(
      db: db,
      shiftRepository: ShiftRepository(dio: MockDio(), db: db),
    );
    expect(service.canReturnRole('owner'), isTrue);
    expect(service.canReturnRole('store_manager'), isTrue);
    expect(service.canReturnRole('cashier'), isFalse);
  });

  test(
    'ProductGroupService upsert writes outbox; inactive hidden from chips stream',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final service = ProductGroupService(db);
      final repo = ProductRepository(db);
      final id = await service.upsert(name: 'Nước ngọt', sortOrder: 1);
      final outbox = await db.pendingOutbox();
      expect(outbox.single.entityType, 'product_group_upsert');
      final payload =
          jsonDecode(outbox.single.payloadJson) as Map<String, dynamic>;
      expect(payload['name'], 'Nước ngọt');
      expect(payload['active'], true);

      await service.upsert(id: id, name: 'Nước ngọt', active: false);
      final activeOnly = await repo.watchGroups(activeOnly: true).first;
      final all = await repo.watchGroups(activeOnly: false).first;
      expect(activeOnly.where((g) => g.id == id), isEmpty);
      expect(all.singleWhere((g) => g.id == id).active, isFalse);
    },
  );
}
