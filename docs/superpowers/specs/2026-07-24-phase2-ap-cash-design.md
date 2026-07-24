# Phase 2 Epic 3 — Công nợ NCC + quỹ/NH

**Ngày:** 2026-07-24  
**Phụ thuộc:** Epic 2 ledger  
**Parent:** design §5.3, §5.4, §5.8 #3

## Deliverable

- Hồ sơ NCC; phiếu nhập tăng AP; thanh toán / trả hàng giảm AP; đối chiếu kỳ.
- Sổ quỹ tiền mặt theo điểm (mở rộng thu chi GĐ1); TK ngân hàng + đối chiếu CK POS mức đơn giản.
- Bút toán AP/quỹ qua ledger Epic 2.

## Gate

- Nhập hàng có `unitCostVnd` → tăng AP + cập nhật WAC (đã có Epic 1).
- Chi trả NCC giảm AP; quỹ khớp break-down ca ở mức spec.

## Ngoài scope

- Multi-currency, banking API sync, full bank reconciliation UI.
