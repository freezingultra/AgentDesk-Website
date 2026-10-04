$ErrorActionPreference = 'Stop'
$root = (Resolve-Path "$PSScriptRoot").Path
$buildDir = Join-Path $root ".agentdesk-build"
if (Test-Path $buildDir) { Remove-Item $buildDir -Recurse -Force }
New-Item -ItemType Directory -Path $buildDir | Out-Null
New-Item -ItemType Directory -Path (Join-Path $buildDir "web") | Out-Null

$files = @{
  "main.go.txt" = "main.go"
  "agent_tools.go.txt" = "agent_tools.go"
  "local_engine.go.txt" = "local_engine.go"
  "parallel_mcp.go.txt" = "parallel_mcp.go"
  "process_other.go.txt" = "process_other.go"
  "process_windows.go.txt" = "process_windows.go"
  "main_test.go.txt" = "main_test.go"
  "go.mod.txt" = "go.mod"
}
foreach ($item in $files.GetEnumerator()) { Copy-Item (Join-Path $root "source\$($item.Key)") (Join-Path $buildDir $item.Value) }
Copy-Item (Join-Path $root "source\web-index.html.txt") (Join-Path $buildDir "web\index.html")
Copy-Item (Join-Path $root "source\web-app.js.txt") (Join-Path $buildDir "web\app.js")
Copy-Item (Join-Path $root "source\web-style.css.txt") (Join-Path $buildDir "web\style.css")
Copy-Item (Join-Path $root "source\LICENSE-SOURCE-AVAILABLE.md.txt") (Join-Path $buildDir "LICENSE-SOURCE-AVAILABLE.md")

Push-Location $buildDir
try {
  if (-not (Get-Command go -ErrorAction SilentlyContinue)) { throw "Go is required." }
  $env:CGO_ENABLED = "0"
  go test ./...
  $env:GOOS = "windows"
  $env:GOARCH = "amd64"
  go build -trimpath -ldflags='-H=windowsgui -s -w' -o AgentDesk.exe .
  if (-not (Test-Path .\AgentDesk.exe)) { throw "AgentDesk.exe was not created." }
  Write-Host "Build complete: AgentDesk.exe ($([math]::Round((Get-Item .\AgentDesk.exe).Length / 1MB, 2)) MB)"
  $iscc = "C:\Program Files (x86)\Inno Setup 6\ISCC.exe"
  if (Test-Path $iscc) {
    New-Item -ItemType Directory -Path (Join-Path $buildDir "release-assets") -Force | Out-Null
    Copy-Item .\AgentDesk.exe (Join-Path $buildDir "release-assets\AgentDesk-v38.0.exe") -Force
    Copy-Item (Join-Path $root "source\installer-AgentDesk.iss.txt") (Join-Path $buildDir "installer-AgentDesk.iss") -Force
    $iss = Get-Content (Join-Path $buildDir "installer-AgentDesk.iss") -Raw
    $iss = $iss.Replace('..\release-assets\AgentDesk-v38.0.exe','release-assets\AgentDesk-v38.0.exe').Replace('..\LICENSE-SOURCE-AVAILABLE.md','LICENSE-SOURCE-AVAILABLE.md').Replace('..\release-assets','release-assets')
    Set-Content (Join-Path $buildDir "installer-AgentDesk.iss") $iss -NoNewline
    & $iscc (Join-Path $buildDir "installer-AgentDesk.iss")
    Write-Host "Installer build complete."
  }
} finally { Pop-Location }
