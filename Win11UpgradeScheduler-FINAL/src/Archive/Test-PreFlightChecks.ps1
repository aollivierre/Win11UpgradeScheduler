# Test script for PreFlightChecks module
$ErrorActionPreference = 'Stop'

# Import the module
Write-Host "Importing PreFlightChecks module..." -ForegroundColor Cyan
Import-Module ".\SupportFiles\Modules\02-PreFlightChecks.psm1" -Force

Write-Host "`nRunning Test-SystemReadiness..." -ForegroundColor Cyan
$results = Test-SystemReadiness -Verbose

Write-Host "`nResults:" -ForegroundColor Yellow
Write-Host "IsReady: $($results.IsReady)" -ForegroundColor $(if ($results.IsReady) { 'Green' } else { 'Red' })

if ($results.Issues.Count -gt 0) {
    Write-Host "`nCritical Issues:" -ForegroundColor Red
    foreach ($issue in $results.Issues) {
        Write-Host "  - $issue" -ForegroundColor Red
    }
}

if ($results.Warnings.Count -gt 0) {
    Write-Host "`nWarnings:" -ForegroundColor Yellow
    foreach ($warning in $results.Warnings) {
        Write-Host "  - $warning" -ForegroundColor Yellow
    }
}

Write-Host "`nDetailed Check Results:" -ForegroundColor Cyan
foreach ($check in $results.Checks.Keys) {
    $checkResult = $results.Checks[$check]
    $color = switch ($checkResult.Severity) {
        'Error' { 'Red' }
        'Warning' { 'Yellow' }
        'Information' { 'Green' }
        default { 'White' }
    }
    
    Write-Host "`n$check`:" -ForegroundColor White
    Write-Host "  Passed: $($checkResult.Passed)" -ForegroundColor $color
    Write-Host "  Message: $($checkResult.Message)" -ForegroundColor $color
    
    # Show additional details for specific checks
    if ($check -eq 'DiskSpace') {
        Write-Host "  Free Space: $($checkResult.FreeSpaceGB) GB" -ForegroundColor $color
        Write-Host "  Required: $($checkResult.RequiredGB) GB" -ForegroundColor $color
    }
    elseif ($check -eq 'Battery') {
        Write-Host "  Battery Level: $($checkResult.BatteryPercent)%" -ForegroundColor $color
        Write-Host "  On AC Power: $($checkResult.IsOnAC)" -ForegroundColor $color
    }
    elseif ($check -eq 'SystemResources') {
        Write-Host "  CPU Usage: $($checkResult.CPUUsagePercent)%" -ForegroundColor $color
        Write-Host "  Free Memory: $($checkResult.FreeMemoryGB) GB" -ForegroundColor $color
    }
}

Write-Host "`n`nTesting Individual Functions:" -ForegroundColor Cyan

# Test disk space check specifically
Write-Host "`nTesting Test-DiskSpace..." -ForegroundColor Cyan
$diskCheck = Test-DiskSpace
Write-Host "Disk Space Check Result:"
Write-Host "  Free Space: $($diskCheck.FreeSpaceGB) GB"
Write-Host "  Severity: $($diskCheck.Severity)"
Write-Host "  Message: $($diskCheck.Message)"