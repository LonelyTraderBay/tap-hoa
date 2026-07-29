import { comboUnitCostVnd } from './combo-unit-cost';

describe('comboUnitCostVnd', () => {
  it('H4: sums raw component costs before rounding once, not per component', () => {
    // avgCostVnd=1667, qtyBase=0.5 each -> raw = 833.5 + 833.5 = 1667.0 exactly.
    // Correct per spec: round(1667.0) = 1667.
    // The old buggy code rounded each component first: round(833.5) + round(833.5)
    // = 834 + 834 = 1668 — a small but systematic overcharge on combo COGS.
    expect(
      comboUnitCostVnd([
        { avgCostVnd: 1667, qtyBase: 0.5 },
        { avgCostVnd: 1667, qtyBase: 0.5 },
      ]),
    ).toBe(1667);
  });

  it('H4: also catches the bias with 3 components landing on .5 boundaries', () => {
    // raw = 833.5 + 833.5 + 416.5 = 2083.5 -> round-half-up once = 2084.
    // Per-component rounding would give 834 + 834 + 417 = 2085 (wrong, off by 1).
    expect(
      comboUnitCostVnd([
        { avgCostVnd: 1667, qtyBase: 0.5 },
        { avgCostVnd: 1667, qtyBase: 0.5 },
        { avgCostVnd: 1666, qtyBase: 0.25 },
      ]),
    ).toBe(2084);
  });

  it('matches the plain sum when no component lands on a rounding boundary', () => {
    // 2*1000 + 1*500 = 2500
    expect(
      comboUnitCostVnd([
        { avgCostVnd: 1000, qtyBase: 2 },
        { avgCostVnd: 500, qtyBase: 1 },
      ]),
    ).toBe(2500);
  });

  it('handles a single component with a fractional qtyBase', () => {
    // 3000 * 0.25 = 750
    expect(comboUnitCostVnd([{ avgCostVnd: 3000, qtyBase: 0.25 }])).toBe(750);
  });

  it('returns 0 for an empty component list', () => {
    expect(comboUnitCostVnd([])).toBe(0);
  });
});
