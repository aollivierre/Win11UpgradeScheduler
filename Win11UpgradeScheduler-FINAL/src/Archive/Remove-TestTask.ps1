# Remove test scheduled task
try {
    Unregister-ScheduledTask -TaskName 'Windows11UpgradeScheduled' -Confirm:$false -ErrorAction Stop
    Write-Host "Successfully removed scheduled task" -ForegroundColor Green
}
catch {
    Write-Host "Failed to remove task: $_" -ForegroundColor Red
}