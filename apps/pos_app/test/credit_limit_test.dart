import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/features/customers/credit_limit.dart';

void main() {
  test('null limit never exceeds', () {
    expect(
      exceedsCreditLimit(balanceVnd: 100, debtAmount: 999999, creditLimitVnd: null),
      isFalse,
    );
  });

  test('equal to limit is allowed', () {
    expect(
      exceedsCreditLimit(balanceVnd: 10000, debtAmount: 5000, creditLimitVnd: 15000),
      isFalse,
    );
  });

  test('over limit is blocked', () {
    expect(
      exceedsCreditLimit(balanceVnd: 10000, debtAmount: 5001, creditLimitVnd: 15000),
      isTrue,
    );
  });
}
