import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pos_app/data/local/database.dart';
import 'package:pos_app/features/pos/sale_return_refund.dart';
import 'package:pos_app/features/pos/sale_return_service.dart';
import 'package:pos_app/features/products/product_repository.dart';
import 'package:pos_app/features/products/product_service.dart';
import 'package:pos_app/features/shifts/shift_repository.dart';

class MockDio extends Mock implements Dio {}

void main() {
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

  test('ProductGroupService upsert writes outbox; inactive hidden from chips stream',
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
  });
}
