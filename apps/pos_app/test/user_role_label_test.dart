import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/features/users/user_management_page.dart';

void main() {
  group('userRoleLabel', () {
    test('maps the three spec roles to Vietnamese labels', () {
      expect(userRoleLabel('owner'), 'Chủ');
      expect(userRoleLabel('store_manager'), 'Quản lý điểm');
      expect(userRoleLabel('cashier'), 'Thu ngân');
    });

    test('falls back to the raw value', () {
      expect(userRoleLabel('unknown'), 'unknown');
      expect(userRoleLabel(null), '—');
    });
  });

  group('userRoleAllowsAccountingFlags', () {
    test('cashier never gets ledger or e-invoice rights', () {
      expect(userRoleAllowsAccountingFlags('cashier'), isFalse);
      expect(userRoleAllowsAccountingFlags('store_manager'), isTrue);
      expect(userRoleAllowsAccountingFlags('owner'), isTrue);
    });
  });
}
