# Changelog

## Unreleased

### POS

- Added per-cart-line VND discounts, synced as `SaleLine.discountVnd`; line discounts apply before invoice-level discounts.
- Added post-checkout receipt sharing with a saved PDF fallback on Windows.

### Phase 2 — Closeout follow-up

- Ledger periods can now be unlocked by owners with an audit reason; Flutter sổ shows period lock/unlock audit and unlock controls.
- Wastage sync now posts WAC ledger journals (Dr `642` / Cr `156`) with period-lock audit coverage.

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

### Phase 3 — VAT / GTGT

- Store flags: `vatEnabled`, `defaultVatRateBps`; product optional `vatRateBps`
- CoA `1331` (input VAT), `3331` (output VAT); inclusive split on sale/purchase/return
- Purchase WAC uses net unit cost when VAT on
- `GET /reports/period/vat`, `GET /reports/period/export.xlsx`
- `PATCH /stores/:id/vat`; Flutter ledger VAT tab + GTGT settings + Excel export
