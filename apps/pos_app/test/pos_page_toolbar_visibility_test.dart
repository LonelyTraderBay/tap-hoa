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

  group('posShowUserManagementAction', () {
    test('owner only', () {
      expect(posShowUserManagementAction('owner'), isTrue);
      expect(posShowUserManagementAction('store_manager'), isFalse);
      expect(posShowUserManagementAction('cashier'), isFalse);
    });
  });

  group('posShowLedgerHomeAction', () {
    test('follows canLedger flag', () {
      expect(posShowLedgerHomeAction(canLedger: true), isTrue);
      expect(posShowLedgerHomeAction(canLedger: false), isFalse);
    });
  });

  group('posShowCashFundAction', () {
    test('follows canLedger flag', () {
      expect(posShowCashFundAction(canLedger: true), isTrue);
      expect(posShowCashFundAction(canLedger: false), isFalse);
    });
  });

  group('posShowBankReconAction', () {
    test('follows canLedger flag', () {
      expect(posShowBankReconAction(canLedger: true), isTrue);
      expect(posShowBankReconAction(canLedger: false), isFalse);
    });
  });

  group('posShowEInvoiceIssueAction', () {
    test('follows canEinvoice flag', () {
      expect(posShowEInvoiceIssueAction(canEinvoice: true), isTrue);
      expect(posShowEInvoiceIssueAction(canEinvoice: false), isFalse);
    });
  });
}
