# Changelog

## Unreleased

- Wave F: Manager `canLedger` POS access, multi-line PO create/receive, customer debt adjustments with audit/debt ledger entries, idempotent batch HĐĐT retry, and quarterly npm-audit ops reminders.
- Wave C: AP statement reconciliation for suppliers with CSV import, read-only summaries, match/unmatch/auto-match, zero-variance locking, e2e coverage, and Flutter entry points from Công nợ NCC.

## 0.3.0

### Design complete

- Design §4/§5 is feature-complete via PR #18: POS gaps, accounting/VAT, HĐĐT, audit, and reporting closeout are documented as complete.
- Prepared release tag name for documentation only: `v0.3.0-design-complete` (tag not created).

### Ops

- Documented periodic `npm audit --omit=dev` tracking for `apps/api` (no `audit fix --force`; exceljs / firebase-admin transitive findings).
- Product sync now audits `product_price_change` when an existing product price changes, exposed through ledger audit filters.
- Sales are not silently deleted or voided; returns remain the supported correction path.

### Wave 8 — Reports

- `GET /reports/day` now includes per-shift revenue breakdowns in `byShift`.
- `GET /reports/debt-aging` supports owner/manager aggregate scope when `storeId` is omitted.
- Added `GET /reports/ar.csv` for accounts-receivable customer debt CSV export.

### POS

- Added per-cart-line VND discounts, synced as `SaleLine.discountVnd`; line discounts apply before invoice-level discounts.
- Added post-checkout receipt sharing with a saved PDF fallback on Windows.
- Added periodic local SQLite backups for the POS app with 7-copy retention, stale reminders, and a manual backup action in sync diagnostics.

### Phase 2 — Closeout follow-up

- Ledger periods can now be unlocked by owners with an audit reason; Flutter sổ shows period lock/unlock audit and unlock controls.
- Wastage sync now posts WAC ledger journals (Dr `642` / Cr `156`) with period-lock audit coverage.
- Stock transfer receive now posts WAC transfer journals (Dr `156` / Cr `156`) with period-lock replay coverage.

### Phase 3 — PDF kỳ + hỗ trợ kê khai GTGT

- `GET /reports/period/export.pdf` (CĐPS/KQKD/VAT)
- `GET /reports/period/vat-declaration.csv` — worksheet hỗ trợ kế toán, không nộp CQT
- Flutter sổ: Xuất PDF + hỗ trợ kê khai

### Phase 3 — Đối chiếu CK

- Import sao kê CSV, khớp amount với sale/voucher/NCC transfer, khóa kỳ
- Flutter: màn Đối chiếu CK

### Phase 3 — Trả hàng NCC

- `POST /suppliers/:id/returns` — giảm tồn, FIFO giảm AP, journal đảo nhập (VAT-aware)
- Flutter: nút Trả hàng trên màn Công nợ NCC

### Phase 3 — HĐĐT HTTP

- `EINVOICE_PROVIDER=stub|http` + `EINVOICE_HTTP_URL` / optional API key
- Sale lines included in provider payload; Flutter copy updated
- `POST /einvoices/:id/cancel` cancels issued/pending-sign HĐĐT only; Flutter adds a reason-confirmed cancel action.

### Wave 6 — HĐĐT gộp + điều chỉnh

- `POST /einvoices/issue-batch` issues one HĐĐT for multiple synced same-customer sales.
- `POST /einvoices/:id/adjust` creates a linked adjustment invoice via stub/HTTP providers.
- Flutter HĐĐT screen supports same-customer multi-select and issued-invoice adjustment.

### Phase 3 — VAT / GTGT

- Store flags: `vatEnabled`, `defaultVatRateBps`; product optional `vatRateBps`
- CoA `1331` (input VAT), `3331` (output VAT); inclusive split on sale/purchase/return
- Purchase WAC uses net unit cost when VAT on
- `GET /reports/period/vat`, `GET /reports/period/export.xlsx`
- `PATCH /stores/:id/vat`; Flutter ledger VAT tab + GTGT settings + Excel export
