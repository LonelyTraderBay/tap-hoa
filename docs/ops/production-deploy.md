# Production deploy, migrate, backup, and rollback runbook

Wave 1 go-live uses Docker Compose for the `apps/api` service and PostgreSQL.
This repository contains deploy artifacts only; a live VPS deployment remains an
operator follow-up when host credentials are available. Never commit real
production secrets, passwords, API keys, or backup files.

See also:

- `docs/ops/production-secrets.md` — `JWT_SECRET`, e-invoice keys, owner account
- `docs/ops/einvoice-http.md` — HĐĐT HTTP gateway vs stub operator checklist
- `docs/ops/android-release.md` — Android release signing and APK
- `docs/ops/windows-prod.md` — Windows prod `API_URL`, build, operator smoke
- `docs/ops/npm-audit.md` — periodic `npm audit --omit=dev` tracking (no `--force`)

## 1. Host choice

- API image: `apps/api/Dockerfile`
- Production compose stub: `apps/api/docker-compose.prod.yml` (`name: tap-hoa`)
- Runtime env file on the host only: `apps/api/.env.production`
- Local multi-project isolation: `docs/ops/local-dev.md` (dev uses host port **3040** / DB **tap_hoa**)

Minimum host requirements:

- Docker Engine with Compose v2
- Disk space for PostgreSQL data and at least 7 retained backups
- Port `API_PORT` (default **3040**) exposed only to the trusted network or reverse proxy
  (container still listens on `PORT=3000` inside the image)

## 2. Prepare production env

Create `apps/api/.env.production` on the production host. This file is ignored
by Docker context rules and must stay outside git.

```env
NODE_ENV=production
PORT=3000
API_PORT=3040

`API_PORT` in `docker-compose.prod.yml` is the **host** publish port (default 3040 for tap-hoa identity). Inside the container keep `PORT=3000`. Compose resolves `API_PORT` from the host (`.env` beside the compose file, shell export, or `--env-file`), not only from variables inside `.env.production` loaded into the container.

POSTGRES_DB=tap_hoa
POSTGRES_USER=tap_hoa_app
POSTGRES_PASSWORD=<strong-postgres-password>
DATABASE_URL=postgresql://tap_hoa_app:<strong-postgres-password>@db:5432/tap_hoa?schema=public

JWT_SECRET=<strong-random-secret>

# Optional for real e-invoice issuance (see docs/ops/einvoice-http.md):
# EINVOICE_PROVIDER=http
# EINVOICE_HTTP_URL=https://...
# EINVOICE_HTTP_API_KEY=<secret>
# EINVOICE_HTTP_TIMEOUT_MS=15000
# Default / no gateway: EINVOICE_PROVIDER=stub (chưa HĐĐT thật)

# Optional FCM:
# FIREBASE_SERVICE_ACCOUNT=/run/secrets/tap-hoa-firebase.json
```

Generate and handle secrets according to `docs/ops/production-secrets.md`.

## 3. First deploy and migrate

From the checked-out repo on the host:

```sh
cd apps/api
docker compose -f docker-compose.prod.yml build
docker compose -f docker-compose.prod.yml up -d db
docker compose -f docker-compose.prod.yml run --rm api npx prisma migrate deploy
docker compose -f docker-compose.prod.yml up -d api
```

The API image also runs `npx prisma migrate deploy` before `node dist/main.js`,
so restarts apply any pending committed migrations before serving traffic.

Create the real owner account after migrations:

```sh
cd apps/api
export OWNER_PHONE="<real owner phone>"
export OWNER_PASSWORD="<strong one-time password>"
docker compose -f docker-compose.prod.yml run --rm \
  -e OWNER_PHONE="$OWNER_PHONE" \
  -e OWNER_PASSWORD="$OWNER_PASSWORD" \
  api node dist/prisma/create-owner.js
```

(`npm run create-owner` invokes `ts-node`, which fails inside this image —
`tsconfig.json` isn't copied into the runtime stage. Run the compiled output
directly instead; `npm run create-owner` still works when run outside Docker
against a full repo checkout, e.g. the PowerShell flow in
`production-secrets.md`.)

Then disable or rotate any seed account as described in
`docs/ops/production-secrets.md`.

Smoke check:

```sh
curl http://<prod-host>:3040/health
```

Expected:

```json
{ "ok": true }
```

(Use your reverse-proxy HTTPS URL in production; `3040` is the Compose default host port.)

## 4. Daily PostgreSQL backup

Back up with `pg_dump` every day and retain at least 7 successful backups.
Backups contain customer, sale, debt, and accounting data; store them encrypted
or on restricted storage.

Example Linux cron entry:

```cron
15 2 * * * cd /srv/tap-hoa/apps/api && mkdir -p /var/backups/tap-hoa && docker compose -f docker-compose.prod.yml exec -T db sh -c 'pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" -Fc' > /var/backups/tap-hoa/tap_hoa_$(date +\%F).dump && find /var/backups/tap-hoa -name 'tap_hoa_*.dump' -type f -mtime +7 -delete
```

Operator checklist:

1. Confirm a new dump file is created daily and is non-empty.
2. Copy backups to storage outside the VPS.
3. Run a restore trial on staging before go-live and after schema-heavy releases.

Restore trial on staging:

```sh
cd apps/api
docker compose -f docker-compose.prod.yml exec -T db sh -c 'createdb -U "$POSTGRES_USER" tap_hoa_restore'
docker compose -f docker-compose.prod.yml exec -T db sh -c 'pg_restore -U "$POSTGRES_USER" -d tap_hoa_restore --clean --if-exists' < /path/to/tap_hoa_YYYY-MM-DD.dump
docker compose -f docker-compose.prod.yml run --rm -e DATABASE_URL="postgresql://tap_hoa_app:<password>@db:5432/tap_hoa_restore?schema=public" api npx prisma migrate deploy
```

If restore validation fails, stop the deployment window until the failure is
understood.

## 5. 15-minute rollback drill

Before each production migration window:

1. Record the current git commit, image tag, and latest verified backup path.
2. Take a fresh pre-deploy backup or provider snapshot.
3. Confirm the previous image or commit can still be started.

Rollback steps:

```sh
cd apps/api
docker compose -f docker-compose.prod.yml stop api
# Restore the pre-deploy database snapshot/dump according to the host backup tool.
# Then redeploy the previous image or checkout the previous commit and rebuild:
docker compose -f docker-compose.prod.yml build api
docker compose -f docker-compose.prod.yml up -d api
curl http://<prod-host>:3040/health
```

Do not casually run `prisma migrate resolve` on production. Use it only after a
documented incident review identifies the exact migration state and recovery
path.
