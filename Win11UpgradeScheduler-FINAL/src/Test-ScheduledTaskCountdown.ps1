<#
.SYNOPSIS
    Test script for scheduled task countdown integration
.DESCRIPTION
    Simulates the scheduled task wrapper countdown functionality
#>

# Set paths
$scriptDirectory = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$PSADTPath = $scriptDirectory

Write-Host "Testing scheduled task countdown integration..." -ForegroundColor Green
Write-Host "PSADTPath: $PSADTPath" -ForegroundColor Cyan

# Test the countdown as it would appear in scheduled task
$countdownSeconds = 30 # 30 seconds for testing (normally 1800 for 30 minutes)

# Create the countdown script as wrapper does
$countdownScript = @"
# Load PSADT toolkit
`$scriptPath = '$PSADTPath'
. "`$scriptPath\AppDeployToolkit\AppDeployToolkitMain.ps1"

# Import custom countdown module
Import-Module '$PSADTPath\PSADTCustomCountdown.psm1' -Force

# Show custom countdown with visual progress
`$result = Show-CustomCountdownDialog ``
    -CountdownSeconds $countdownSeconds ``
    -Message "Windows 11 upgrade will begin in 30 seconds.`n`nPlease save your work before continuing." ``
    -Title "Windows 11 Upgrade Scheduled"

# Return 1 if Start Now was clicked, 0 if countdown completed
if (`$result -eq 'Yes') {
    Write-Host "User clicked Start Now - would start upgrade immediately" -ForegroundColor Green
    exit 1
} else {
    Write-Host "Countdown completed - would proceed with upgrade" -ForegroundColor Yellow
    exit 0
}
"@

# Save and execute the test script
$tempScript = Join-Path -Path $env:TEMP -ChildPath "TestCountdown_$(Get-Date -Format 'yyyyMMddHHmmss').ps1"
$countdownScript | Set-Content -Path $tempScript -Force

Write-Host "`nRunning countdown test..." -ForegroundColor Yellow
Write-Host "This simulates what users will see when the scheduled task runs.`n" -ForegroundColor Gray

$process = Start-Process -FilePath 'powershell.exe' `
    -ArgumentList "-ExecutionPolicy Bypass -File `"$tempScript`"" `
    -WorkingDirectory $PSADTPath `
    -Wait `
    -PassThru

if ($process.ExitCode -eq 1) {
    Write-Host "`nResult: User clicked 'Start Now' (Exit code: 1)" -ForegroundColor Cyan
} else {
    Write-Host "`nResult: Countdown completed (Exit code: 0)" -ForegroundColor Cyan
}

# Cleanup
Remove-Item -Path $tempScript -Force -ErrorAction SilentlyContinue

Write-Host "`nTest completed successfully!" -ForegroundColor Green