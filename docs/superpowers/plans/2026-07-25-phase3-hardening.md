# Phase 3 Hardening Checklist (Closeout)

> Gate đóng Phase 3 production-readiness. Ngày bắt đầu: 2026-07-25.  
> Scope: accounting/tenant correctness, supplier return/AP, bank recon, HĐĐT HTTP, UX/exports.  
> **Ngoài scope:** nộp CQT tự động; SDK Viettel/MISA riêng; Phase 4 features.

**Gate P3 Hardening:** **PASS** (2026-07-25)

---

## A0 — Baseline tự động

| Lệnh | Status | Ghi chú |
|------|--------|--------|
| migrate deploy | PASS | `20260725160000_phase3_hardening` + tax snapshot follow-ups |
| nest build | PASS | |
| test:e2e | PASS | **26 suites / 77 tests** |
| jest unit (journal-builders) | PASS | **4 suites / 22 tests** (incl. mixed VAT) |
| flutter analyze (Phase 3 UI) | PASS | no errors (info-only async context hints) |
| flutter test | PASS | **95** tests |

## Known issues → fixed

1. Period reports filter `storeId` (owner aggregate khi omit; manager scoped).
2. VAT summary net movement: `3331 Cr−Dr`, `1331 Dr−Cr`, `511 Cr−Dr`.
3. Sale journal per-line `Product.vatRateBps` + discount allocation; snapshots on `SaleLine` / purchase / return lines.
4. Supplier return bắt buộc `purchaseReceiptId`; chặn over-qty/over-AP; idempotent `clientId`; journal trong transaction.
5. Bank recon: fingerprint idempotent import; GET read-only; match/unmatch/auto-match; lock khi variance=0.
6. HĐĐT HTTP: timeout, retry 429/5xx, `Idempotency-Key`, status allowlist, redact logs.

## Characterization / gate evidence

| Criterion | Evidence |
|-----------|----------|
| Multi-store period scope | `test/phase3-hardening.e2e-spec.ts`, `phase3-hardening-accounting.e2e-spec.ts` |
| VAT net after sale return | same + unit `journal-builders.spec.ts` |
| Mixed product VAT rates | hardening e2e + unit |
| Supplier over-return blocked | hardening e2e + `supplier-return.e2e-spec.ts` |
| Bank import idempotent / GET no mutation | hardening + `bank-recon.e2e-spec.ts` |
| HĐĐT idempotency + unknown status | hardening e2e |

## Waves

| Wave | Branch intent | Status |
|------|---------------|--------|
| A1 | accounting integrity | Done (on `hardening/phase3-closeout`) |
| A2–A3 | transaction + einvoice | Done |
| A4–A5 | UX + release gate | Done |

## Security / dependency audit

- Ran `npm audit --omit=dev` in `apps/api` (2026-07-25): **27** findings (14 moderate / 12 high / 1 critical), predominantly **transitive** via `exceljs`→`uuid` and `firebase-admin`→`google-gax`/`uuid`.
- **Acceptance:** no `audit fix --force` (would downgrade exceljs to breaking 3.x). Track upstream upgrades for exceljs/firebase-admin; `uuid` buffer issue is not on our direct call path for v4 random IDs.
- Flutter analyze: no errors on Phase 3 UI (info-only `use_build_context_synchronously`).

## Known limitations

- PDF Unicode depends on `C:\Windows\Fonts\arial.ttf` when present; falls back to Helvetica.
- Bank CSV import via paste (no OS file_picker dependency); fingerprint dedupes re-import.
- HĐĐT “real” provider still via generic HTTP gateway (not vendor SDK).
- Nộp CQT tự động vẫn ngoài scope.

## Runbook

1. `cd apps/api && npx prisma migrate deploy`
2. Optional env: `EINVOICE_PROVIDER=http`, `EINVOICE_HTTP_URL=https://…`, `EINVOICE_HTTP_API_KEY`, `EINVOICE_HTTP_TIMEOUT_MS`
3. Rollback: restore DB snapshot before hardening migrations; revert app to pre-hardening commit.
