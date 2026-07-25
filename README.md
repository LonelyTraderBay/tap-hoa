# tap-hoa

Offline-first grocery POS monorepo (Phase 1–2 + Phase 3 VAT track).

| Path | Stack | Purpose |
|------|-------|---------|
| `apps/api` | NestJS 10, Prisma, PostgreSQL | Central API — auth, sync, ledger, AP, VAT journals, period Excel, e-invoice |
| `apps/pos_app` | Flutter 3, Drift/SQLite | POS client (Windows, Android, iOS) |

**Spec:** `docs/superpowers/specs/2026-07-23-tap-hoa-pos-ke-toan-design.md`  
**Phase 2 closeout:** `docs/superpowers/plans/2026-07-25-phase2-hardening.md`  
**Phase 3 VAT gate:** `docs/superpowers/plans/2026-07-25-phase3-vat.md`  
**Phase 3 roadmap:** `docs/superpowers/plans/2026-07-25-phase3-roadmap.md`

## Prerequisites

- **Node.js** 18+ and npm
- **Flutter** 3.24+ (`flutter doctor`)
- **PostgreSQL 16** — either a local install on port 5432, or **Supabase CLI** for the port **54322** workaround (recommended on Windows; see below)

## Dev setup

### 1. PostgreSQL

#### Option A — Supabase local (recommended on Windows)

On some Windows machines, a system PostgreSQL service on `:5432` rejects the `postgres:postgres` credentials from `.env.example`. This project uses **Supabase CLI** to run PostgreSQL on **port 54322** instead.

```powershell
cd apps/api
npx supabase start          # first run downloads images; PG listens on 127.0.0.1:54322
```

Use this `DATABASE_URL` in `apps/api/.env`:

```env
DATABASE_URL=postgresql://postgres:postgres@127.0.0.1:54322/postgres?schema=public
JWT_SECRET=dev-change-me
PORT=3000
```

Prisma migrations and seed run against the `postgres` database on that instance. Stop the stack with `npx supabase stop` when done.

#### Option B — Standalone PostgreSQL

Create database `tap_hoa` on PostgreSQL 16 (default port 5432), then copy `.env.example` to `.env` unchanged:

```env
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/tap_hoa?schema=public
```

### 2. API

```powershell
cd apps/api
cp .env.example .env        # edit DATABASE_URL if using Supabase :54322 (see above)
npm install
npx prisma migrate dev
npx prisma db seed
npm run start:dev           # http://localhost:3000
```

Verify: `GET http://localhost:3000/health` → `{ "ok": true }`.

**Seed login:** phone `0900000001`, password `123456` (owner, stores CH1 + CH2, product STING-330).

Run API tests:

```powershell
cd apps/api
npm run test:e2e
```

### 3. Flutter POS (Windows)

```powershell
cd apps/pos_app
flutter pub get
flutter run -d windows --dart-define=API_URL=http://localhost:3000
```

Signed Android release APKs require a local keystore and `apps/pos_app/android/key.properties`; see `docs/ops/android-release.md`. Production Windows builds use `--dart-define=API_URL=https://…`; see `docs/ops/windows-prod.md`.

| Platform | `API_URL` |
|----------|-----------|
| Windows / iOS simulator | `http://localhost:3000` |
| Android emulator | `http://10.0.2.2:3000` |

Run Flutter tests:

```powershell
cd apps/pos_app
flutter test
```

## Phase 1 MVP acceptance checklist

Manual smoke test after API + POS are running:

- [x] **Login and select store** — sign in as `0900000001` / `123456`, pick CH1 or CH2 (`auth.e2e`)
- [x] **Open shift** — enter opening cash; cannot sell without an open shift (`shifts.e2e`)
- [x] **Pull products** — catalog sync shows STING-330 and stock qty for the selected store (`sync-pull.e2e`)
- [x] **Sell offline then sync** — disable network, complete a cash sale, re-enable network, run sync (auto timer, app resume, or manual **Đồng bộ**); sale appears on server (`sync-push.e2e`)
- [x] **Second device sees new stock after pull** — after device A syncs a sale, device B pulls and stock qty decreases (`sync-multi-device.e2e`)
- [x] **Day report shows revenue** — `/reports/day` and in-app day report match sales for the store (owner sees consolidated total) (`reports.e2e`)
- [x] **Debt sale increases customer balance after sync** — checkout with debt + customer selected; after push, customer balance increases on server and in debt list (`customers-debt.e2e` / `debt-payments.e2e`)

Hardening gate: see `docs/superpowers/plans/2026-07-24-phase1-hardening.md` (PASS 2026-07-24).

## Phase 2 acceptance checklist (parent §8)

