# Bring up the "production" tap-hoa stack (docker-compose.prod.yml) locally
# on this machine, as a stand-in for a real VPS while there is none yet.
# Requires apps/api/.env.production to already exist (see docs/ops/production-deploy.md).
#
# API_PORT is exported here on purpose: docker-compose.prod.yml resolves
# ${API_PORT:-3040} for its host port mapping from Compose's own environment,
# NOT from .env.production's env_file values (documented gotcha in
# docs/ops/production-deploy.md, section 1). Fixed at 3041 to avoid colliding
# with the dev API's default port 3040 (docs/ops/local-dev.md) if both are
# ever run side by side.
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
$Api = Join-Path $Root "apps\api"
$dockerBin = "C:\Program Files\Docker\Docker\resources\bin"
if (Test-Path $dockerBin) {
  $env:Path = "$dockerBin;" + $env:Path
}

if (-not (Test-Path (Join-Path $Api ".env.production"))) {
  Write-Error "apps/api/.env.production not found. See docs/ops/production-deploy.md section 2."
  exit 1
}

$env:API_PORT = "3041"
Set-Location $Api

Write-Host "[tap-hoa-local-prod] Building API image..."
docker compose -f docker-compose.prod.yml build

Write-Host "[tap-hoa-local-prod] Starting db..."
docker compose -f docker-compose.prod.yml up -d db

Write-Host "[tap-hoa-local-prod] Waiting for db healthy..."
$attempts = 0
while ($attempts -lt 20) {
  $status = docker inspect --format='{{.State.Health.Status}}' tap-hoa-prod-db 2>$null
  if ($status -eq "healthy") { break }
  Start-Sleep -Seconds 2
  $attempts++
}
if ($status -ne "healthy") {
  Write-Error "db did not become healthy in time"
  exit 1
}

Write-Host "[tap-hoa-local-prod] Running migrations..."
docker compose -f docker-compose.prod.yml run --rm api npx prisma migrate deploy

Write-Host "[tap-hoa-local-prod] Starting api on host port $($env:API_PORT)..."
docker compose -f docker-compose.prod.yml up -d api

Write-Host "[tap-hoa-local-prod] Done. Health check: curl http://localhost:$($env:API_PORT)/health"
