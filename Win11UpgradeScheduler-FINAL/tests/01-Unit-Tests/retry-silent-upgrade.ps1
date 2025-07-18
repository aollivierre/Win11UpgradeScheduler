# Retry silent upgrade with proper VM specs
Write-Host "Retrying Windows 11 Silent Upgrade with proper VM specs..." -ForegroundColor Cyan

# Clean up old tasks
Get-ScheduledTask | Where-Object {$_.TaskName -like "*Win11*"} | Unregister-ScheduledTask -Confirm:$false

# Create new scheduled task
$taskName = "Win11SilentUpgrade_$(Get-Date -Format 'HHmmss')"
$exePath = "C:\Win11Upgrade\Windows11InstallationAssistant.exe"
$arguments = "/QuietInstall /SkipEULA"

Write-Host "`nCreating scheduled task: $taskName" -ForegroundColor Yellow
Write-Host "Command: $exePath $arguments" -ForegroundColor Yellow

$action = New-ScheduledTaskAction -Execute $exePath -Argument $arguments
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit (New-TimeSpan -Hours 3)

Register-ScheduledTask -TaskName $taskName -Action $action -Principal $principal -Settings $settings -Force | Out-Null

Write-Host "Starting upgrade task..." -ForegroundColor Green
Start-ScheduledTask -TaskName $taskName

# Monitor for 30 seconds
$endTime = (Get-Date).AddSeconds(30)
$foundProcess = $false

while ((Get-Date) -lt $endTime) {
    $process = Get-Process -Name "Windows11InstallationAssistant" -ErrorAction SilentlyContinue
    if ($process) {
        if (-not $foundProcess) {
            Write-Host "`nProcess started! PID: $($process.Id)" -ForegroundColor Green
            $foundProcess = $true
        }
        
        # Check if upgrade folder is growing
        if (Test-Path "C:\`$WINDOWS.~BT") {
            $size = (Get-ChildItem "C:\`$WINDOWS.~BT" -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1MB
            Write-Host "Upgrade folder size: $([math]::Round($size, 2)) MB" -ForegroundColor Yellow
        }
    }
    Start-Sleep -Seconds 5
}

# Final status
$task = Get-ScheduledTask -TaskName $taskName
$info = $task | Get-ScheduledTaskInfo
Write-Host "`nTask State: $($task.State)" -ForegroundColor Cyan
Write-Host "Last Result: 0x$($info.LastTaskResult.ToString('X'))" -ForegroundColor Cyan

if (Get-Process -Name "Windows11InstallationAssistant" -ErrorAction SilentlyContinue) {
    Write-Host "`nUpgrade process is running!" -ForegroundColor Green
} else {
    Write-Host "`nProcess not running - checking for UI window..." -ForegroundColor Yellow
}