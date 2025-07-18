# Check the actual scheduled time in the task
$task = Get-ScheduledTask -TaskName "Windows11UpgradeScheduled" -ErrorAction SilentlyContinue

if ($task) {
    Write-Host "Task found!" -ForegroundColor Green
    
    # Get the trigger time
    $trigger = $task.Triggers[0]
    Write-Host "`nTrigger Type: $($trigger.CimClass.CimClassName)" -ForegroundColor Cyan
    Write-Host "StartBoundary: $($trigger.StartBoundary)" -ForegroundColor Yellow
    
    # Parse the StartBoundary to readable format
    if ($trigger.StartBoundary) {
        try {
            $scheduledTime = [DateTime]::Parse($trigger.StartBoundary)
            Write-Host "`nScheduled to run at: $($scheduledTime.ToString('dddd, MMMM d, yyyy')) at $($scheduledTime.ToString('h:mm tt'))" -ForegroundColor Green
            
            # Compare to current time
            $hoursUntil = ($scheduledTime - (Get-Date)).TotalHours
            Write-Host "Hours until execution: $([math]::Round($hoursUntil, 1))" -ForegroundColor Cyan
        }
        catch {
            Write-Host "Could not parse StartBoundary: $_" -ForegroundColor Red
        }
    }
}
else {
    Write-Host "No scheduled task found" -ForegroundColor Red
}