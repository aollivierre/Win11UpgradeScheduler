# Check scheduled task details
$task = Get-ScheduledTask -TaskName 'Windows11UpgradeScheduled' -ErrorAction SilentlyContinue
if ($task) {
    Write-Host "Task Name: $($task.TaskName)" -ForegroundColor Cyan
    Write-Host "State: $($task.State)" -ForegroundColor Green
    Write-Host "Path: $($task.TaskPath)" -ForegroundColor Gray
    
    $trigger = $task.Triggers[0]
    Write-Host "`nTrigger Details:" -ForegroundColor Yellow
    Write-Host "Start Time: $($trigger.StartBoundary)" -ForegroundColor Green
    Write-Host "Enabled: $($trigger.Enabled)" -ForegroundColor Gray
    
    $action = $task.Actions[0]
    Write-Host "`nAction Details:" -ForegroundColor Yellow
    Write-Host "Execute: $($action.Execute)" -ForegroundColor Gray
    Write-Host "Arguments: $($action.Arguments)" -ForegroundColor Gray
}