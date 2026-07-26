# Tap Hoa POS (`pos_app`)

Flutter client for the **tap-hoa** monorepo.

Local API (locked): `http://127.0.0.1:3040`  
DB: Supabase project `tap-hoa` — see repo root [`docs/ops/local-dev.md`](../../docs/ops/local-dev.md).

```powershell
# From repo root first: .\scripts\dev-up.ps1 ; .\scripts\dev-setup.ps1 ; .\scripts\start-api.ps1
cd apps\pos_app
flutter pub get
flutter run -d windows --dart-define=API_URL=http://127.0.0.1:3040
```

Seed login: `0900000001` / `123456` (dev only).
