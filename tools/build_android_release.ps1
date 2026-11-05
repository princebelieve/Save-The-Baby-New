param(
    [string]$Godot = "C:\Users\ASUS\My Tools\Godot\4.6.3\Godot_v4.6.3-stable_win64.exe",
    [string]$Java = "C:\Program Files\Microsoft\jdk-21.0.12.101-hotspot",
    [string]$AndroidSdk = "C:\Users\ASUS\Android\Sdk"
)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$version = [int]([regex]::Match((Get-Content (Join-Path $root 'export_presets.cfg') -Raw),'version/code=(\d+)').Groups[1].Value)
$bundle = Join-Path $root "build/android/SaveTheBaby-v$version.aab"
$outputLog = Join-Path $root ".test-data/android-v$version-output.log"
$errorLog = Join-Path $root ".test-data/android-v$version-error.log"
$old = @{APPDATA=$env:APPDATA; GRADLE_USER_HOME=$env:GRADLE_USER_HOME; JAVA_HOME=$env:JAVA_HOME; ANDROID_HOME=$env:ANDROID_HOME}
try {
    $env:APPDATA = Join-Path $root '.test-data/r8-release-editor'
    $env:GRADLE_USER_HOME = Join-Path $root '.gradle-cache'
    $env:JAVA_HOME = $Java
    $env:ANDROID_HOME = $AndroidSdk
    if (-not (Test-Path (Join-Path $env:APPDATA 'Godot/editor_settings-4.6.tres'))) { throw 'The isolated Android export editor profile is missing.' }
    $started = Get-Date
    $process = Start-Process -FilePath $Godot -ArgumentList @('--headless','--path',"`"$root`"",'--export-release','"Android AAB Release"',"`"$bundle`"") -WindowStyle Hidden -PassThru -RedirectStandardOutput $outputLog -RedirectStandardError $errorLog
    $process.Id | Set-Content (Join-Path $root '.test-data/android-export.pid')
    if (-not $process.WaitForExit(900000)) { $process.Kill(); throw 'Android export timed out.' }
    $process.WaitForExit()
    $errors = Get-Content $errorLog -Raw
    if ($errors -match 'SCRIPT ERROR:|Export failed|Failed to export' -or -not (Test-Path $bundle) -or (Get-Item $bundle).LastWriteTime -lt $started) {
        Get-Content $errorLog -Tail 20
        throw 'Android export did not produce a fresh successful bundle.'
    }
    Write-Output "Fresh Android bundle: $bundle"
} finally {
    foreach ($name in $old.Keys) { [Environment]::SetEnvironmentVariable($name,$old[$name],'Process') }
}
