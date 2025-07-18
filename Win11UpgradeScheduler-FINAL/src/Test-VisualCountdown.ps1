#region Test Visual Countdown Timer
<#
.SYNOPSIS
    Test the visual countdown timer using Show-InstallationWelcome
.DESCRIPTION
    Tests the proper PSADT v3 visual countdown implementation
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$PSADTPath = 'C:\code\Windows\Win11UpgradeScheduler-FINAL\src',
    
    [Parameter(Mandatory=$false)]
    [int]$CountdownMinutes = 1
)

# Load PSADT toolkit
$toolkitMain = Join-Path -Path $PSADTPath -ChildPath 'AppDeployToolkit\AppDeployToolkitMain.ps1'

if (Test-Path -Path $toolkitMain) {
    Write-Host "Testing visual countdown timer for $CountdownMinutes minute(s)..." -ForegroundColor Yellow
    Write-Host "Per PSADT v3 guide, using Show-InstallationWelcome for visual countdown" -ForegroundColor Cyan
    
    # Create the countdown script
    $countdownSeconds = $CountdownMinutes * 60
    $countdownScript = @"
# Load PSADT toolkit
. '$toolkitMain'

Write-Host "Starting visual countdown test..."

# Use Show-InstallationWelcome for VISUAL countdown timer (per PSADT v3 guide)
# We need to specify actual running processes for the countdown to display
`$runningApps = @('notepad', 'chrome', 'firefox', 'edge', 'winword', 'excel', 'outlook', 'teams', 'powershell')
`$appsToClose = `$runningApps | Where-Object { Get-Process -Name `$_ -ErrorAction SilentlyContinue }

# If no specific apps are running, use explorer as it's always running
if (-not `$appsToClose) {
    `$appsToClose = @('explorer')
}

Write-Host "Apps to monitor: `$(`$appsToClose -join ', ')"

# Show visual countdown using Show-InstallationWelcome
Show-InstallationWelcome ``
    -CloseApps (`$appsToClose -join ',') ``
    -CloseAppsCountdown $countdownSeconds ``
    -ForceCloseAppsCountdown $countdownSeconds ``
    -PersistPrompt ``
    -BlockExecution ``
    -AllowDefer ``
    -DeferTimes 0 ``
    -CheckDiskSpace ``
    -RequiredDiskSpace 50000 ``
    -MinimizeWindows `$false ``
    -TopMost `$true ``
    -ForceCountdown $countdownSeconds

Write-Host "Visual countdown completed!"
"@
    
    $tempScript = Join-Path -Path $env:TEMP -ChildPath "VisualCountdown_$(Get-Date -Format 'yyyyMMddHHmmss').ps1"
    $countdownScript | Set-Content -Path $tempScript -Force
    
    Write-Host "Created test script: $tempScript" -ForegroundColor Yellow
    
    # Show the countdown dialog
    Write-Host "Showing VISUAL countdown dialog..." -ForegroundColor Yellow
    Write-Host "You should see:" -ForegroundColor Green
    Write-Host "  - A dialog listing running applications" -ForegroundColor Green
    Write-Host "  - A VISUAL countdown timer ticking down from $countdownSeconds seconds" -ForegroundColor Green
    Write-Host "  - 'Continue' button to proceed immediately" -ForegroundColor Green
    
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