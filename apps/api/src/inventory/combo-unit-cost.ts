/**
 * Combo unit cost (VND integer).
 *
 * Spec: docs/superpowers/specs/2026-07-24-phase2-cogs-wac-design.md
 *   unitCostVnd = Σ (componentAvg * qtyBase), rounded ONCE at the end.
 *
 * Rounding each component before summing (instead of summing raw values first)
 * introduces a small systematic bias. Example: 2 components, avgCostVnd=1667,
 * qtyBase=0.5 each —
 *   correct (sum first):  round(1667*0.5 + 1667*0.5) = round(1667.0) = 1667
 *   wrong (round first):  round(1667*0.5) + round(1667*0.5) = 834 + 834 = 1668
 */
export function comboUnitCostVnd(
  components: { avgCostVnd: number; qtyBase: number }[],
): number {
  let raw = 0;
  for (const c of components) {
    raw += c.avgCostVnd * c.qtyBase;
  }
  return Math.round(raw);
}
