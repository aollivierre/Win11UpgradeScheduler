# Check scheduled task details
$task = Get-ScheduledTask -TaskName 'Windows11UpgradeScheduled' -ErrorAction SilentlyContinue

if ($task) {
    Write-Host "Task Name: $($task.TaskName)" -ForegroundColor Green
    Write-Host "State: $($task.State)" -ForegroundColor Green
    Write-Host "Task Path: $($task.TaskPath)" -ForegroundColor Green
    
    $taskInfo = Get-ScheduledTaskInfo -TaskName $task.TaskName
    Write-Host "Next Run Time: $($taskInfo.NextRunTime)" -ForegroundColor Yellow
    Write-Host "Last Run Time: $($taskInfo.LastRunTime)" -ForegroundColor Cyan
    Write-Host "Last Task Result: $($taskInfo.LastTaskResult)" -ForegroundColor Cyan
    
    # Get the action details
    $action = $task.Actions[0]
    Write-Host "`nAction Details:" -ForegroundColor Magenta
    Write-Host "Execute: $($action.Execute)" -ForegroundColor White
    Write-Host "Arguments: $($action.Arguments)" -ForegroundColor White
}
else {
    Write-Host "Scheduled task 'Windows11UpgradeScheduled' not found" -ForegroundColor Red
}