# Create a scheduled task to test the wrapper as SYSTEM
$taskAction = New-ScheduledTaskAction -Execute "PowerShell.exe" `
    -Argument "-ExecutionPolicy Bypass -File `"C:\code\Win11UpgradeScheduler\Win11UpgradeScheduler-FINAL\src\SupportFiles\ScheduledTaskWrapper.ps1`" -PSADTPath `"C:\code\Win11UpgradeScheduler\Win11UpgradeScheduler-FINAL\src`""

$taskPrincipal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -RunLevel Highest
$taskSettings = New-ScheduledTaskSettings -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries

# Unregister if exists
Unregister-ScheduledTask -TaskName "TestWin11UpgradeUI" -Confirm:$false -ErrorAction SilentlyContinue

# Register new task
Register-ScheduledTask -TaskName "TestWin11UpgradeUI" `
    -Action $taskAction `
    -Principal $taskPrincipal `
    -Settings $taskSettings `
    -Force

Write-Host "Scheduled task 'TestWin11UpgradeUI' created successfully."
Write-Host "Run it with: Start-ScheduledTask -TaskName 'TestWin11UpgradeUI'"