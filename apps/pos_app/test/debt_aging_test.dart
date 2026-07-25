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
}
