#region Test Live Countdown from Scheduled Task
<#
.SYNOPSIS
    Creates a test scheduled task to verify live countdown from SYSTEM context
.DESCRIPTION
    Tests the live countdown functionality when running as SYSTEM
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$PSADTPath = 'C:\code\Windows\Win11UpgradeScheduler-FINAL\src'
)

# Create a test scheduled task with live countdown
$taskName = "TestLiveCountdown_$(Get-Date -Format 'yyyyMMddHHmmss')"
$triggerTime = (Get-Date).AddMinutes(1)

Write-Host "Creating test scheduled task: $taskName" -ForegroundColor Yellow
Write-Host "Trigger time: $triggerTime" -ForegroundColor Cyan
Write-Host "This will test the live countdown functionality from SYSTEM context" -ForegroundColor Yellow

try {
    # Create task action that will show the countdown dialog
    $wrapperScript = Join-Path -Path $PSADTPath -ChildPath 'SupportFiles\ScheduledTaskWrapper.ps1'
    
    # Create a simple test script that just shows the countdown
    $testScript = @"
# Load wrapper functions
. '$wrapperScript'

# Set up test environment
`$PSADTPath = '$PSADTPath'
`$script:LogPath = "`$env:ProgramData\Win11UpgradeScheduler\TestLogs"

# Test countdown dialog (2 minutes for quick testing)
Write-Host "Testing live countdown from SYSTEM context..."
Show-CountdownDialog -Minutes 2
Write-Host "Countdown test completed"
"@
    
    $tempTestScript = Join-Path -Path $env:TEMP -ChildPath "TestLiveCountdownSystem_$(Get-Date -Format 'yyyyMMddHHmmss').ps1"
    $testScript | Set-Content -Path $tempTestScript -Force
    
    $arguments = @(
        "-ExecutionPolicy Bypass"
        "-NoProfile"
        "-WindowStyle Hidden"
        "-File `"$tempTestScript`""
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
    Write-Host "Watch for the LIVE COUNTDOWN dialog to appear" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "To manually trigger the task now:" -ForegroundColor Cyan
    Write-Host "Start-ScheduledTask -TaskName '$taskName' -TaskPath '\Microsoft\Windows\Win11Upgrade'" -ForegroundColor Gray
    Write-Host ""
    Write-Host "To remove the task after testing:" -ForegroundColor Cyan
    Write-Host "Unregister-ScheduledTask -TaskName '$taskName' -TaskPath '\Microsoft\Windows\Win11Upgrade' -Confirm:`$false" -ForegroundColor Gray
    
    # Clean up the temp script after a delay
    Start-Sleep -Seconds 5
    Remove-Item -Path $tempTestScript -Force -ErrorAction SilentlyContinue
    
} catch {
    Write-Host "Error creating scheduled task: $_" -ForegroundColor Red
}
#endregion