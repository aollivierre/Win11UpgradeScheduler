#region Alternative Countdown Test
<#
.SYNOPSIS
    Test alternative countdown approach
.DESCRIPTION
    Try different parameter combinations to get visual countdown
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$PSADTPath = 'C:\code\Windows\Win11UpgradeScheduler-FINAL\src'
)

$toolkitMain = Join-Path -Path $PSADTPath -ChildPath 'AppDeployToolkit\AppDeployToolkitMain.ps1'

Write-Host "Testing alternative countdown approaches..." -ForegroundColor Yellow

# Test 1: Show-InstallationRestartPrompt (has visual countdown but restarts!)
Write-Host "`nTest 1: Show-InstallationRestartPrompt (DO NOT USE IN PRODUCTION - will restart!)" -ForegroundColor Red
Write-Host "This function HAS a visual countdown but will restart the computer!" -ForegroundColor Red
Write-Host "Press any key to skip this dangerous test..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

# Test 2: Show-InstallationPrompt with custom message
Write-Host "`nTest 2: Show-InstallationPrompt with timeout message" -ForegroundColor Cyan
$testScript2 = @"
. '$toolkitMain'
# This shows a static message with timeout, not a visual countdown
Show-InstallationPrompt ``
    -Message "Windows 11 upgrade starting in 60 seconds...`n`nThis dialog will close automatically." ``
    -ButtonRightText 'Start Now' ``
    -Icon Information ``
    -Timeout 60 ``
    -ExitOnTimeout `$true
"@

$tempScript = Join-Path -Path $env:TEMP -ChildPath "StaticCountdown_$(Get-Date -Format 'yyyyMMddHHmmss').ps1"
$testScript2 | Set-Content -Path $tempScript -Force

Write-Host "Running static timeout test..." -ForegroundColor Yellow
Start-Process -FilePath 'powershell.exe' `
    -ArgumentList "-ExecutionPolicy Bypass -File `"$tempScript`"" `
    -WorkingDirectory $PSADTPath `
    -NoNewWindow

Start-Sleep -Seconds 5
Remove-Item -Path $tempScript -Force -ErrorAction SilentlyContinue

Write-Host "`nConclusion:" -ForegroundColor Yellow
Write-Host "- Show-InstallationWelcome: May not show visual countdown in v3" -ForegroundColor White
Write-Host "- Show-InstallationPrompt: Shows static message with silent timeout" -ForegroundColor White
Write-Host "- Show-InstallationRestartPrompt: Has visual countdown but RESTARTS computer!" -ForegroundColor White
Write-Host "`nPlease share the PSADT_v3_Countdown_Timer_Guide.md for exact implementation details" -ForegroundColor Cyan
#endregion