#region Test Script Header
<#
.SYNOPSIS
    Test script for Windows Version Check implementation (Phase 1)
.DESCRIPTION
    Validates the Windows version check functionality added to PreFlightChecks module
.NOTES
    Version:        1.0.0
    Created:        2025-01-18
#>
#endregion

#region Test Setup
# Import the module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\SupportFiles\Modules\02-PreFlightChecks.psm1"
Import-Module $modulePath -Force

Write-Host ("=" * 60) -ForegroundColor Cyan
Write-Host "Windows Version Check Test Script" -ForegroundColor Cyan
Write-Host ("=" * 60) -ForegroundColor Cyan
#endregion

#region Test Windows Version Check
Write-Host "`nTesting Windows Version Check Function..." -ForegroundColor Yellow

# Test the specific function
$versionResult = Test-WindowsVersion

Write-Host "`nWindows Version Check Results:" -ForegroundColor Green
Write-Host "  Passed: $($versionResult.Passed)"
Write-Host "  Message: $($versionResult.Message)"
Write-Host "  Build Number: $($versionResult.BuildNumber)"
Write-Host "  Version: $($versionResult.Version)"
Write-Host "  Minimum Build: $($versionResult.MinimumBuild)"
Write-Host "  Severity: $($versionResult.Severity)"

# Color code the severity
$severityColor = switch ($versionResult.Severity) {
    'Error' { 'Red' }
    'Warning' { 'Yellow' }
    'Information' { 'Green' }
    default { 'White' }
}

Write-Host "`nSeverity Status: $($versionResult.Severity)" -ForegroundColor $severityColor
#endregion

#region Test Full System Readiness
Write-Host "`n`nTesting Full System Readiness (includes version check)..." -ForegroundColor Yellow

# Run full system readiness check
$readinessResult = Test-SystemReadiness -Verbose

Write-Host "`nSystem Readiness Results:" -ForegroundColor Green
Write-Host "  Is Ready: $($readinessResult.IsReady)"

if ($readinessResult.Issues.Count -gt 0) {
    Write-Host "`n  Critical Issues:" -ForegroundColor Red
    foreach ($issue in $readinessResult.Issues) {
        Write-Host "    - $issue" -ForegroundColor Red
    }
}

if ($readinessResult.Warnings.Count -gt 0) {
    Write-Host "`n  Warnings:" -ForegroundColor Yellow
    foreach ($warning in $readinessResult.Warnings) {
        Write-Host "    - $warning" -ForegroundColor Yellow
    }
}

Write-Host "`n  Individual Check Results:" -ForegroundColor Cyan
foreach ($check in $readinessResult.Checks.GetEnumerator()) {
    $checkColor = switch ($check.Value.Severity) {
        'Error' { 'Red' }
        'Warning' { 'Yellow' }
        'Information' { 'Green' }
        default { 'White' }
    }
    Write-Host "    $($check.Key): $($check.Value.Message)" -ForegroundColor $checkColor
}
#endregion

#region Display Log Location
Write-Host "`n`nLog files are located at:" -ForegroundColor Cyan
Write-Host "  $env:ProgramData\Win11UpgradeScheduler\Logs" -ForegroundColor White

$latestLog = Get-ChildItem -Path "$env:ProgramData\Win11UpgradeScheduler\Logs" -Filter "PreFlightChecks_*.log" |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1

if ($latestLog) {
    Write-Host "`nLatest log file: $($latestLog.Name)" -ForegroundColor Cyan
    Write-Host "Last 10 lines of log:" -ForegroundColor Yellow
    Get-Content $latestLog.FullName -Tail 10 | ForEach-Object {
        if ($_ -match '\[Warning\]') {
            Write-Host $_ -ForegroundColor Yellow
        }
        elseif ($_ -match '\[Error\]') {
            Write-Host $_ -ForegroundColor Red
        }
        else {
            Write-Host $_ -ForegroundColor Gray
        }
    }
}
#endregion

Write-Host "`n" ("=" * 60) -ForegroundColor Cyan
Write-Host "Test Complete" -ForegroundColor Cyan
Write-Host ("=" * 60) -ForegroundColor Cyan