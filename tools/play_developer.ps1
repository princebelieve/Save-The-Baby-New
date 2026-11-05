param(
    [string]$Godot = "C:\Users\ASUS\My Tools\Godot\4.6.3\Godot_v4.6.3-stable_win64.exe"
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$previousAppData = $env:APPDATA
try {
    $env:APPDATA = Join-Path $projectRoot '.test-data/developer-play/manual'
    New-Item -ItemType Directory -Path $env:APPDATA -Force | Out-Null
    if (-not (Test-Path -LiteralPath $Godot)) { throw "Godot executable not found: $Godot" }
    # This is the visible interactive game requested by the developer.
    $player = Start-Process -FilePath $Godot -ArgumentList @('--path', "`"$projectRoot`"", '--', '--developer-tools') -PassThru
    $player.WaitForExit()
} finally {
    $env:APPDATA = $previousAppData
}
