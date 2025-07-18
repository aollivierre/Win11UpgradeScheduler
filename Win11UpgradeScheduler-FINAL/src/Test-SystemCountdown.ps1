<#
.SYNOPSIS
    Test countdown execution as SYSTEM
.DESCRIPTION
    Simulates what happens when scheduled task runs as SYSTEM
#>

param(
    [string]$PSADTPath = "C:\Code\Win11UpgradeScheduler\Win11UpgradeScheduler-FINAL\src"
)

Write-Host "Testing SYSTEM execution flow..." -ForegroundColor Cyan

# Load PSADT toolkit
$toolkitMain = Join-Path -Path $PSADTPath -ChildPath 'AppDeployToolkit\AppDeployToolkitMain.ps1'
Write-Host "Loading PSADT from: $toolkitMain" -ForegroundColor Yellow
. $toolkitMain

# Test Execute-ProcessAsUser with a simple command first
Write-Host "`nTesting Execute-ProcessAsUser with simple command..." -ForegroundColor Yellow
try {
    $testResult = Execute-ProcessAsUser -Path "$PSHOME\powershell.exe" `
        -Parameters "-Command `"Write-Host 'Hello from user context'; Start-Sleep -Seconds 2`"" `
        -Wait
    
    Write-Host "Simple test exit code: $($testResult.ExitCode)" -ForegroundColor Green
} catch {
    Write-Host "Failed simple test: $_" -ForegroundColor Red
}

# Now test with countdown
Write-Host "`nTesting countdown in user context..." -ForegroundColor Yellow

$countdownScript = @"
# This is what the wrapper tries to run
`$PSADTPath = '$PSADTPath'
Write-Host "PSADTPath: `$PSADTPath"

# Load PSADT toolkit
`$toolkitMain = Join-Path -Path `$PSADTPath -ChildPath 'AppDeployToolkit\AppDeployToolkitMain.ps1'
Write-Host "Loading toolkit from: `$toolkitMain"
. `$toolkitMain

# Import custom countdown module  
`$countdownModule = Join-Path -Path `$PSADTPath -ChildPath 'PSADTCustomCountdown.psm1'
Write-Host "Loading countdown module from: `$countdownModule"
Import-Module `$countdownModule -Force

# Show countdown (30 seconds for testing)
Write-Host "Showing countdown dialog..."
`$result = Show-CustomCountdownDialog -CountdownSeconds 30 -Message "Test countdown - 30 seconds" -Title "System Test"

if (`$result -eq 'Yes') {
    Write-Host "User clicked Start Now"
    exit 1
} else {
    Write-Host "Countdown completed"
    exit 0
}
"@

$tempScript = Join-Path -Path $env:TEMP -ChildPath "SystemCountdownTest_$(Get-Date -Format 'yyyyMMddHHmmss').ps1"
Write-Host "Creating temp script: $tempScript" -ForegroundColor Gray
$countdownScript | Set-Content -Path $tempScript -Force

try {
    Write-Host "Executing countdown script via Execute-ProcessAsUser..." -ForegroundColor Yellow
    $result = Execute-ProcessAsUser -Path "$PSHOME\powershell.exe" `
        -Parameters "-ExecutionPolicy Bypass -File `"$tempScript`"" `
        -Wait
    
    Write-Host "Countdown test exit code: $($result.ExitCode)" -ForegroundColor Green
} catch {
    Write-Host "Failed countdown test: $_" -ForegroundColor Red
} finally {
    Remove-Item -Path $tempScript -Force -ErrorAction SilentlyContinue
}

Write-Host "`nTest complete." -ForegroundColor Cyan