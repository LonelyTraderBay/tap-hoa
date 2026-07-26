# Create database tap_hoa on local Supabase Postgres (project_id tap-hoa) if missing.
$ErrorActionPreference = "Stop"
$Container = "supabase_db_tap-hoa"
$Db = "tap_hoa"

Write-Host "[tap-hoa] Ensuring database '$Db' in container '$Container' ..."

$running = docker ps --format '{{.Names}}' 2>$null | Where-Object { $_ -eq $Container }
if (-not $running) {
  Write-Error "[tap-hoa] Container '$Container' not running. Start with: cd apps/api; npx supabase start"
}

$exists = docker exec $Container psql -U postgres -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='$Db'"
if (($exists | Out-String).Trim() -ne "1") {
  docker exec $Container psql -U postgres -d postgres -c "CREATE DATABASE $Db;"
  Write-Host "[tap-hoa] Created database $Db"
} else {
  Write-Host "[tap-hoa] Database $Db already exists"
}
