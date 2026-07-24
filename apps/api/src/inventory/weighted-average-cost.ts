/** Weighted-average unit cost (VND integers). */
export function weightedAverageCost(
  oldQty: number,
  oldAvgVnd: number,
  receiptQty: number,
  unitCostVnd: number,
): number {
  if (!(receiptQty > 0) || !Number.isFinite(receiptQty)) {
    return Math.max(0, Math.round(oldAvgVnd));
  }
  if (!(oldQty > 0)) {
    return Math.max(0, Math.round(unitCostVnd));
  }
  const totalQty = oldQty + receiptQty;
  const avg = (oldQty * oldAvgVnd + receiptQty * unitCostVnd) / totalQty;
  return Math.max(0, Math.round(avg));
}
