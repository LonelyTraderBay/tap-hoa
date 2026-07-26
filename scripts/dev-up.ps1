# Start tap-hoa local Postgres via Supabase CLI only (project_id = tap-hoa).
# Locked ports 5542x — see apps/api/supabase/config.toml and docs/ops/local-dev.md
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
$Api = Join-Path $Root "apps\api"
$dockerBin = "C:\Program Files\Docker\Docker\resources\bin"
if (Test-Path $dockerBin) {
  $env:Path = "$dockerBin;" + $env:Path
}

Write-Host "[tap-hoa] Local DB = Supabase only (project_id=tap-hoa, Postgres :55422 / DB tap_hoa)"

# Stop legacy docker-compose.dev Postgres if it still holds :55422
$legacy = docker ps -q --filter "name=tap-hoa-db" 2>$null
if ($legacy) {
  Write-Host "[tap-hoa] Stopping legacy container tap-hoa-db so Supabase can bind :55422..."
  Set-Location $Root
  if (Test-Path (Join-Path $Root "docker-compose.dev.yml")) {
    docker compose -f docker-compose.dev.yml down 2>$null
  } else {
    docker stop tap-hoa-db 2>$null
  }
}

Set-Location $Api
Write-Host "[tap-hoa] npx supabase start (project_id from config.toml)..."
npx supabase start
& (Join-Path $Root "scripts\ensure-tap-hoa-db.ps1")
& (Join-Path $Root "scripts\write-tap-hoa-env.ps1")

Write-Host "[tap-hoa] Studio: http://127.0.0.1:55423"
Write-Host "[tap-hoa] DATABASE_URL must be postgresql://postgres:***@127.0.0.1:55422/tap_hoa?schema=public"
Write-Host "[tap-hoa] Next: .\scripts\dev-setup.ps1 then .\scripts\start-api.ps1"
