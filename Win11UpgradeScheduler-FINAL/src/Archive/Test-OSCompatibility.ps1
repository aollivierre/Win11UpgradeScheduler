#region Test Script Header
<#
.SYNOPSIS
    Test script for OS Compatibility Check implementation
.DESCRIPTION
    Validates the OS compatibility check functionality with developer mode
.NOTES
    Version:        1.0.0
    Created:        2025-01-18
#>
#endregion

#region Test Setup
# Import the module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\SupportFiles\Modules\00-OSCompatibilityCheck.psm1"
Import-Module $modulePath -Force

Write-Host ("=" * 60) -ForegroundColor Cyan
Write-Host "OS Compatibility Check Test Script" -ForegroundColor Cyan
Write-Host ("=" * 60) -ForegroundColor Cyan
#endregion

#region Test OS Detection
Write-Host "`nTesting OS Detection..." -ForegroundColor Yellow

# Get OS details
$osDetails = Get-OSDetails

Write-Host "`nOS Details:" -ForegroundColor Green
Write-Host "  Product Name: $($osDetails.ProductName)"
Write-Host "  Display Version: $($osDetails.DisplayVersion)"
Write-Host "  Build Number: $($osDetails.BuildNumber)"
Write-Host "  OS Type: $($osDetails.OSType)"
Write-Host "  Caption: $($osDetails.Caption)"
#endregion

#region Test Compatibility Check - Normal Mode
Write-Host "`n`nTesting Compatibility Check (Normal Mode)..." -ForegroundColor Yellow

$normalResult = Test-OSCompatibility

Write-Host "`nNormal Mode Results:" -ForegroundColor Green
Write-Host "  Is Compatible: $($normalResult.IsCompatible)"
Write-Host "  Requires User Prompt: $($normalResult.RequiresUserPrompt)"
Write-Host "  Block Completely: $($normalResult.BlockCompletely)"
Write-Host "  Action: $($normalResult.Action)"
Write-Host "  Message: $($normalResult.Message)"
#endregion

#region Test Compatibility Check - Developer Mode
Write-Host "`n`nTesting Compatibility Check (Developer Mode)..." -ForegroundColor Yellow

$devResult = Test-OSCompatibility -DeveloperMode

Write-Host "`nDeveloper Mode Results:" -ForegroundColor Green
Write-Host "  Is Compatible: $($devResult.IsCompatible)"
Write-Host "  Requires User Prompt: $($devResult.RequiresUserPrompt)"
Write-Host "  Block Completely: $($devResult.BlockCompletely)"
Write-Host "  Action: $($devResult.Action)"
Write-Host "  Message: $($devResult.Message)"
#endregion

#region Simulate Different OS Types
Write-Host "`n`nSimulating Different OS Types..." -ForegroundColor Yellow

# Mock function to test different scenarios
function Test-OSScenario {
    param(
        [string]$OSType,
        [int]$BuildNumber,
        [string]$ProductName
    )
    
    Write-Host "`n  Testing $OSType (Build: $BuildNumber):" -ForegroundColor Cyan
    
    # We can't actually mock the OS, but we can show what would happen
    switch ($OSType) {
        'Windows11' {
            Write-Host "    - Normal Mode: Would block completely" -ForegroundColor Red
            Write-Host "    - Dev Mode: Would show prompt to continue" -ForegroundColor Yellow
        }
        'Windows10' {
            Write-Host "    - Normal Mode: Would allow upgrade" -ForegroundColor Green
            Write-Host "    - Dev Mode: Would allow upgrade" -ForegroundColor Green
        }
        'Legacy' {
            Write-Host "    - Normal Mode: Would block completely" -ForegroundColor Red
            Write-Host "    - Dev Mode: Would block completely" -ForegroundColor Red
        }
    }
}

Test-OSScenario -OSType 'Windows11' -BuildNumber 22000 -ProductName 'Windows 11'
Test-OSScenario -OSType 'Windows10' -BuildNumber 19045 -ProductName 'Windows 10'
Test-OSScenario -OSType 'Legacy' -BuildNumber 7601 -ProductName 'Windows 7'
#endregion

#region Display Log Location
Write-Host "`n`nLog files are located at:" -ForegroundColor Cyan
Write-Host "  $env:ProgramData\Win11UpgradeScheduler\Logs" -ForegroundColor White

$latestLog = Get-ChildItem -Path "$env:ProgramData\Win11UpgradeScheduler\Logs" -Filter "OSCompatibilityCheck_*.log" -ErrorAction SilentlyContinue |
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

#region Test Command Line Examples
Write-Host "`n`nCommand Line Examples:" -ForegroundColor Cyan
Write-Host "  Normal mode (blocks Win11):" -ForegroundColor Yellow
Write-Host "    .\Deploy-Application-InstallationAssistant-Version.ps1" -ForegroundColor White

Write-Host "`n  Developer mode (allows Win11 bypass):" -ForegroundColor Yellow
Write-Host "    .\Deploy-Application-InstallationAssistant-Version.ps1 -DeveloperMode" -ForegroundColor White

Write-Host "`n  Silent mode with developer mode:" -ForegroundColor Yellow
Write-Host "    .\Deploy-Application-InstallationAssistant-Version.ps1 -DeployMode Silent -DeveloperMode" -ForegroundColor White
#endregion

Write-Host "`n" ("=" * 60) -ForegroundColor Cyan
Write-Host "Test Complete" -ForegroundColor Cyan
Write-Host ("=" * 60) -ForegroundColor Cyan