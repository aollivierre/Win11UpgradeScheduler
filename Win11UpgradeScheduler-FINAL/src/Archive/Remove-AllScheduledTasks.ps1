# Remove all Windows 11 upgrade scheduled tasks
$tasks = Get-ScheduledTask | Where-Object {$_.TaskName -like "*Win11*" -and $_.TaskPath -like "*Win11Upgrade*"}

foreach ($task in $tasks) {
    try {
        Unregister-ScheduledTask -TaskName $task.TaskName -Confirm:$false
        Write-Host "Removed task: $($task.TaskName)" -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to remove task $($task.TaskName): $_" -ForegroundColor Red
    }
}

Write-Host "`nAll Windows 11 upgrade tasks removed" -ForegroundColor Cyan