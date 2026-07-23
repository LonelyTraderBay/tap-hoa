# tap-hoa

Offline-first grocery POS monorepo (Phase 1 MVP).

| Path | Stack | Purpose |
|------|-------|---------|
| `apps/api` | NestJS 10, Prisma, PostgreSQL | Central API — auth, catalog sync, sales push, reports |
| `apps/pos_app` | Flutter 3, Drift/SQLite | POS client (Windows, Android, iOS) |

**Spec:** `docs/superpowers/specs/2026-07-23-tap-hoa-pos-ke-toan-design.md`  
**Implementation plan:** `docs/superpowers/plans/2026-07-23-phase1-foundation-pos.md`  
**Deferred Phase 1 items:** `docs/superpowers/plans/2026-07-23-phase1-remaining.md`

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

- [ ] **Login and select store** — sign in as `0900000001` / `123456`, pick CH1 or CH2
- [ ] **Open shift** — enter opening cash; cannot sell without an open shift
- [ ] **Pull products** — catalog sync shows STING-330 and stock qty for the selected store
- [ ] **Sell offline then sync** — disable network, complete a cash sale, re-enable network, run sync (auto timer, app resume, or manual **Đồng bộ**); sale appears on server
- [ ] **Second device sees new stock after pull** — after device A syncs a sale, device B pulls and stock qty decreases
- [ ] **Day report shows revenue** — `/reports/day` and in-app day report match sales for the store (owner sees consolidated total)
- [ ] **Debt sale increases customer balance after sync** — checkout with debt + customer selected; after push, customer balance increases on server and in debt list

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

## Out of scope (this MVP)

See `docs/superpowers/plans/2026-07-23-phase1-remaining.md` for deferred Phase 1 work (inventory transfers, cash in/out, debt payment history, thermal print, etc.).
