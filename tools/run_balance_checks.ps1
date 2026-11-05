param(
    [string]$Godot = "C:\Users\ASUS\My Tools\Godot\4.6.3\Godot_v4.6.3-stable_win64.exe",
    [string]$BaselineRevision = "e764ce9"
)
$ErrorActionPreference = "Stop"
$balanceRoot = Split-Path -Parent $PSScriptRoot
$previousAppData = $env:APPDATA
$runs = @()
try {
    # Archive the committed definitions so both runs use the same policies and
    # seeds; only move budgets/reward definitions differ between the two runs.
    $baselineDir = Join-Path $balanceRoot '.test-data/balance-baseline-levels'
    New-Item -ItemType Directory -Force -Path $baselineDir | Out-Null
    $sample = @(51,105,133,435,511,637,783,966,1050)
    foreach ($level in $sample) {
        $name = 'level{0:000}.json' -f $level
        $content = git -C $balanceRoot show "${BaselineRevision}:levels/$name"
        if ($LASTEXITCODE) { throw "Cannot archive committed $name" }
        [IO.File]::WriteAllText((Join-Path $baselineDir $name),($content -join "`n"))
    }
    foreach ($variant in @('before','after')) {
        $runDir = Join-Path $balanceRoot ".test-data/balance-$variant"
        New-Item -ItemType Directory -Force -Path $runDir | Out-Null
        $env:APPDATA = $runDir
        $arguments = @('--headless','--path',"`"$balanceRoot`"",'res://tests/random_release_checks.tscn','--',"--levels=$($sample -join ',')","--output=res://.test-data/balance-$variant/report.json",'--probe-continue','--inventory-start')
        if ($variant -eq 'before') { $arguments += '--baseline' }
        $process = Start-Process -FilePath $Godot -ArgumentList $arguments -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $runDir 'output.log') -RedirectStandardError (Join-Path $runDir 'error.log')
        $process.Id | Set-Content (Join-Path $runDir 'runner.pid')
        $runs += @{Process=$process; Directory=$runDir; Variant=$variant}
        Write-Output "$variant started: $($process.Id)"
    }
} finally { $env:APPDATA = $previousAppData }
$deadline = [DateTime]::UtcNow.AddMinutes(18)
$failed = $false
foreach ($run in $runs) {
    while (-not $run.Process.WaitForExit(1000)) {
        $errors = Get-Content (Join-Path $run.Directory 'error.log') -Raw
        if ($errors -match 'SCRIPT ERROR:' -or [DateTime]::UtcNow -gt $deadline) {
            $run.Process.Kill()
            $failed = $true
            break
        }
    }
    $run.Process.WaitForExit()
    Get-Content (Join-Path $run.Directory 'output.log') -Tail 3
    if ($run.Process.ExitCode -ne 0) { $failed = $true }
    if ((Get-Content (Join-Path $run.Directory 'error.log') -Raw) -match 'SCRIPT ERROR:') { $failed = $true }
}
if ($failed) { exit 1 }
