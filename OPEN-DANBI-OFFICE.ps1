$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$index = Join-Path $here "index.html"
if (-not (Test-Path $index)) {
  Write-Host "index.html not found: $index"
  Read-Host "Press Enter to exit"
  exit 1
}
Start-Process $index
