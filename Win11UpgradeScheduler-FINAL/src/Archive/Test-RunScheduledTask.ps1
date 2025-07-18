# Test running the scheduled task immediately
Write-Host "Starting Windows 11 Upgrade scheduled task..." -ForegroundColor Cyan

try {
    Start-ScheduledTask -TaskName "Windows11UpgradeScheduled"
    Write-Host "`nTask started successfully!" -ForegroundColor Green
    Write-Host "You should now see UI elements in your session." -ForegroundColor Yellow
    Write-Host "`nCheck for:" -ForegroundColor Cyan
    Write-Host "  1. Countdown dialog (if attended session)" -ForegroundColor White
    Write-Host "  2. Pre-flight checks progress" -ForegroundColor White
    Write-Host "  3. Upgrade information dialogs" -ForegroundColor White
    
    Write-Host "`nMonitoring task status..." -ForegroundColor Cyan
    for ($i = 0; $i -lt 10; $i++) {
        Start-Sleep -Seconds 3
        $task = Get-ScheduledTask -TaskName "Windows11UpgradeScheduled"
        $taskInfo = Get-ScheduledTaskInfo -TaskName "Windows11UpgradeScheduled"
        Write-Host "  Status: $($task.State) | Last Result: $($taskInfo.LastTaskResult)" -ForegroundColor Gray
        
        if ($task.State -ne 'Running') {
            break
        }
    }
}
catch {
    Write-Host "Failed to start task: $_" -ForegroundColor Red
}

# Check logs
Write-Host "`nChecking logs..." -ForegroundColor Cyan
$logPath = "C:\ProgramData\Win11UpgradeScheduler\Logs"
$latestLog = Get-ChildItem "$logPath\TaskWrapper_*.log" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1

if ($latestLog) {
    Write-Host "`nLatest wrapper log entries:" -ForegroundColor Yellow
    Get-Content $latestLog.FullName -Tail 10 | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
}