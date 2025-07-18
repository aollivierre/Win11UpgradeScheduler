#region Quick Countdown Test
<#
.SYNOPSIS
    Quick test to show countdown dialog for 30 seconds
.DESCRIPTION
    Tests countdown functionality with a very short timer to verify it's working
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$PSADTPath = 'C:\code\Windows\Win11UpgradeScheduler-FINAL\src'
)

# Load PSADT toolkit
$toolkitMain = Join-Path -Path $PSADTPath -ChildPath 'AppDeployToolkit\AppDeployToolkitMain.ps1'

if (Test-Path -Path $toolkitMain) {
    Write-Host "Testing countdown dialog for 30 seconds..." -ForegroundColor Yellow
    
    # Create the countdown script with 30 second timer
    $countdownScript = @"
# Load PSADT toolkit
. '$toolkitMain'

Write-Host "Starting countdown test..."

# Show countdown using Show-InstallationWelcome with live countdown timer
`$processes = Get-Process -Name 'explorer' -ErrorAction SilentlyContinue
if (`$processes) {
    Write-Host "Found explorer process, showing countdown with live timer..."
    Show-InstallationWelcome ``
        -CloseApps "explorer" ``
        -CloseAppsCountdown 30 ``
        -ForceCloseAppsCountdown 30 ``
        -CustomText "Windows 11 upgrade test countdown (30 seconds).`n`nThis is a test of the live countdown timer.`n`nClick 'Continue' to proceed or wait for auto-start." ``
        -TopMost `$true ``
        -AllowDefer ``
        -DeferTimes 0
} else {
    Write-Host "No explorer process found, using fallback dialog..."
    Show-InstallationPrompt ``
        -Message "Windows 11 upgrade test countdown (30 seconds).`n`nThis is a test countdown dialog." ``
        -ButtonRightText 'Continue' ``
        -ButtonLeftText 'Wait' ``
        -Icon Information ``
        -Timeout 30 ``
        -ExitOnTimeout `$true
}

Write-Host "Countdown test completed!"
"@
    
    $tempScript = Join-Path -Path $env:TEMP -ChildPath "QuickCountdown_$(Get-Date -Format 'yyyyMMddHHmmss').ps1"
    $countdownScript | Set-Content -Path $tempScript -Force
    
    Write-Host "Created test script: $tempScript" -ForegroundColor Yellow
    
    # Show the countdown dialog
    Write-Host "Showing countdown dialog (30 seconds)..." -ForegroundColor Yellow
    Write-Host "You should see a dialog with a live countdown timer!" -ForegroundColor Green
    
    Start-Process -FilePath 'powershell.exe' `
        -ArgumentList "-ExecutionPolicy Bypass -File `"$tempScript`"" `
        -WorkingDirectory $PSADTPath `
        -Wait `
        -WindowStyle Normal
    
    Remove-Item -Path $tempScript -Force -ErrorAction SilentlyContinue
    Write-Host "Test completed!" -ForegroundColor Green
}
else {
    Write-Host "PSADT toolkit not found at: $toolkitMain" -ForegroundColor Red
}
#endregion