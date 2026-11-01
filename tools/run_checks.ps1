param(
    [string]$Godot = "C:\Users\ASUS\My Tools\Godot\4.6.3\Godot_v4.6.3-stable_win64.exe"
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot
$previousAppData = $env:APPDATA
try {
    $env:APPDATA = Join-Path $projectRoot ".test-data"
    New-Item -ItemType Directory -Path $env:APPDATA -Force | Out-Null
    & $Godot --headless --path $projectRoot res://tests/release_checks.tscn
    $checkExitCode = $LASTEXITCODE
} finally {
    $env:APPDATA = $previousAppData
}
exit $checkExitCode
