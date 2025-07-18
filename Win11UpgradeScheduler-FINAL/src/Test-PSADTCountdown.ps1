#region Test PSADT Countdown Following Guide
<#
.SYNOPSIS
    Test PSADT countdown timer following the guide exactly
.DESCRIPTION
    Uses the simplest working example from PSADT v3 guide
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$PSADTPath = 'C:\code\Windows\Win11UpgradeScheduler-FINAL\src'
)

# Load PSADT toolkit
$toolkitMain = Join-Path -Path $PSADTPath -ChildPath 'AppDeployToolkit\AppDeployToolkitMain.ps1'

Write-Host "Testing PSADT visual countdown timer..." -ForegroundColor Yellow
Write-Host "Following PSADT v3 Countdown Timer Guide" -ForegroundColor Cyan

# Create test script
$testScript = @"
# Load PSADT toolkit
. '$toolkitMain'

Write-Host "Launching notepad to have an app to close..."

# Launch notepad for testing (safe app)
Start-Process 'notepad.exe' -WindowStyle Normal
Start-Sleep -Seconds 2

Write-Host "Showing countdown dialog..."

# Show visual countdown - exactly as per guide
Show-InstallationWelcome ``
    -CloseApps 'notepad' ``
    -CloseAppsCountdown 60

Write-Host "Countdown completed!"
"@

$tempScript = Join-Path -Path $env:TEMP -ChildPath "PSADTCountdown_$(Get-Date -Format 'yyyyMMddHHmmss').ps1"
$testScript | Set-Content -Path $tempScript -Force

Write-Host "Running test..." -ForegroundColor Yellow
Write-Host "You should see:" -ForegroundColor Green
Write-Host "  1. Notepad will open" -ForegroundColor Green
Write-Host "  2. A dialog saying apps need to close" -ForegroundColor Green  
Write-Host "  3. A VISUAL COUNTDOWN TIMER counting down from 60 seconds" -ForegroundColor Green
Write-Host "  4. The ability to click 'Continue' or wait for countdown" -ForegroundColor Green

Start-Process -FilePath 'powershell.exe' `
    -ArgumentList "-ExecutionPolicy Bypass -File `"$tempScript`"" `
    -WorkingDirectory $PSADTPath `
    -Wait `
    -WindowStyle Normal

Remove-Item -Path $tempScript -Force -ErrorAction SilentlyContinue
Write-Host "Test completed!" -ForegroundColor Green
#endregion