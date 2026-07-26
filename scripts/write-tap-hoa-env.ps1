# Write/overwrite apps/api/.env with locked tap-hoa Supabase local values.
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
$Api = Join-Path $Root "apps\api"
$EnvFile = Join-Path $Api ".env"

$contents = @"
# AUTO-WRITTEN by scripts/write-tap-hoa-env.ps1 — tap-hoa Supabase local lock
# Do not point this at another project's DATABASE_URL. See docs/ops/local-dev.md
DATABASE_URL=postgresql://postgres:postgres@127.0.0.1:55422/tap_hoa?schema=public
JWT_SECRET=dev-change-me-tap-hoa
PORT=3040
"@

Set-Content -Path $EnvFile -Value $contents -Encoding utf8
Write-Host "[tap-hoa] Wrote locked apps/api/.env (DB tap_hoa @ 55422, PORT 3040)"
