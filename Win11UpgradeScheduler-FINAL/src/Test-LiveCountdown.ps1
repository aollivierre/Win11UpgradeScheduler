#region Test Live Countdown Dialog
<#
.SYNOPSIS
    Test the live countdown functionality
.DESCRIPTION
    Tests the Show-InstallationWelcome function with live countdown timer
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$PSADTPath = 'C:\code\Windows\Win11UpgradeScheduler-FINAL\src',
    
    [Parameter(Mandatory=$false)]
    [int]$CountdownMinutes = 2
)

# Load PSADT toolkit
$toolkitMain = Join-Path -Path $PSADTPath -ChildPath 'AppDeployToolkit\AppDeployToolkitMain.ps1'

if (Test-Path -Path $toolkitMain) {
    Write-Host "Testing live countdown dialog for $CountdownMinutes minutes..." -ForegroundColor Yellow
    
    # Create the countdown script
    $countdownSeconds = $CountdownMinutes * 60
    $countdownScript = @"
# Load PSADT toolkit
. '$toolkitMain'

# Show countdown using Show-InstallationWelcome with live countdown timer
Show-InstallationWelcome ``
    -CloseApps "nonexistentapp" ``
    -Silent ``
    -CloseAppsCountdown $countdownSeconds ``
    -ForceCloseAppsCountdown $countdownSeconds ``
    -CustomText "Windows 11 upgrade will begin automatically after the countdown or you can click 'Continue' to start immediately.`n`nPlease save your work before continuing." ``
    -TopMost `$true

# The function returns when user clicks Continue or countdown expires
Write-Host "Countdown dialog completed"
"@
    
    $tempScript = Join-Path -Path $env:TEMP -ChildPath "TestLiveCountdown_$(Get-Date -Format 'yyyyMMddHHmmss').ps1"
    $countdownScript | Set-Content -Path $tempScript -Force
    
    Write-Host "Created test script: $tempScript" -ForegroundColor Yellow
    Write-Host "Script content:" -ForegroundColor Yellow
    Get-Content -Path $tempScript | Write-Host -ForegroundColor Gray
    
    # Show the countdown dialog
    Write-Host "Showing live countdown dialog..." -ForegroundColor Yellow
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