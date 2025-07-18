# Create a scheduled task to run in 1 minute for immediate testing
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath 'SupportFiles\Modules\01-UpgradeScheduler.psm1'
Import-Module $modulePath -Force

# Schedule for 3 hours from now (minimum required)
$scheduleTime = (Get-Date).AddHours(3)

Write-Host "Creating scheduled task for: $scheduleTime" -ForegroundColor Cyan

try {
    New-UpgradeSchedule -ScheduleTime $scheduleTime `
        -PSADTPath $PSScriptRoot `
        -DeploymentType 'Install' `
        -DeployMode 'Interactive'
    
    Write-Host "`nScheduled task created successfully!" -ForegroundColor Green
    
    # Check the task
    $task = Get-ScheduledTask -TaskName "Windows11UpgradeScheduled" -ErrorAction SilentlyContinue
    if ($task) {
        Write-Host "`nTask Details:" -ForegroundColor Yellow
        Write-Host "  Execute: $($task.Actions[0].Execute)" -ForegroundColor White
        Write-Host "  Arguments: $($task.Actions[0].Arguments)" -ForegroundColor White
        
        if ($task.Actions[0].Execute -like "*ServiceUI.exe") {
            Write-Host "`nTask is using ServiceUI.exe - UI should be visible!" -ForegroundColor Green
        }
        else {
            Write-Host "`nTask is NOT using ServiceUI.exe" -ForegroundColor Red
        }
    }
}
catch {
    Write-Host "Failed to create scheduled task: $_" -ForegroundColor Red
}