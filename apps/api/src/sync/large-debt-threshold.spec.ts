import { crossesLargeDebtThreshold } from './large-debt-threshold';

describe('crossesLargeDebtThreshold', () => {
  it('is off when threshold is null', () => {
    expect(
      crossesLargeDebtThreshold({
        thresholdVnd: null,
        previousBalanceVnd: 0,
        nextBalanceVnd: 100000,
      }),
    ).toBe(false);
  });

  it('returns true only when the balance crosses upward', () => {
    expect(
      crossesLargeDebtThreshold({
        thresholdVnd: 50000,
        previousBalanceVnd: 20000,
        nextBalanceVnd: 50000,
      }),
    ).toBe(true);

    expect(
      crossesLargeDebtThreshold({
        thresholdVnd: 50000,
        previousBalanceVnd: 50000,
        nextBalanceVnd: 70000,
      }),
    ).toBe(false);
  });

  it('does not alert for debt payments that reduce balance', () => {
    expect(
      crossesLargeDebtThreshold({
        thresholdVnd: 50000,
        previousBalanceVnd: 70000,
        nextBalanceVnd: 40000,
      }),
    ).toBe(false);
  });
});
