param(
    [string]$Godot = "C:\Users\ASUS\My Tools\Godot\4.6.3\Godot_v4.6.3-stable_win64.exe",
    [ValidateSet("release_checks", "progression_daily_checks", "random_release_checks", "streak_release_checks", "economy_checks", "difficulty_checks", "story_checks", "developer_checks", "gallery_checks", "mobile_ui_checks", "level48_checks", "character_booster_checks", "action_audio_checks", "dialog_readability_checks")]
    [string]$Suite = "release_checks",
    [switch]$Resume,
    [ValidateRange(1, 3600)]
    [int]$TimeoutSeconds = 900,
    [string[]]$TestArguments = @()
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot
$previousAppData = $env:APPDATA
try {
    $env:APPDATA = Join-Path $projectRoot ".test-data/$Suite"
    if ($Suite -eq "developer_checks") { $env:APPDATA = Join-Path $projectRoot '.test-data/developer-play/checks' }
    New-Item -ItemType Directory -Path $env:APPDATA -Force | Out-Null
    if ($Resume -and $Suite -ne "streak_release_checks") {
        throw "-Resume is only supported by streak_release_checks."
    }
    $runnerArguments = @("--headless", "--path", "`"$projectRoot`"", "res://tests/$Suite.tscn")
    if ($Resume) { $runnerArguments += @("--", "--resume") }
    if ($TestArguments.Count) { $runnerArguments += @("--") + $TestArguments }
    if ($Suite -eq "developer_checks") { $runnerArguments += @('--', '--developer-tools') }
    $outputLog = Join-Path $env:APPDATA "runner-output.log"
    $errorLog = Join-Path $env:APPDATA "runner-error.log"
    # The Windows GUI executable can return immediately with '&'. Wait for its
    # actual process exit so a failed suite cannot be reported as successful.
    $runner = Start-Process -FilePath $Godot -ArgumentList $runnerArguments -WindowStyle Hidden -PassThru -RedirectStandardOutput $outputLog -RedirectStandardError $errorLog
    $runner.Id | Set-Content (Join-Path $env:APPDATA "runner.pid")
    if (-not $runner.WaitForExit($TimeoutSeconds * 1000)) {
        $runner.Kill()
        $runner.WaitForExit()
        $checkExitCode = 124
    } else {
        $runner.WaitForExit()
        $checkExitCode = $runner.ExitCode
    }
    Get-Content -LiteralPath $outputLog
    Get-Content -LiteralPath $errorLog
    if ($checkExitCode -eq 0 -and (Get-Content -LiteralPath $errorLog -Raw) -match "SCRIPT ERROR:") {
        $checkExitCode = 1
    }
} finally {
    $env:APPDATA = $previousAppData
}
exit $checkExitCode
