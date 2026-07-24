# Phase 2 Epic 4 — Hóa đơn điện tử

**Ngày:** 2026-07-24  
**Phụ thuộc:** P1 sync ổn định + Epic 2 audit/roles  
**Parent:** design §5.5, §5.8 #4

## Deliverable

- `EInvoiceAdapter` interface; stub + one provider adapter (chọn khi implement: Viettel / MISA / EasyInvoice).
- Lập HĐ từ Sale đã sync + online; trạng thái: draft / pending_sign / issued / cancelled.
- Lưu MST khách, mẫu số, ký hiệu; XML/PDF storage path.
- Chỉ xuất khi `sale` đã accepted trên server.

## Gate

- Offline / unsynced sale → reject issue.
- Đổi adapter implementation không đụng checkout/sync core.

## Ngoài scope

- Kê khai thuế CQT tự động.
