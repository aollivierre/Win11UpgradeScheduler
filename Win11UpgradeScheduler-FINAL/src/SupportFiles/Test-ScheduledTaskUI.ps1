# Test script to verify scheduled task UI visibility
Write-Host "Testing scheduled task UI visibility..." -ForegroundColor Cyan

# Get the scheduled task
$task = Get-ScheduledTask -TaskName "Windows11UpgradeScheduled" -ErrorAction SilentlyContinue

if ($task) {
    Write-Host "`nTask found: $($task.TaskName)" -ForegroundColor Green
    Write-Host "State: $($task.State)" -ForegroundColor Yellow
    
    # Check if running as SYSTEM
    $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
    Write-Host "`nCurrent user context: $currentUser" -ForegroundColor Cyan
    
    # Check session
    $sessionId = [System.Diagnostics.Process]::GetCurrentProcess().SessionId
    Write-Host "Session ID: $sessionId" -ForegroundColor Cyan
    
    if ($sessionId -eq 0) {
        Write-Host "`nWARNING: Running in Session 0 (non-interactive)" -ForegroundColor Red
        Write-Host "UI will not be visible to logged-in users!" -ForegroundColor Red
        Write-Host "`nFor attended sessions, the task needs to either:" -ForegroundColor Yellow
        Write-Host "1. Use ServiceUI.exe to show UI in user session" -ForegroundColor White
        Write-Host "2. Run in user context instead of SYSTEM" -ForegroundColor White
        Write-Host "3. Use PSADT's Execute-ProcessAsUser function" -ForegroundColor White
    }
    else {
        Write-Host "`nRunning in interactive session - UI should be visible" -ForegroundColor Green
    }
    
    # Show task action
    Write-Host "`nTask Action:" -ForegroundColor Cyan
    $task.Actions | ForEach-Object {
        Write-Host "  Execute: $($_.Execute)" -ForegroundColor White
        Write-Host "  Arguments: $($_.Arguments)" -ForegroundColor White
    }
}
else {
    Write-Host "No scheduled task found" -ForegroundColor Red
}