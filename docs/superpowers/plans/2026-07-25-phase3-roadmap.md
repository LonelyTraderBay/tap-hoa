# Phase 3 roadmap index

| Order | Epic | Plan / gate | Status |
|------|------|-------------|--------|
| 1 | Kế toán thuế GTGT | `2026-07-25-phase3-vat.md` | **Done** |
| 2 | Provider HĐĐT HTTP | `2026-07-25-phase3-einvoice-http-design.md` | Done (env `EINVOICE_PROVIDER=http`) |
| 3 | PDF kỳ + hỗ trợ kê khai GTGT | `/export.pdf`, `/vat-declaration.csv` | Done (không nộp CQT) |
| 4 | Trả hàng NCC (giảm AP) | `POST /suppliers/:id/returns` | Done |
| 5 | Đối chiếu chuyển khoản | `/reports/bank-recon*` | Done |

Tracks Done: VAT journals/report/Excel; HĐĐT HTTP gateway; supplier return; bank recon; period PDF + VAT declaration assist (no CQT submit).

**Production closeout:** **PASS (hardening, merged to `main`)** — see `2026-07-25-phase3-hardening.md` (26 e2e suites / 77 tests; store-scoped period reports; net VAT; supplier return AP integrity; bank recon idempotency; HĐĐT HTTP timeout/retry/idempotency).
