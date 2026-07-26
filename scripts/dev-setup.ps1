# Install deps, migrate, seed for tap-hoa API (Supabase local lock).
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
$Api = Join-Path $Root "apps\api"

# Always rewrite locked .env so shell env from other projects cannot stick in the file.
& (Join-Path $Root "scripts\write-tap-hoa-env.ps1")

Set-Location $Api
$EnvFile = Join-Path $Api ".env"

# Load .env into this process (overrides parent-shell DATABASE_URL).
Get-Content $EnvFile | ForEach-Object {
  if ($_ -match '^\s*#' -or $_ -match '^\s*$') { return }
  $name, $value = $_.Split('=', 2)
  if ($name -and $null -ne $value) {
    Set-Item -Path "Env:$name" -Value $value
  }
}
Write-Host "[tap-hoa] DATABASE_URL -> $($env:DATABASE_URL)"

Write-Host "[tap-hoa] npm install..."
npm install

Write-Host "[tap-hoa] prisma migrate deploy..."
npx prisma migrate deploy

Write-Host "[tap-hoa] prisma db seed..."
npx prisma db seed

Write-Host "[tap-hoa] Done. From repo root: .\scripts\start-api.ps1  (PORT 3040)"
Write-Host "[tap-hoa] Health: http://127.0.0.1:3040/health"
