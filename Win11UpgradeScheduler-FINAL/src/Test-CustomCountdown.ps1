<#
.SYNOPSIS
    Test script for custom countdown integration
.DESCRIPTION
    Tests the custom countdown module integration with PSADT
#>

# Set script directory
$scriptDirectory = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent

# Import PSADT
. "$scriptDirectory\AppDeployToolkit\AppDeployToolkitMain.ps1"

# Import custom countdown module
Import-Module "$scriptDirectory\PSADTCustomCountdown.psm1" -Force

Write-Host "Testing custom countdown module..." -ForegroundColor Green

# Test 1: Short countdown (30 seconds)
Write-Host "`nTest 1: 30-second countdown" -ForegroundColor Yellow
$result = Show-CustomCountdownDialog -CountdownSeconds 30 -Message "Test countdown - 30 seconds`n`nClick 'Start Now' to test immediate return." -Title "Countdown Test"

if ($result -eq 'Yes') {
    Write-Host "User clicked 'Start Now'" -ForegroundColor Cyan
} else {
    Write-Host "Countdown completed or dialog closed" -ForegroundColor Cyan
}

# Test 2: Longer countdown (60 seconds) with NoAutoClose
Write-Host "`nTest 2: 60-second countdown with NoAutoClose" -ForegroundColor Yellow
$result = Show-CustomCountdownDialog -CountdownSeconds 60 -Message "Test countdown - 60 seconds`n`nDialog will stay open after countdown." -Title "Countdown Test" -NoAutoClose

Write-Host "Test completed. Result: $result" -ForegroundColor Green