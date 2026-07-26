# Local development — identity `tap-hoa`

Use this when developing **multiple projects** on one PC. Everything below is
namespaced to the folder / product name **tap-hoa** so ports, DB, Docker, and
window titles do not collide with other repos.

## Identity map

| Concern | Value |
|---------|--------|
| Repo folder | `tap-hoa` |
| Nest package | `tap-hoa-api` |
| Postgres database | `tap_hoa` |
| Postgres user (Docker) | `tap_hoa` / `tap_hoa_dev` |
| Nest API port | **3040** |
| Postgres host port | **55422** |
| Supabase `project_id` | `tap-hoa` |
| Supabase Studio | http://127.0.0.1:55423 |
| POS display name | **Tap Hoa POS** |
| Local SQLite | `tap_hoa_pos.sqlite` |
| Docker Compose project | `tap-hoa` (`docker-compose.dev.yml`) |
| Prod Compose project | `tap-hoa` (`apps/api/docker-compose.prod.yml`) |

## Preferred DB: Docker Compose (when Docker Desktop is installed)

```powershell
cd C:\Users\C-PC\Documents\Projects\tap-hoa
.\scripts\dev-up.ps1
.\scripts\dev-setup.ps1
```

`apps/api/.env` (from `.env.example`):

```env
DATABASE_URL=postgresql://tap_hoa:tap_hoa_dev@127.0.0.1:55422/tap_hoa?schema=public
JWT_SECRET=dev-change-me-tap-hoa
PORT=3040
```

## Alternate DB: Supabase CLI (unique ports for this project)

Config is tracked at `apps/api/supabase/config.toml` (`project_id = "tap-hoa"`).
Ports are offset from the Supabase defaults so another project can keep `:54322`.

```powershell
cd apps/api
npx supabase start
.\..\..\scripts\ensure-tap-hoa-db.ps1
```

Then:

```env
DATABASE_URL=postgresql://postgres:postgres@127.0.0.1:55422/tap_hoa?schema=public
JWT_SECRET=dev-change-me-tap-hoa
PORT=3040
```

Stop: `npx supabase stop` (from `apps/api`).

## API + POS

```powershell
# Prefer wrapper so shell DATABASE_URL from other projects cannot override .env:
.\scripts\start-api.ps1
# → http://127.0.0.1:3040/health

cd apps/pos_app
flutter run -d windows --dart-define=API_URL=http://127.0.0.1:3040
```

| Platform | `API_URL` |
|----------|-----------|
| Windows / iOS sim | `http://127.0.0.1:3040` |
| Android emulator | `http://10.0.2.2:3040` |

**Seed login (dev only):** `0900000001` / `123456`

## Port cheat sheet (tap-hoa only)

| Port | Service |
|------|---------|
| 3040 | Nest API |
| 55420 | Supabase shadow DB |
| 55421 | Supabase API |
| 55422 | PostgreSQL (`tap_hoa`) |
| 55423 | Supabase Studio |
| 55424 | Supabase Inbucket |
| 55427 | Supabase analytics |
| 55429 | Supabase pooler |
| 18083 | Edge inspector |

## Do not

- Point this app at another project's `postgres` DB on `:54322` / `:5432`
- Commit `apps/api/.env` or real JWT / owner passwords
- Reuse Compose project name `api` (old default from folder name)
- Leave a global/shell `DATABASE_URL` from another project — it **overrides** `apps/api/.env`. Prefer `.\scripts\dev-setup.ps1` (loads `.env` into the process) or clear the variable first:

```powershell
Remove-Item Env:DATABASE_URL -ErrorAction SilentlyContinue
```
