# Supabase local — project `tap-hoa`

Tracked `config.toml` sets `project_id = "tap-hoa"` and ports in the **5542x** range
so this stack does not collide with another repo using default Supabase `:54322`.

```powershell
cd apps/api
npx supabase start
..\..\scripts\ensure-tap-hoa-db.ps1
```

Prisma `DATABASE_URL` must use database **`tap_hoa`** on port **55422**.
See `docs/ops/local-dev.md`.
