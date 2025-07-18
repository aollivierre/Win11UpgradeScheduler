# Show PSADT countdown timer with visible countdown
param(
    [string]$PSADTPath = "C:\code\Windows\Win11UpgradeScheduler-FINAL\src",
    [int]$Minutes = 2  # 2 minutes for testing instead of 30
)

Write-Host "=== SHOWING COUNTDOWN TIMER ===" -ForegroundColor Cyan
Write-Host "This will show a dialog with a VISIBLE COUNTDOWN TIMER" -ForegroundColor Yellow

# Create script for interactive session
$countdownScript = @"
param([string]`$PSADTPath, [int]`$Minutes)

# Load PSADT
Push-Location `$PSADTPath
. "`$PSADTPath\AppDeployToolkit\AppDeployToolkitMain.ps1"

Write-Host "Showing Installation Restart prompt with countdown timer..." -ForegroundColor Green

# Use Show-InstallationRestartPrompt which has a visible countdown timer
Show-InstallationRestartPrompt ``
    -Countdownseconds ([timespan]::FromMinutes(`$Minutes).TotalSeconds) ``
    -CountdownNoHideSeconds 300

Pop-Location
"@

$tempScript = "$env:TEMP\CountdownTimer_$(Get-Date -Format 'yyyyMMddHHmmss').ps1"
$countdownScript | Set-Content -Path $tempScript -Force

# Create and run scheduled task
$taskName = "CountdownTimerTest_$(Get-Date -Format 'yyyyMMddHHmmss')"
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -WindowStyle Normal -File `"$tempScript`" -PSADTPath `"$PSADTPath`" -Minutes $Minutes"
$principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive -RunLevel Highest
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -StartWhenAvailable

Write-Host "`nCreating scheduled task to show countdown timer..." -ForegroundColor Yellow
Register-ScheduledTask -TaskName $taskName -Action $action -Principal $principal -Settings $settings -Force | Out-Null

Write-Host "Starting countdown timer task..." -ForegroundColor Green
Start-ScheduledTask -TaskName $taskName

Write-Host "`n!!! LOOK AT YOUR SCREEN NOW !!!" -ForegroundColor Yellow -BackgroundColor Red
Write-Host "You should see:" -ForegroundColor Cyan
Write-Host "- A dialog titled 'Restart Required'" -ForegroundColor White
Write-Host "- A COUNTDOWN TIMER showing minutes:seconds" -ForegroundColor Green
Write-Host "- The timer counting down from $Minutes:00" -ForegroundColor Green
Write-Host "- Options to 'Restart Now' or 'Minimize'" -ForegroundColor White

# Let it run
Start-Sleep -Seconds ([timespan]::FromMinutes($Minutes).TotalSeconds + 10)

# Cleanup
Write-Host "`nCleaning up..." -ForegroundColor Yellow
Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
Remove-Item $tempScript -Force -ErrorAction SilentlyContinue

Write-Host "`nDone!" -ForegroundColor Green