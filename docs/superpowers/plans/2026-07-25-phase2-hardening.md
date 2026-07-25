# Phase 2 Hardening Checklist (Closeout)

> Gate đóng Giai đoạn 2 theo parent design §8. Ngày: 2026-07-25.  
> Design DoD: `docs/superpowers/specs/2026-07-23-tap-hoa-pos-ke-toan-design.md` §8.  
> Scope closeout: ledger trả hàng/kiểm kê + Flutter HĐĐT stub/CSV/quỹ/NH + docs.  
> **Ngoài scope:** VAT CoA thật, provider HĐĐT thật (Viettel/MISA/…).

**Gate P2 Closeout:** **PASS** (2026-07-25) — A0 xanh; A1 §8 evidence bằng e2e.

---

## A0 — Baseline tự động

- [x] `npx prisma migrate deploy` — No pending migrations
- [x] `npm run build` (`apps/api`) — OK
- [x] `npm run test:e2e` — **19 suites / 61 tests PASS**
- [x] `flutter analyze` (files closeout) — No issues
- [x] `flutter test` — **95 PASS**

| Lệnh | Status | Ghi chú |
|------|--------|--------|
| migrate deploy | PASS | DB `127.0.0.1:54322` |
| nest build | PASS | |
| test:e2e | PASS | 61/61 |
| flutter analyze | PASS | closeout UI files |
| flutter test | PASS | 95/95 |

---

## A1 — Parent design §8 evidence

| Tiêu chí §8 | Evidence |
|-------------|----------|
| Lãi theo giá vốn tin cậy | `cogs-wac.e2e-spec.ts` + period PnL `period-reports.e2e-spec.ts` |
| Xuất HĐĐT từ đơn đã sync | `einvoice.e2e-spec.ts` (stub); Flutter `EInvoiceIssuePage` (sale local `syncedAt != null`) |
| Khóa sổ tháng có audit | `ledger.e2e-spec.ts` + `ledger-returns-stocktake.e2e-spec.ts` (period lock blocks post) |

### Suite Phase 2 / closeout

- [x] COGS WAC — `cogs-wac.e2e-spec.ts`
- [x] Ledger sale + khóa sổ — `ledger.e2e-spec.ts`
- [x] Return + stocktake journals — `ledger-returns-stocktake.e2e-spec.ts`
- [x] AP pay — `ap-cash.e2e-spec.ts`
- [x] HĐĐT stub — `einvoice.e2e-spec.ts`
- [x] Period PnL khớp sổ — `period-reports.e2e-spec.ts`

### Flutter smoke (manual / analyze)

- [x] Owner: **Sổ kế toán** (CSV copy, kỳ khóa hint, KQKD)
- [x] Owner/manager: **Xuất HĐĐT**, **Sổ quỹ kỳ**, **Công nợ NCC** (+ TK NH khi CK)

---

## A2 — Closeout deliverables

| Wave | Deliverable | Status |
|------|-------------|--------|
| 1 | `buildSaleReturnJournal` / `buildStocktakeJournal` + hooks fail-soft | Done |
| 2 | Flutter HĐĐT / CSV / cash-fund / bank on NCC pay | Done |
| 3 | Hardening + README/CHANGELOG/roadmap | Done |

---

## Deferred (Phase 3 outline)

- VAT/GTGT CoA + journal lines
- Real e-invoice provider adapter
- Excel/PDF export; trả hàng NCC giảm AP; full bank recon
- Journals for wastage/transfer; period unlock
