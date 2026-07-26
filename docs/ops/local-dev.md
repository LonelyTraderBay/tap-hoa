# Local development — identity `tap-hoa` (Supabase only)

Local PostgreSQL for this repo is **Supabase CLI only**, with `project_id = "tap-hoa"`
locked in `apps/api/supabase/config.toml` and enforced in Nest by
`apps/api/src/config/tap-hoa.identity.ts`.

This avoids colliding with other projects that use default Supabase `:54322` or a
shared `postgres` database.

## Quick start

```powershell
cd C:\Users\C-PC\Documents\Projects\tap-hoa
.\scripts\dev-up.ps1      # supabase start + create DB tap_hoa + write .env
.\scripts\dev-setup.ps1   # migrate + seed
.\scripts\start-api.ps1   # Nest :3040 (loads .env; rejects foreign DATABASE_URL)
```

POS:

```powershell
cd apps\pos_app
flutter run -d windows --dart-define=API_URL=http://127.0.0.1:3040
```

IDE: `.vscode/launch.json` — **API (tap-hoa :3040)** / **Flutter POS (tap-hoa)**.

## Locked identity map

| Concern | Locked value |
|---------|----------------|
| Supabase `project_id` | `tap-hoa` |
| Postgres database | `tap_hoa` (never bare `postgres`) |
| Postgres host port | **55422** |
| Nest API port | **3040** |
| Schema | `public` |
| Studio | http://127.0.0.1:55423 |
| POS title | **Tap Hoa POS** |
| Local SQLite | `tap_hoa_pos.sqlite` |
| Nest package | `tap-hoa-api` |

`apps/api/.env` (auto-written by `write-tap-hoa-env.ps1`):

```env
DATABASE_URL=postgresql://postgres:postgres@127.0.0.1:55422/tap_hoa?schema=public
JWT_SECRET=dev-change-me-tap-hoa
PORT=3040
```

## Identity lock in code

On API boot (when `NODE_ENV` ≠ `production`), Nest calls `assertTapHoaLocalIdentity()`:

- Rejects port `54322` / `5432` (shared defaults)
- Requires DB name `tap_hoa`, schema `public`, host localhost, port `55422`
- Requires `PORT=3040`

Override only for special tooling: `TAP_HOA_SKIP_LOCAL_IDENTITY=1`  
Production: set `NODE_ENV=production` (lock skipped).

## Docker PATH (Windows)

Supabase CLI still needs Docker Desktop. `dev-up.ps1` prepends
`C:\Program Files\Docker\Docker\resources\bin` when present.

## Stop local stack

```powershell
cd apps\api
npx supabase stop
```

## Port cheat sheet (tap-hoa only)

| Port | Service |
|------|---------|
| 3040 | Nest API |
| 55420 | Supabase shadow DB |
| 55421 | Supabase API |
| 55422 | PostgreSQL (`tap_hoa`) |
| 55423 | Supabase Studio |
| 55424 | Inbucket |
| 55427 | Analytics |
| 55429 | Pooler |
| 18083 | Edge inspector |

## Do not

- Use `docker-compose.dev.yml` for local DB (deprecated stub)
- Point at another project's `:54322` or schema (e.g. `taskd_*`)
- Leave shell `DATABASE_URL` from another repo — scripts rewrite/load `.env`, and Nest will refuse a mismatch
- Commit `apps/api/.env`

Smoke: `docs/ops/local-smoke.md`
