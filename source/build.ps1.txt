$ErrorActionPreference = 'Stop'
if (-not (Get-Command go -ErrorAction SilentlyContinue)) { throw "Go is required. Install Go and rerun this script." }
$env:GOOS=''; $env:GOARCH=''; $env:CGO_ENABLED='0'
go test ./...
$env:GOOS='windows'; $env:GOARCH='amd64'; $env:CGO_ENABLED='0'
go build -trimpath -ldflags='-H=windowsgui -s -w' -o AgentDesk.exe .
if (-not (Test-Path .\AgentDesk.exe)) { throw "Build completed but AgentDesk.exe was not created." }
Write-Host "Built AgentDesk V38.exe ($([math]::Round((Get-Item .\AgentDesk.exe).Length / 1MB, 2)) MB)"