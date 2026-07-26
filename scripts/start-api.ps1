# Start Nest API using locked tap-hoa Supabase .env (overrides shell DATABASE_URL).
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
$Api = Join-Path $Root "apps\api"
& (Join-Path $Root "scripts\write-tap-hoa-env.ps1")
$EnvFile = Join-Path $Api ".env"
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
