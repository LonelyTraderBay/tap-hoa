class CreditLimitExceededException implements Exception {
  const CreditLimitExceededException({
    required this.balanceVnd,
    required this.creditLimitVnd,
    required this.debtAmount,
  });

  final int balanceVnd;
  final int creditLimitVnd;
  final int debtAmount;
}

bool exceedsCreditLimit({
  required int balanceVnd,
  required int debtAmount,
  int? creditLimitVnd,
}) {
  if (creditLimitVnd == null) return false;
  return balanceVnd + debtAmount > creditLimitVnd;
}
