export type LargeDebtThresholdInput = {
  thresholdVnd: number | null | undefined;
  previousBalanceVnd: number;
  nextBalanceVnd: number;
};

export function crossesLargeDebtThreshold(input: LargeDebtThresholdInput) {
  const threshold = input.thresholdVnd;
  if (threshold == null) {
    return false;
  }
  return (
    input.previousBalanceVnd < threshold && input.nextBalanceVnd >= threshold
  );
}
