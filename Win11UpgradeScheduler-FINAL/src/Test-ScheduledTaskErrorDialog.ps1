#region Test Scheduled Task Error Dialog
<#
.SYNOPSIS
    Creates a test scheduled task to verify error dialog display from SYSTEM context
.DESCRIPTION
    This replicates the exact scenario where the scheduled task runs as SYSTEM
    and encounters a pre-flight check failure, then displays an error dialog
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$PSADTPath = 'C:\code\Windows\Win11UpgradeScheduler-FINAL\src'
)

# Import the scheduler module
$modulePath = Join-Path -Path $PSADTPath -ChildPath 'SupportFiles\Modules\01-UpgradeScheduler.psm1'
if (Test-Path -Path $modulePath) {
    Import-Module -Name $modulePath -Force
}

# Create a test scheduled task that will trigger the error dialog
$taskName = "TestServiceUIFix_$(Get-Date -Format 'yyyyMMddHHmmss')"
$triggerTime = (Get-Date).AddMinutes(1)

Write-Host "Creating test scheduled task: $taskName" -ForegroundColor Yellow
Write-Host "Trigger time: $triggerTime" -ForegroundColor Cyan
Write-Host "This will run the wrapper script as SYSTEM and should show error dialog due to pending reboot" -ForegroundColor Yellow

try {
    # Create task action - this will run as SYSTEM
    $wrapperScript = Join-Path -Path $PSADTPath -ChildPath 'SupportFiles\ScheduledTaskWrapper.ps1'
    
    $arguments = @(
        "-ExecutionPolicy Bypass"
        "-NoProfile"
        "-WindowStyle Hidden"
        "-File `"$wrapperScript`""
        "-PSADTPath `"$PSADTPath`""
        "-DeploymentType Install"
        "-DeployMode Interactive"
    )
    
    $taskAction = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument ($arguments -join ' ')
    $taskTrigger = New-ScheduledTaskTrigger -Once -At $triggerTime
    $taskPrincipal = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType ServiceAccount -RunLevel Highest
    $taskSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -WakeToRun
    
    # Register the task
    $task = Register-ScheduledTask `
        -TaskName $taskName `
        -TaskPath '\Microsoft\Windows\Win11Upgrade' `
        -Action $taskAction `
        -Trigger $taskTrigger `
        -Principal $taskPrincipal `
        -Settings $taskSettings `
        -Force
    
    Write-Host "Task created successfully!" -ForegroundColor Green
    Write-Host "Task will run at: $triggerTime" -ForegroundColor Yellow
    Write-Host "Watch for the error dialog to appear showing the pending reboot message" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "To check task status:" -ForegroundColor Cyan
    Write-Host "Get-ScheduledTask -TaskName '$taskName' -TaskPath '\Microsoft\Windows\Win11Upgrade'" -ForegroundColor Gray
    Write-Host ""
    Write-Host "To manually trigger the task now:" -ForegroundColor Cyan
    Write-Host "Start-ScheduledTask -TaskName '$taskName' -TaskPath '\Microsoft\Windows\Win11Upgrade'" -ForegroundColor Gray
    Write-Host ""
    Write-Host "To remove the task after testing:" -ForegroundColor Cyan
    Write-Host "Unregister-ScheduledTask -TaskName '$taskName' -TaskPath '\Microsoft\Windows\Win11Upgrade' -Confirm:`$false" -ForegroundColor Gray
    
} catch {
    Write-Host "Error creating scheduled task: $_" -ForegroundColor Red
}
#endregion