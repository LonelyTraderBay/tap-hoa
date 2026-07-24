# Phase 1 Hardening Checklist

> Gate trước Giai đoạn 2. Ngày: 2026-07-24.  
> Design DoD: `docs/superpowers/specs/2026-07-23-tap-hoa-pos-ke-toan-design.md` §6.4, §8.

**Gate P1:** **PASS** (2026-07-24) — A0 xanh; A1–A3 chứng minh bằng e2e + unit; bug login/FCM + timer banner đã fix.

---

## A0 — Baseline tự động

- [x] `npx prisma migrate deploy` — No pending migrations
- [x] `npm run build` (`apps/api`) — OK
- [x] `npm run test:e2e` — **13 suites / 52 tests PASS**
- [x] `flutter analyze` — 11 info/warning only (no errors); Radio deprecations deferred
- [x] `flutter test` — **93 PASS** (sau fix PushService + banner timer)

| Lệnh | Status | Ghi chú |
|------|--------|--------|
| migrate deploy | PASS | DB `127.0.0.1:54322` |
| nest build | PASS | |
| test:e2e | PASS | 52/52 |
| flutter analyze | PASS* | *info/warning only |
| flutter test | PASS | 93/93 |

**Bugs fixed in A0:**
| ID | Severity | Description | Status |
|----|----------|-------------|--------|
| H1 | High | `PushService` / mock `dio` làm fail login → chặn navigate "Mở ca" | Fixed — try/catch quanh register |
| H2 | Med | `SyncStatusBanner` tests: Drift timer pending after dispose | Fixed — unmount + pump 1ms |

---

## A1 — README MVP acceptance

Evidence = API e2e (automated stand-in for manual UI smoke trên CI/dev).

- [x] Login `0900000001` / `123456` → store — `auth.e2e-spec.ts`
- [x] Mở ca → không bán khi chưa mở — `shifts.e2e-spec.ts` + checkout unit
- [x] Pull catalog STING-330 + tồn — `sync-pull.e2e-spec.ts`
- [x] Bán → sync → đơn lên server — `sync-push.e2e-spec.ts`
- [x] Máy B pull → tồn giảm — `sync-multi-device.e2e-spec.ts`
- [x] Báo cáo ngày khớp — `reports.e2e-spec.ts`
- [x] Bán ghi nợ → balance — `customers-debt.e2e-spec.ts` / `debt-payments.e2e-spec.ts`

---

## A2 — Design §6.4

| ID | Kịch bản | Pass? | Evidence |
|----|----------|-------|----------|
| D1 | Offline→online / điểm khác + báo cáo tổng | PASS | `sync-multi-device` + `reports` e2e |
| D2 | Hai điểm bán cùng SKU | PASS | `sync-multi-device.e2e-spec.ts` |
| D3 | Ghi nợ A + thu nợ một phần | PASS | `debt-payments.e2e-spec.ts` |
| D4 | Sync lỗi / outbox Conflict UI | PASS | `outbox_conflict_service_test` + reject paths e2e |

---

## A3 — Polish feature smoke

- [x] Combo / `invalid_combo` — `phase1-polish.e2e` + `checkout_combo_test`
- [x] Nhóm SP CRUD + inactive — `sale_return_refund_test` (group) + polish e2e
- [x] Trả hàng role / refund — `phase1-polish.e2e` + refund unit
- [x] `debtOverdueDays` / aging — `debt_aging_test` + API patch stores
- [x] Print modes — unit `receipt_print_test`; ESC/POS Win32 manual-deferred hardware
- [x] FCM soft-fail — login no longer crashes without Firebase
- [x] Conflict UI — `outbox_conflict_service_test` (11)
- [x] CSV / stock-on-hand / top SKU / diagnostics — unit + reports e2e

---

## A4 — Ops runbook (no secrets)

### Deploy API

1. Set `DATABASE_URL`, `JWT_SECRET`, `PORT` (`apps/api/.env.example`).
2. `cd apps/api && npx prisma migrate deploy && npm run build && npm run start:dev`.
3. Optional FCM: `FIREBASE_SERVICE_ACCOUNT` = absolute path to service-account JSON.

### Deploy POS

1. Optional: `flutterfire configure` → replace `firebase_options.dart`; placeholder skips FCM safely.
2. Windows printer: Settings → `pdf` \| `escpos` \| `ask` + printer name.
3. `flutter run -d windows --dart-define=API_URL=<api>`.

### Gate

- [x] README MVP acceptance ticks updated
- [x] **P1 hardened 2026-07-24** — Gate: **PASS**
