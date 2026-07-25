# Go-live operator checklist (Wave A — Tasks A.2–A.5)

Use this checklist after Wave 1 in-repo artifacts are on `main` and pushed to
`origin`. **No live VPS or gateway credentials are required in the repo** — the
operator completes these steps on the production host and POS machines.

**Prerequisites:** Task A.1 done (`main` matches `origin/main`).

| Task | Topic | Runbook |
|------|-------|---------|
| A.2 | Secrets + real owner | [production-secrets.md](production-secrets.md) |
| A.3 | Host API + backup | [production-deploy.md](production-deploy.md) |
| A.4 | HĐĐT day 1 (branch) | [einvoice-http.md](einvoice-http.md) |
| A.5 | POS prod pointer | [windows-prod.md](windows-prod.md), [android-release.md](android-release.md) |

**Default day-1 HĐĐT path:** `EINVOICE_PROVIDER=stub` — cửa hàng **chưa HĐĐT thật**.
No Viettel/MISA SDK in this repo. Do not issue legal tax invoices to customers or
CQT until a real HTTP gateway is configured (see A.4 branch B).

Never commit `apps/api/.env.production`, JWT secrets, gateway API keys, keystore
files, or backup dumps.

---

## Task A.2 — Secrets + owner on host

**Docs:** [production-secrets.md](production-secrets.md)

- [ ] Generate `JWT_SECRET` (PowerShell command in doc); set on host only — **do not commit**.
- [ ] Minimum env on host: `NODE_ENV=production`, `DATABASE_URL`, `JWT_SECRET`, `PORT`.
- [ ] Run `npx prisma migrate deploy` on production DB (or via Compose — see [production-deploy.md](production-deploy.md)).
- [ ] Create real owner: `npm run create-owner` with `OWNER_PHONE` / `OWNER_PASSWORD` (Compose: pass `-e` as in deploy doc).
- [ ] Disable or rotate seed account `0900000001` if seed ever ran on prod.
- [ ] Verify: `GET /health` → `{ "ok": true }`; login with real owner OK; login `123456` fails or seed disabled.

---

## Task A.3 — Host API + backup

**Docs:** [production-deploy.md](production-deploy.md)

- [ ] Choose host path: Docker Compose (`apps/api/Dockerfile`, `docker-compose.prod.yml`) or Node on VPS per runbook.
- [ ] Create `apps/api/.env.production` on host only; build and start API + PostgreSQL.
- [ ] Confirm first deploy: migrate deploy, API healthy, owner from A.2 can log in.
- [ ] Schedule daily `pg_dump`; retain ≥ 7 backups.
- [ ] Run one restore trial on staging or secondary DB.
- [ ] Record backup path internally (not required in git).

---

## Task A.4 — HĐĐT day 1 (choose one branch)

**Docs:** [einvoice-http.md](einvoice-http.md)

### Branch A — Default: stub / chưa HĐĐT thật (recommended when no gateway)

- [ ] Set `EINVOICE_PROVIDER=stub` (or omit); **do not** set `EINVOICE_HTTP_URL`.
- [ ] Document store status: **chưa HĐĐT thật** — stub numbers are not valid for CQT/tax filing.
- [ ] Do **not** train staff to treat **Xuất HĐĐT** stub output as legal invoices for customers.
- [ ] Optional: test **Xuất HĐĐT** in POS for workflow only; confirm UI shows `provider: stub`.

### Branch B — Real gateway (only when provider URL + key are available)

- [ ] Set `EINVOICE_PROVIDER=http`, `EINVOICE_HTTP_URL`, `EINVOICE_HTTP_API_KEY`; restart API.
- [ ] From POS: sync a sale, **Xuất HĐĐT** once; confirm `provider: http` and allowed `status`.
- [ ] Issue again for same sale → idempotent (same `invoiceNumber`, no duplicate provider charge).

---

## Task A.5 — POS prod pointer

**Docs:** [windows-prod.md](windows-prod.md), [android-release.md](android-release.md)

### Windows (counter)

- [ ] Confirm API health at production HTTPS base URL (no trailing slash).
- [ ] Build or run: `flutter build windows --release --dart-define=API_URL=https://…` (real URL).
- [ ] Deploy `build\windows\x64\runner\Release\` to counter machine(s).
- [ ] Smoke: login → chọn CH → mở ca → bán 1 đơn TM → **Đồng bộ** → báo cáo ngày shows revenue.

### Android (if using tablet/phone)

- [ ] Create local keystore + `key.properties` (never commit).
- [ ] `flutter build apk --release --dart-define=API_URL=https://…` (JDK required).
- [ ] Install release APK; smoke same path as Windows (login → ca → bán → sync).

---

## Wave A definition of done

- [ ] A.2–A.5 checkboxes above completed on live host and ≥ 1 POS machine.
- [ ] API prod healthy; real owner login; backup restore tried once.
- [ ] POS points at prod API; ≥ 1 cash sale synced and visible in day report.
- [ ] HĐĐT: gateway verified **or** stub documented as **chưa HĐĐT thật**.

Next: Wave B (multi-device smoke, PDF Unicode, optional FCM) — see
`docs/superpowers/plans/2026-07-25-hoan-thien-con-lai.md`.
