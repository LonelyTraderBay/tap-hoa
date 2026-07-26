import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/features/pos/pos_page.dart';

void main() {
  group('posShowStoreManagementAction', () {
    test('owner only', () {
      expect(posShowStoreManagementAction('owner'), isTrue);
      expect(posShowStoreManagementAction('store_manager'), isFalse);
      expect(posShowStoreManagementAction('cashier'), isFalse);
    });
  });

  group('posShowLedgerHomeAction', () {
    test('follows canLedger flag', () {
      expect(posShowLedgerHomeAction(canLedger: true), isTrue);
      expect(posShowLedgerHomeAction(canLedger: false), isFalse);
    });
  });

  group('posShowCashFundAction', () {
    test('owner or store_manager', () {
      expect(posShowCashFundAction('owner'), isTrue);
      expect(posShowCashFundAction('store_manager'), isTrue);
      expect(posShowCashFundAction('cashier'), isFalse);
    });
  });

  group('posShowEInvoiceIssueAction', () {
    test('follows canEinvoice flag', () {
      expect(posShowEInvoiceIssueAction(canEinvoice: true), isTrue);
      expect(posShowEInvoiceIssueAction(canEinvoice: false), isFalse);
    });
  });
}
