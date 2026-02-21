$ErrorActionPreference = 'Stop'

Write-Host "Restarting AeroCommand dev stack..." -ForegroundColor Cyan

$dockerCmd = Get-Command docker -ErrorAction SilentlyContinue
if (-not $dockerCmd) {
  Write-Host "Docker CLI not found. Start Docker Desktop and ensure it is on PATH." -ForegroundColor Red
  Write-Host "Expected path: C:\Program Files\Docker\Docker\resources\bin" -ForegroundColor Yellow
  exit 1
}

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
Set-Location $repoRoot

docker compose down

docker compose up -d --build

Write-Host "Dev stack restarted." -ForegroundColor Green
Write-Host "Dashboard: http://localhost:3000" -ForegroundColor Green
Write-Host "API:       http://localhost:8000 (health: /health/ready)" -ForegroundColor Green
Write-Host "EMQX:      http://localhost:18083 (admin / aerocommand_emqx_admin)" -ForegroundColor Green
