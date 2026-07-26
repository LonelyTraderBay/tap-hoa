# Start Nest API using apps/api/.env (overrides any shell DATABASE_URL from other projects).
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
$Api = Join-Path $Root "apps\api"
$EnvFile = Join-Path $Api ".env"
if (-not (Test-Path $EnvFile)) {
  Copy-Item (Join-Path $Api ".env.example") $EnvFile
}
Get-Content $EnvFile | ForEach-Object {
  if ($_ -match '^\s*#' -or $_ -match '^\s*$') { return }
  $name, $value = $_.Split('=', 2)
  if ($name -and $null -ne $value) {
    Set-Item -Path "Env:$name" -Value $value
  }
}
Write-Host "[tap-hoa] PORT=$env:PORT DATABASE=$($env:DATABASE_URL -replace ':[^:@/]+@', ':***@')"
Set-Location $Api
npm run start:dev
