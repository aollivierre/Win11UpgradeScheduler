# Remove existing scheduled task
try {
    Unregister-ScheduledTask -TaskName 'Windows11UpgradeScheduled' -Confirm:$false
    Write-Host "Task removed successfully" -ForegroundColor Green
} catch {
    Write-Host "Task not found or error removing: $_" -ForegroundColor Yellow
}