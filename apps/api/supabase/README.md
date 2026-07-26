# Supabase local — **canonical** DB for `tap-hoa`

This is the **only** supported local Postgres for the tap-hoa API.

| Lock | Value |
|------|--------|
| `project_id` | `tap-hoa` |
| DB port | `55422` |
| Database name | `tap_hoa` (created by `scripts/ensure-tap-hoa-db.ps1`) |
| Nest guard | `src/config/tap-hoa.identity.ts` |

```powershell
# From repo root:
.\scripts\dev-up.ps1
```

Or manually:

```powershell
cd apps/api
npx supabase start
..\..\scripts\ensure-tap-hoa-db.ps1
..\..\scripts\write-tap-hoa-env.ps1
```

Studio: http://127.0.0.1:55423
