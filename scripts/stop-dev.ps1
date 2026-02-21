$ErrorActionPreference = 'Stop'

Write-Host "Stopping AeroCommand dev stack..." -ForegroundColor Cyan

$dockerCmd = Get-Command docker -ErrorAction SilentlyContinue
if (-not $dockerCmd) {
  Write-Host "Docker CLI not found. Start Docker Desktop and ensure it is on PATH." -ForegroundColor Red
  Write-Host "Expected path: C:\Program Files\Docker\Docker\resources\bin" -ForegroundColor Yellow
  exit 1
}

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
Set-Location $repoRoot

docker compose down

Write-Host "Dev stack stopped." -ForegroundColor Green