- [x] **COGS / WAC** — purchase updates `avgCostVnd`; sale snapshots `unitCostVnd` (`cogs-wac.e2e`)
- [x] **Auto journals + period lock** — sale/debt/cash/purchase/AP/return/stocktake; lock blocks post + audit (`ledger*.e2e`)
- [x] **AP NCC** — purchase opens payable; payment reduces AP (`ap-cash.e2e`)
- [x] **HĐĐT stub** — issue only for synced sale; Flutter **Xuất HĐĐT** (`einvoice.e2e`)
- [x] **Báo cáo kỳ** — CĐPS/KQKD/CSV khớp sổ (`period-reports.e2e`); Flutter ledger + **Sổ quỹ kỳ**
- [x] Closeout gate: `docs/superpowers/plans/2026-07-25-phase2-hardening.md` (PASS 2026-07-25)

## API surface (Phase 1)

| Area | Endpoints |
|------|-----------|
| Health | `GET /health` |
| Auth | `POST /auth/login` |
| Stores | `GET /stores` |
| Shifts | `POST /shifts/open`, `POST /shifts/:id/close` |
| Sync | `GET /sync/pull`, `POST /sync/push` |
| Customers | `POST /customers`, `GET /customers?withDebt=true` |
| Reports | `GET /reports/day?date=YYYY-MM-DD&storeId=` |
| Devices | `POST /devices/push-token`, `POST /devices/low-stock-alert` |
| Stores | `PATCH /stores/:id/debt-overdue-days`, `PATCH /stores/:id/vat` |

## API surface (Phase 2–3)

| Area | Endpoints |
|------|-----------|
| Ledger | `GET /ledger/journal`, `GET /ledger/trial-balance`, `GET|POST /ledger/period-locks` |
| Suppliers / AP | `GET|POST /suppliers`, `GET /suppliers/:id/payables`, `POST /suppliers/:id/payments`, `GET|POST /suppliers/bank-accounts` |
| E-invoice | `POST /einvoices/issue`, `GET /einvoices/by-sale/:saleId` |
| Period reports | `GET /reports/period/trial-balance|pnl|vat|export.*` (`storeId` optional), `GET /reports/cash-fund` |
| Bank recon | `POST /reports/bank-recon/import`, `GET /reports/bank-recon` (read-only), `POST .../match|unmatch|auto-match|lock` |
| Suppliers | `POST /suppliers/:id/returns` (requires `purchaseReceiptId`), `GET /suppliers/:id/returnable-receipts` |

### Optional FCM (default off for day 1)

- **Default:** FCM off — no `FIREBASE_SERVICE_ACCOUNT`, placeholder `firebase_options.dart`; app and API run normally.
- **Enable later:** `docs/ops/fcm.md` — `flutterfire configure` + absolute-path `FIREBASE_SERVICE_ACCOUNT` on API host only.

### Optional e-invoice HTTP gateway

- Default: `EINVOICE_PROVIDER=stub` (local / e2e).
- Production-style: `EINVOICE_PROVIDER=http`, `EINVOICE_HTTP_URL=https://…/issue`, optional `EINVOICE_HTTP_API_KEY`. Operator checklist: `docs/ops/einvoice-http.md`; adapter spec: `docs/superpowers/specs/2026-07-25-phase3-einvoice-http-design.md`.

## Out of scope (this MVP)

See `docs/superpowers/plans/2026-07-23-phase1-remaining.md` for Phase 1 checklist.  
**Phase 3:** Feature track Done (PR #12–#16). Production closeout / hardening: see `docs/superpowers/plans/2026-07-25-phase3-hardening.md` (store-scoped period reports, net VAT, supplier return AP integrity, bank recon idempotency, HĐĐT HTTP timeout/retry). Nộp CQT tự động vẫn ngoài scope.

### Wave 1 ops (go-live)

| Topic | Doc |
|-------|-----|
| **Operator checklist (A.2–A.5)** | `docs/ops/go-live-checklist.md` |
| Deploy, migrate, backup, rollback | `docs/ops/production-deploy.md` |
| Secrets + real owner account | `docs/ops/production-secrets.md` |
| HĐĐT HTTP gateway / stub | `docs/ops/einvoice-http.md` |
| Android release signing + APK | `docs/ops/android-release.md` |
| Windows prod `API_URL` + smoke | `docs/ops/windows-prod.md` |

### Wave B ops (stable day 1–3)

| Topic | Doc |
|-------|-----|
| Multi-device smoke (required) | `docs/ops/smoke-multi-device.md` |
| FCM optional (default **off**) | `docs/ops/fcm.md` |

Host choice for Wave 1: Docker Compose (`apps/api/Dockerfile`, `apps/api/docker-compose.prod.yml`); live VPS execution is an operator follow-up when credentials are available.

Short path:

1. Create `apps/api/.env.production` on the host only; never commit real `DATABASE_URL`, `JWT_SECRET`, e-invoice keys, or backup files.
2. `cd apps/api && docker compose -f docker-compose.prod.yml build`.
3. Start PostgreSQL, run `npx prisma migrate deploy`, then start API as documented in `docs/ops/production-deploy.md`.
4. Schedule daily `pg_dump` backups with at least 7 retained copies and run a restore trial on staging.
5. Rollback schema by restoring the pre-deploy DB snapshot/dump and redeploying the previous app image/commit. Do not `migrate resolve` casually on production.
