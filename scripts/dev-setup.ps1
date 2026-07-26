# Install deps, migrate, seed for tap-hoa API.
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
$Api = Join-Path $Root "apps\api"
Set-Location $Api

$EnvFile = Join-Path $Api ".env"
$Example = Join-Path $Api ".env.example"
if (-not (Test-Path $EnvFile)) {
  Copy-Item $Example $EnvFile
  Write-Host "[tap-hoa] Created apps/api/.env from .env.example"
} else {
  Write-Host "[tap-hoa] Using existing apps/api/.env"
}

# Other projects may export DATABASE_URL in the parent shell — that OVERRIDES .env.
# Always load tap-hoa values from apps/api/.env explicitly.
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
