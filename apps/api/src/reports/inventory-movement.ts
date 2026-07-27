/**
 * Báo cáo nhập–xuất–tồn theo kỳ/điểm (P2.3).
 *
 * Nguồn sự thật: `StockMovement` — một dòng/lần thay đổi tồn, `qtyDelta` có
 * dấu (dương = nhập, âm = xuất), `balanceAfter` = tồn ngay sau dòng đó.
 * Module này chỉ chứa phần tính toán thuần (không đụng Prisma) để dễ unit
 * test — theo đúng khuôn `cash-fund.ts`/`debt-aging.ts` trong cùng thư mục.
 */

/** Một dòng StockMovement đã convert Decimal → number, đã lọc theo 1 product. */
export type InventoryMovementRow = {
  qtyDelta: number;
  balanceAfter: number;
  docType: string;
  clientCreatedAt: Date;
};

export type InventoryMovementTotals = {
  /** Tồn đầu kỳ — balanceAfter của dòng gần nhất trước periodStart (0 nếu chưa từng có). */
  openingQty: number;
  /** Tổng nhập trong kỳ (tổng qtyDelta dương). */
  inQty: number;
  /** Tổng xuất trong kỳ (trị tuyệt đối tổng qtyDelta âm). */
  outQty: number;
  /** Tồn cuối kỳ = openingQty + inQty − outQty. */
  closingQty: number;
  /** Nhập trong kỳ, tách theo docType của từng dòng (chỉ dòng qtyDelta > 0). */
  inByDocType: Record<string, number>;
  /** Xuất trong kỳ, tách theo docType của từng dòng (chỉ dòng qtyDelta < 0). */
  outByDocType: Record<string, number>;
};

/**
 * Tồn đầu kỳ = balanceAfter của dòng StockMovement gần nhất có
 * `clientCreatedAt < periodStart` cho đúng sản phẩm+điểm bán đó. `latest`
 * là dòng đó nếu có (service truy nó bằng 1 query `distinct` theo productId,
 * `orderBy clientCreatedAt desc` — hiệu quả hơn tải toàn bộ lịch sử rồi lọc
 * tay), `undefined` nếu sản phẩm chưa từng có lịch sử trước kỳ này (0).
 */
export function computeOpeningQty(
  latest: { balanceAfter: number } | undefined,
): number {
  return latest ? latest.balanceAfter : 0;
}

/**
 * Cộng dồn nhập/xuất trong kỳ (kèm breakdown theo docType) từ danh sách
 * StockMovement đã lọc đúng 1 sản phẩm + trong khoảng [periodStart, periodEnd].
 * Chiều nhập/xuất suy từ DẤU của từng dòng qtyDelta thực tế — KHÔNG suy theo
 * một bảng ánh xạ docType→chiều cố định, vì `transfer`/`stocktake`/... có thể
 * là dòng tăng hoặc giảm tuỳ chứng từ cụ thể (chuyển đến vs chuyển đi, kiểm kê
 * tăng vs giảm). Dòng qtyDelta === 0 (kiểm kê khớp, không lệch) không tính
 * vào nhập cũng không tính vào xuất.
 */
export function computeInventoryMovement(
  openingQty: number,
  periodMovements: InventoryMovementRow[],
): InventoryMovementTotals {
  let inQty = 0;
  let outQty = 0;
  const inByDocType: Record<string, number> = {};
  const outByDocType: Record<string, number> = {};

  for (const m of periodMovements) {
    if (m.qtyDelta > 0) {
      inQty += m.qtyDelta;
      inByDocType[m.docType] = (inByDocType[m.docType] ?? 0) + m.qtyDelta;
    } else if (m.qtyDelta < 0) {
      const abs = Math.abs(m.qtyDelta);
      outQty += abs;
      outByDocType[m.docType] = (outByDocType[m.docType] ?? 0) + abs;
    }
    // qtyDelta === 0: kiểm kê khớp hệ thống — không phát sinh nhập/xuất.
  }

  return {
    openingQty,
    inQty,
    outQty,
    closingQty: openingQty + inQty - outQty,
    inByDocType,
    outByDocType,
  };
}
