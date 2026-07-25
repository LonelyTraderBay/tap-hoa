# Changelog

## Unreleased

### Phase 3 — Trả hàng NCC

- `POST /suppliers/:id/returns` — giảm tồn, FIFO giảm AP, journal đảo nhập (VAT-aware)
- Flutter: nút Trả hàng trên màn Công nợ NCC

### Phase 3 — HĐĐT HTTP

- `EINVOICE_PROVIDER=stub|http` + `EINVOICE_HTTP_URL` / optional API key
- Sale lines included in provider payload; Flutter copy updated

### Phase 3 — VAT / GTGT

- Store flags: `vatEnabled`, `defaultVatRateBps`; product optional `vatRateBps`
- CoA `1331` (input VAT), `3331` (output VAT); inclusive split on sale/purchase/return
- Purchase WAC uses net unit cost when VAT on
- `GET /reports/period/vat`, `GET /reports/period/export.xlsx`
- `PATCH /stores/:id/vat`; Flutter ledger VAT tab + GTGT settings + Excel export
