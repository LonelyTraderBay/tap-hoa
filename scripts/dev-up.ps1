# Start tap-hoa local Postgres (Docker preferred).
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
Set-Location $Root

# Docker Desktop on Windows often installs docker.exe off PATH for non-interactive shells.
$dockerBin = "C:\Program Files\Docker\Docker\resources\bin"
if (Test-Path $dockerBin) {
  $env:Path = "$dockerBin;" + $env:Path
}

function Test-Docker {
  try {
    docker version --format '{{.Server.Version}}' 2>$null | Out-Null
    return $LASTEXITCODE -eq 0
  } catch {
    return $false
  }
}

if (Test-Docker) {
  Write-Host "[tap-hoa] Starting Docker Compose project 'tap-hoa' (Postgres :55422 / DB tap_hoa)..."
  docker compose -f docker-compose.dev.yml up -d
  Write-Host "[tap-hoa] Waiting for health..."
  $ok = $false
  for ($i = 0; $i -lt 30; $i++) {
    Start-Sleep -Seconds 1
    $status = docker inspect -f '{{.State.Health.Status}}' tap-hoa-db 2>$null
    if ($status -eq 'healthy') { $ok = $true; break }
  }
  if (-not $ok) {
    Write-Warning "[tap-hoa] Container started but health not confirmed yet. Check: docker ps"
  } else {
    Write-Host "[tap-hoa] DB ready: postgresql://tap_hoa:***@127.0.0.1:55422/tap_hoa"
  }
  exit 0
}

Write-Host "[tap-hoa] Docker not found. Falling back to Supabase CLI (project_id tap-hoa, ports 5542x)..."
Set-Location (Join-Path $Root "apps\api")
npx supabase start
& (Join-Path $Root "scripts\ensure-tap-hoa-db.ps1")
