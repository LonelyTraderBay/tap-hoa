import {
  computeInventoryMovement,
  computeOpeningQty,
  InventoryMovementRow,
} from './inventory-movement';

function row(
  qtyDelta: number,
  balanceAfter: number,
  docType: string,
  at = '2026-07-15T00:00:00.000Z',
): InventoryMovementRow {
  return { qtyDelta, balanceAfter, docType, clientCreatedAt: new Date(at) };
}

describe('computeOpeningQty', () => {
  it('trả 0 khi chưa từng có lịch sử trước kỳ', () => {
    expect(computeOpeningQty(undefined)).toBe(0);
  });

  it('trả đúng balanceAfter của dòng gần nhất trước kỳ', () => {
    expect(computeOpeningQty({ balanceAfter: 42 })).toBe(42);
  });
});

describe('computeInventoryMovement', () => {
  it('rỗng thì tồn cuối kỳ == tồn đầu kỳ, không nhập không xuất', () => {
    const totals = computeInventoryMovement(10, []);
    expect(totals).toEqual({
      openingQty: 10,
      inQty: 0,
      outQty: 0,
      closingQty: 10,
      inByDocType: {},
      outByDocType: {},
    });
  });

  it('cộng nhập/xuất theo dấu qtyDelta, không theo bảng ánh xạ docType cố định', () => {
    const totals = computeInventoryMovement(100, [
      row(50, 150, 'purchase'),
      row(-20, 130, 'sale'),
      row(-5, 125, 'wastage'),
      // transfer có thể là dòng TĂNG (nhận từ điểm khác)...
      row(15, 140, 'transfer'),
      // ...hoặc dòng GIẢM (chuyển đi điểm khác) — cùng docType, khác chiều.
      row(-8, 132, 'transfer'),
      // stocktake cũng vậy: có thể tăng (kiểm kê dư) hoặc giảm (kiểm kê thiếu).
      row(3, 135, 'stocktake'),
      row(-2, 133, 'stocktake'),
    ]);

    expect(totals.openingQty).toBe(100);
    expect(totals.inQty).toBe(50 + 15 + 3); // 68
    expect(totals.outQty).toBe(20 + 5 + 8 + 2); // 35
    expect(totals.closingQty).toBe(100 + 68 - 35); // 133
    expect(totals.inByDocType).toEqual({
      purchase: 50,
      transfer: 15,
      stocktake: 3,
    });
    expect(totals.outByDocType).toEqual({
      sale: 20,
      wastage: 5,
      transfer: 8,
      stocktake: 2,
    });
  });

  it('dòng qtyDelta = 0 (kiểm kê khớp) không tính vào nhập lẫn xuất', () => {
    const totals = computeInventoryMovement(20, [row(0, 20, 'stocktake')]);
    expect(totals.inQty).toBe(0);
    expect(totals.outQty).toBe(0);
    expect(totals.closingQty).toBe(20);
    expect(totals.inByDocType).toEqual({});
    expect(totals.outByDocType).toEqual({});
  });

  it('nhiều dòng cùng docType cùng chiều được cộng dồn', () => {
    const totals = computeInventoryMovement(0, [
      row(10, 10, 'purchase'),
      row(5, 15, 'purchase'),
    ]);
    expect(totals.inByDocType).toEqual({ purchase: 15 });
    expect(totals.inQty).toBe(15);
  });

  it('bất biến: opening + nhập − xuất == closing (kể cả số âm/lẻ)', () => {
    const totals = computeInventoryMovement(7.5, [
      row(2.25, 9.75, 'purchase'),
      row(-1.5, 8.25, 'sale'),
    ]);
    expect(totals.closingQty).toBeCloseTo(
      totals.openingQty + totals.inQty - totals.outQty,
    );
    expect(totals.closingQty).toBeCloseTo(8.25);
  });
});
