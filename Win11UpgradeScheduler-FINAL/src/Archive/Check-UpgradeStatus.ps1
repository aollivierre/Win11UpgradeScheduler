# Check Windows 11 upgrade status
Write-Host "=== Windows 11 Upgrade Status ===" -ForegroundColor Cyan

# Check for Installation Assistant process
$process = Get-Process -Name "*Windows11InstallationAssistant*" -ErrorAction SilentlyContinue
if ($process) {
    Write-Host "`nInstallation Assistant Running:" -ForegroundColor Green
    Write-Host "  PID: $($process.Id)"
    Write-Host "  Start Time: $($process.StartTime)"
    Write-Host "  CPU Time: $($process.TotalProcessorTime)"
}
else {
    Write-Host "`nInstallation Assistant: Not running" -ForegroundColor Yellow
}

# Check for upgrade folder
$upgradeFolder = "C:\`$WINDOWS.~BT"
if (Test-Path $upgradeFolder) {
    Write-Host "`nUpgrade Folder Found: $upgradeFolder" -ForegroundColor Green
    $size = (Get-ChildItem $upgradeFolder -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1GB
    Write-Host "  Size: $([math]::Round($size, 2)) GB" -ForegroundColor White
}
else {
    Write-Host "`nUpgrade Folder: Not found" -ForegroundColor Yellow
}

# Check for scheduled tasks
Write-Host "`nScheduled Tasks:" -ForegroundColor Cyan
$tasks = Get-ScheduledTask | Where-Object {$_.TaskName -like "*Win11*"}
foreach ($task in $tasks) {
    Write-Host "  Task: $($task.TaskName)" -ForegroundColor White
    Write-Host "    State: $($task.State)" -ForegroundColor $(if ($task.State -eq 'Running') {'Green'} else {'Yellow'})
}