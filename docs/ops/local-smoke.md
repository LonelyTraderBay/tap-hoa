# Local smoke — API health + seed login

Quick checks after `.\scripts\dev-up.ps1` and `.\scripts\dev-setup.ps1`. Start the
API with `.\scripts\start-api.ps1` (loads `apps/api/.env`; do not rely on a shell
`DATABASE_URL` from another project).

## Health

```powershell
Invoke-RestMethod http://127.0.0.1:3040/health
# Expected: ok = True  (JSON: { "ok": true })
```

```bash
curl -s http://127.0.0.1:3040/health
```

## Seed login (dev only)

Credentials: `0900000001` / `123456` (see README).

```powershell
$body = @{ phone = "0900000001"; password = "123456" } | ConvertTo-Json
Invoke-RestMethod -Uri http://127.0.0.1:3040/auth/login `
  -Method POST -Body $body -ContentType "application/json"
# Expected: accessToken + user (role owner, storeIds non-empty)
```

```bash
curl -s -X POST http://127.0.0.1:3040/auth/login \
  -H "Content-Type: application/json" \
  -d '{"phone":"0900000001","password":"123456"}'
```

## POS path (manual)

See [local-dev.md](local-dev.md#minimal-pos-smoke-local): login → chọn CH → mở ca →
bán TM → đồng bộ.
