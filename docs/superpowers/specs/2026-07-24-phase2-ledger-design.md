# Phase 2 Epic 2 — Sổ kế toán tự động

**Ngày:** 2026-07-24  
**Phụ thuộc:** Epic 1 COGS (WAC + SaleLine.unitCostVnd)  
**Parent:** design §5.1, §5.7, §5.8 #2

## Deliverable

- Chart of accounts gọn (hộ KD): tiền mặt, NH, hàng tồn, phải thu KH, phải trả NCC, doanh thu, giá vốn, chi phí.
- Auto journal từ chứng từ GĐ1 đã sync: bán, COGS, thu nợ, thu chi quỹ, nhập hàng (AP stub nếu chưa Epic 3).
- UI/API: sổ nhật ký, sổ cái, cân đối phát sinh theo kỳ.
- Khóa sổ tháng; sửa sau khóa cần quyền owner + audit log.

## Gate

- Mỗi sale sync sinh ĐR tiền/nợ + ĐR COGS đúng WAC snapshot.
- Khóa sổ chặn tạo bút toán mới trong kỳ khóa.

## Ngoài scope

- FIFO, HĐĐT, AP đầy đủ (Epic 3), VAT declaration.
