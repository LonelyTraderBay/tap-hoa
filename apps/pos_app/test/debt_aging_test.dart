import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/features/customers/debt_aging.dart';

void main() {
  DateTime day(int n) => DateTime.utc(2026, 1, n, 10);

  test('overdue when oldest unpaid > X days', () {
    final result = computeDebtAging(
      [
        DebtLedgerRow(
          type: 'sale_debt',
          amountVnd: 100000,
          clientCreatedAt: day(1),
        ),
      ],
      30,
      asOf: day(32),
    );
    expect(result.overdue, isTrue);
    expect(result.daysOutstanding, 31);
  });

  test('FIFO payment clears oldest first', () {
    final result = computeDebtAging(
      [
        DebtLedgerRow(
          type: 'sale_debt',
          amountVnd: 50000,
          clientCreatedAt: day(1),
        ),
        DebtLedgerRow(
          type: 'sale_debt',
          amountVnd: 50000,
          clientCreatedAt: day(10),
        ),
        DebtLedgerRow(
          type: 'payment',
          amountVnd: 50000,
          clientCreatedAt: day(15),
        ),
      ],
      30,
      asOf: day(40),
    );
    expect(result.oldestUnpaidAt, day(10));
    expect(result.daysOutstanding, 30);
    expect(result.overdue, isFalse);
  });

  test('parses aggregate debt aging response', () {
    final report = DebtAgingReport.fromJson({
      'storeId': null,
      'scope': 'aggregate',
      'storeIds': ['store-1', 'store-2'],
      'debtOverdueDays': null,
      'customers': [
        {
          'customerId': 'customer-1',
          'storeId': 'store-1',
          'name': 'Khach 1',
          'phone': null,
          'balanceVnd': 100000,
          'debtOverdueDays': 30,
          'oldestUnpaidAt': '2026-01-01T00:00:00.000Z',
          'daysOutstanding': 31,
          'overdue': true,
        },
        {
          'customerId': 'customer-2',
          'storeId': 'store-2',
          'name': 'Khach 2',
          'phone': '090',
          'balanceVnd': 200000,
          'debtOverdueDays': 45,
          'oldestUnpaidAt': null,
          'daysOutstanding': 0,
          'overdue': false,
        },
      ],
    });

    expect(report.scope, 'aggregate');
    expect(report.storeId, isNull);
    expect(report.storeIds, ['store-1', 'store-2']);
    expect(report.customers, hasLength(2));
    expect(report.totalBalanceVnd, 300000);
    expect(report.overdueCount, 1);
    expect(report.customers.first.oldestUnpaidAt, isNotNull);
  });
}
