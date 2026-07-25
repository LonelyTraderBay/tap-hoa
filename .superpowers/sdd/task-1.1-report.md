# Task 1.1 Report: Secrets & tài khoản prod

## Status

DONE_WITH_CONCERNS

In-repo artifacts are complete. Concern is limited to live production host
application/verification because no live production host was available in this
environment.

## Summary

- Added `docs/ops/production-secrets.md` with the exact JWT generation command,
  minimum production env checklist, owner bootstrap steps, seed credential
  cleanup guidance, and production `/health` follow-up.
- Added one-shot Prisma script `apps/api/prisma/create-owner.ts` using
  `OWNER_PHONE` and `OWNER_PASSWORD`.
- Added `npm run create-owner` under `apps/api`.
- Expanded `apps/api/.env.example` with production JWT guidance and commented
  `EINVOICE_*` keys.
- No real secrets, passwords, API keys, or production URLs were committed.

## Files changed

- `apps/api/.env.example`
- `apps/api/package.json`
- `apps/api/prisma/create-owner.ts`
- `docs/ops/production-secrets.md`
- `.superpowers/sdd/task-1.1-report.md`

## Implementation notes

### JWT secret

Documented the required PowerShell command exactly:

```powershell
[Convert]::ToBase64String((1..48 | ForEach-Object { Get-Random -Maximum 256 }) -as [byte[]])
```

The ops doc and `.env.example` both point out that
`apps/api/src/auth/jwt.config.ts` rejects a missing `JWT_SECRET` outside
`NODE_ENV=development`.

### Owner account

`apps/api/prisma/create-owner.ts`:

- requires `OWNER_PHONE`;
- requires `OWNER_PASSWORD`;
- rejects the known seed password `123456`;
- hashes the supplied password with bcrypt;
- creates or updates the user as `Role.owner`;
- sets `active=true`;
- logs only non-secret account metadata.

Operator command documented:

```powershell
cd apps/api
npx prisma migrate deploy
$env:OWNER_PHONE="<real owner phone>"
$env:OWNER_PASSWORD="<strong one-time password>"
npm run create-owner
Remove-Item Env:OWNER_PHONE
Remove-Item Env:OWNER_PASSWORD
```

### Seed credential cleanup

Documented that production must not rely on seed user `0900000001` / `123456`,
and if seed ever ran on production the seed account must be disabled or rotated.

### Minimum production env checklist

Documented:

```env
NODE_ENV=production
DATABASE_URL=postgresql://...
JWT_SECRET=<random>
PORT=3000
# Nếu xuất HĐĐT thật ngày 1:
EINVOICE_PROVIDER=http
EINVOICE_HTTP_URL=https://...
EINVOICE_HTTP_API_KEY=...
EINVOICE_HTTP_TIMEOUT_MS=15000
# Optional FCM:
# FIREBASE_SERVICE_ACCOUNT=/absolute/path/sa.json
```

## Verification

Commands run from `apps/api` unless noted:

```powershell
npm ci
npx prisma generate
npm run build
```

Result: PASS. `npm run build` passed after generating Prisma client types.

Production-mode local health smoke:

```powershell
$env:NODE_ENV = "production"
$env:JWT_SECRET = "local-smoke-secret-not-prod"
$env:PORT = "3101"
node dist/src/main.js
Invoke-RestMethod http://127.0.0.1:3101/health
```

Result: PASS with response `{"ok":true}` using the local `.env` database
configuration. The temporary process was stopped after the check.

Owner script safety checks:

```powershell
npm run create-owner
```

Result: expected failure before DB work: `OWNER_PHONE is required`.

```powershell
$env:OWNER_PHONE = "0900000001"
$env:OWNER_PASSWORD = "123456"
npm run create-owner
```

Result: expected failure before DB work:
`OWNER_PASSWORD must not use the seed password 123456`.

Notes:

- First `/health` attempt with the sample `.env.example` database URL failed
  because local PostgreSQL credentials at `localhost:5432` were not valid.
  Retrying without overriding `DATABASE_URL` allowed the app to use the local
  repo `.env` and pass.
- `npm ci` reported existing audit warnings and allow-scripts warnings; no new
  dependencies or dependency versions were added by this task.

## Self-review

- Confirmed no committed value is a real secret or production host URL.
- Confirmed `.env.example` uses comments/placeholders only for production-only
  secret values.
- Confirmed create-owner script follows the existing Prisma/ts-node/bcrypt seed
  pattern.
- Confirmed owner role can operate without store links because owner bypasses
  store-scoped access checks in existing services.
- Confirmed live production host application and `/health` verification remain
  operator follow-up because no production host was available here.

## Working tree note

The unrelated untracked file
`docs/superpowers/plans/2026-07-25-hoan-thien-uu-tien.md` was present before this
task and was left untouched.
