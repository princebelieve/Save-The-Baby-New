param(
    [string]$Godot = "C:\Users\ASUS\My Tools\Godot\4.6.3\Godot_v4.6.3-stable_win64.exe",
    [string]$Java = "C:\Program Files\Microsoft\jdk-21.0.12.101-hotspot",
    [string]$AndroidSdk = "C:\Users\ASUS\Android\Sdk"
)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$apk = Join-Path $root 'build/android/SaveTheBaby-Dev.apk'
$outputLog = Join-Path $root '.test-data/android-developer-output.log'
$errorLog = Join-Path $root '.test-data/android-developer-error.log'
$old = @{APPDATA=$env:APPDATA; GRADLE_USER_HOME=$env:GRADLE_USER_HOME; JAVA_HOME=$env:JAVA_HOME; ANDROID_HOME=$env:ANDROID_HOME}
try {
    $env:APPDATA = Join-Path $root '.test-data/r8-release-editor'
    $env:GRADLE_USER_HOME = Join-Path $root '.gradle-cache'
    $env:JAVA_HOME = $Java
    $env:ANDROID_HOME = $AndroidSdk
    $started = Get-Date
    $process = Start-Process -FilePath $Godot -ArgumentList @('--headless','--path',"`"$root`"",'--export-debug','"Android Developer APK"',"`"$apk`"") -WindowStyle Hidden -PassThru -RedirectStandardOutput $outputLog -RedirectStandardError $errorLog
    $process.Id | Set-Content (Join-Path $root '.test-data/android-developer-export.pid')
    if (-not $process.WaitForExit(900000)) { $process.Kill(); throw 'Developer Android export timed out.' }
    $process.WaitForExit()
    $errors = Get-Content $errorLog -Raw
    if ($errors -match 'SCRIPT ERROR:|Export failed|Failed to export' -or -not (Test-Path $apk) -or (Get-Item $apk).LastWriteTime -lt $started) {
        Get-Content $errorLog -Tail 20
        throw 'Android developer export did not produce a fresh successful APK.'
    }
    Write-Output "Fresh developer APK: $apk"
} finally {
    foreach ($name in $old.Keys) { [Environment]::SetEnvironmentVariable($name,$old[$name],'Process') }
}
