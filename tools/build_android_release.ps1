param(
    [string]$Godot = "C:\Users\ASUS\My Tools\Godot\4.6.3\Godot_v4.6.3-stable_win64.exe",
    [string]$Java = "C:\Program Files\Microsoft\jdk-21.0.12.101-hotspot",
    [string]$AndroidSdk = "C:\Users\ASUS\Android\Sdk",
    [string]$GradleCache = ".gradle-cache",
    [ValidateSet('aab', 'apk')]
    [string[]]$Formats = @('aab', 'apk')
)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$version = [int]([regex]::Match((Get-Content (Join-Path $root 'export_presets.cfg') -Raw),'version/code=(\d+)').Groups[1].Value)
$outputLog = Join-Path $root ".test-data/android-v$version-output.log"
$errorLog = Join-Path $root ".test-data/android-v$version-error.log"
$old = @{APPDATA=$env:APPDATA; GRADLE_USER_HOME=$env:GRADLE_USER_HOME; JAVA_HOME=$env:JAVA_HOME; ANDROID_HOME=$env:ANDROID_HOME; ANDROID_USER_HOME=$env:ANDROID_USER_HOME; ANDROID_SDK_HOME=$env:ANDROID_SDK_HOME; JAVA_TOOL_OPTIONS=$env:JAVA_TOOL_OPTIONS}
try {
    $env:APPDATA = Join-Path $root '.test-data/r8-release-editor'
    $env:GRADLE_USER_HOME = Join-Path $root $GradleCache
    $env:JAVA_HOME = $Java
    $env:ANDROID_HOME = $AndroidSdk
    $env:ANDROID_SDK_HOME = Join-Path $root '.test-data/android-user'
    $env:ANDROID_USER_HOME = Join-Path $env:ANDROID_SDK_HOME '.android'
    New-Item -ItemType Directory -Force -Path $env:ANDROID_USER_HOME | Out-Null
    $env:JAVA_TOOL_OPTIONS = '-Duser.home="' + $env:ANDROID_SDK_HOME + '"'
    if (-not (Test-Path (Join-Path $env:APPDATA 'Godot/editor_settings-4.6.tres'))) { throw 'The isolated Android export editor profile is missing.' }
    foreach ($format in $Formats) {
    $bundle = Join-Path $root "build/android/SaveTheBaby-v$version.$format"
    $preset = if ($format -eq 'aab') { 'Android AAB Release' } else { 'Android APK Release' }
    $outputLog = Join-Path $root ".test-data/android-v$version-$format-output.log"
    $errorLog = Join-Path $root ".test-data/android-v$version-$format-error.log"
    $started = Get-Date
    $process = Start-Process -FilePath $Godot -ArgumentList @('--headless','--path',"`"$root`"",'--export-release',"`"$preset`"","`"$bundle`"") -WindowStyle Hidden -PassThru -RedirectStandardOutput $outputLog -RedirectStandardError $errorLog
    $null = $process.Handle
    $process.Id | Set-Content (Join-Path $root '.test-data/android-export.pid')
    if (-not $process.WaitForExit(900000)) { $process.Kill(); throw 'Android export timed out.' }
    $process.WaitForExit()
    $exportExitCode = $process.ExitCode
    # Godot/Gradle can echo signing arguments on failure; keep logs reviewable.
    foreach ($log in @($outputLog, $errorLog)) {
        $safeLog = (Get-Content -LiteralPath $log -Raw) -replace '(?i)(keystore_password=)[^"\s]+', '$1[REDACTED]'
        [System.IO.File]::WriteAllText($log, $safeLog)
    }
    $errors = Get-Content $errorLog -Raw
    Write-Output "Export exit code: $exportExitCode; started: $($started.ToString('o'))"
    if (($null -ne $exportExitCode -and $exportExitCode -ne 0) -or $errors -match 'SCRIPT ERROR:|Export failed|Failed to export' -or -not (Test-Path $bundle) -or (Get-Item $bundle).LastWriteTime -lt $started) {
        Get-Content $errorLog -Tail 20
        throw 'Android export did not produce a fresh successful bundle.'
    }
    Write-Output "Fresh Android release: $bundle"
    }
} finally {
    foreach ($name in $old.Keys) { [Environment]::SetEnvironmentVariable($name,$old[$name],'Process') }
}
