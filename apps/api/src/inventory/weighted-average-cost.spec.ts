import { weightedAverageCost } from './weighted-average-cost';

describe('weightedAverageCost', () => {
  it('uses unit cost when old qty is zero', () => {
    expect(weightedAverageCost(0, 0, 10, 8000)).toBe(8000);
  });

  it('blends existing avg with receipt', () => {
    // (10*10000 + 10*8000) / 20 = 9000
    expect(weightedAverageCost(10, 10000, 10, 8000)).toBe(9000);
  });

  it('rounds to nearest VND', () => {
    // (1*1000 + 2*1001) / 3 = 1000.666… → 1001
    expect(weightedAverageCost(1, 1000, 2, 1001)).toBe(1001);
  });

  it('ignores non-positive receipt qty', () => {
    expect(weightedAverageCost(5, 7000, 0, 9000)).toBe(7000);
  });
});
