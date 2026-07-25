# Production secrets and owner account

Wave 1 go-live checklist for `apps/api`. Do not commit real production secrets,
passwords, API keys, or host-specific values to git. Store them on the
production host environment or in the deployment secret manager.

## 1. Generate `JWT_SECRET`

Generate a strong random value on the operator machine:

```powershell
[Convert]::ToBase64String((1..48 | ForEach-Object { Get-Random -Maximum 256 }) -as [byte[]])
```

Set the generated value as `JWT_SECRET` on the production host. Do not paste it
into `.env.example`, README, issue trackers, chat, or commits.

`apps/api/src/auth/jwt.config.ts` allows the fallback value `dev-change-me` only
when `NODE_ENV=development`. In production, missing `JWT_SECRET` fails startup,
so verify this host env key before starting the API.

## 2. Minimum production environment

Set at least these keys on the production host:

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

Notes:

- `DATABASE_URL` must point at the migrated production PostgreSQL database.
- `EINVOICE_HTTP_URL` and `EINVOICE_HTTP_API_KEY` are required only when real
  e-invoice issuance is enabled with `EINVOICE_PROVIDER=http`.
- Keep `FIREBASE_SERVICE_ACCOUNT` as an absolute file path. The JSON file itself
  is a secret and must stay outside git.

## 3. Create the real owner user after migrations

After deploying code and running production migrations:

```powershell
cd apps/api
npx prisma migrate deploy
$env:OWNER_PHONE="<real owner phone>"
$env:OWNER_PASSWORD="<strong one-time password>"
npm run create-owner
Remove-Item Env:OWNER_PHONE
Remove-Item Env:OWNER_PASSWORD
```

The script `apps/api/prisma/create-owner.ts` creates or updates the owner from
`OWNER_PHONE` and `OWNER_PASSWORD`, sets `role=owner`, and re-activates the
account. It never hardcodes the password and refuses the seed password `123456`.

Run it once for the real owner account, then unset the env vars from the shell,
CI job, or host session. If a deployment system stores one-shot task env vars,
delete them after the command succeeds.

## 4. Remove seed credentials from production

Do not use `npx prisma db seed` to create the production owner. If the seed was
ever run against production, immediately remove or rotate the seed account:

- Seed phone: `0900000001`
- Seed password: `123456`

Recommended cleanup after creating the real owner:

```sql
-- Option A: disable the seed user
UPDATE "User" SET active = false WHERE phone = '0900000001';

-- Option B: if the account must remain, rotate it to a strong unknown password
-- with apps/api/prisma/create-owner.ts or a controlled SQL/Prisma operation.
```

## 5. Production smoke check

After the host has the env keys above and the API is running:

```powershell
Invoke-RestMethod http://<prod-host>:3000/health
```

Expected response:

```json
{ "ok": true }
```

If there is no live production host yet, keep this as an operator follow-up for
the first deployment window.
