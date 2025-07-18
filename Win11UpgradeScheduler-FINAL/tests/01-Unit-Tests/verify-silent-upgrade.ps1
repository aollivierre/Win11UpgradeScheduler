#region Verify Silent Windows 11 Upgrade Details

Write-Host "`nWindows 11 Silent Upgrade Analysis" -ForegroundColor Cyan
Write-Host ("=" * 60) -ForegroundColor Cyan

#region Process Details
$process = Get-Process -Name "Windows11InstallationAssistant" -ErrorAction SilentlyContinue
if ($process) {
    Write-Host "`nProcess Found!" -ForegroundColor Green
    Write-Host "PID: $($process.Id)"
    Write-Host "Start Time: $($process.StartTime)"
    
    # Get command line via WMI
    $wmiProcess = Get-WmiObject Win32_Process -Filter "ProcessId = $($process.Id)"
    Write-Host "Command Line: $($wmiProcess.CommandLine)" -ForegroundColor Yellow
    Write-Host "Executable: $($wmiProcess.ExecutablePath)"
    
    # Check who owns the process
    $owner = $wmiProcess.GetOwner()
    Write-Host "Running As: $($owner.Domain)\$($owner.User)" -ForegroundColor Magenta
    
    # Parent process
    $parent = Get-Process -Id $wmiProcess.ParentProcessId -ErrorAction SilentlyContinue
    Write-Host "Parent Process: $($parent.Name) (PID: $($wmiProcess.ParentProcessId))"
}
#endregion

#region Scheduled Task Details
Write-Host "`nScheduled Task Details:" -ForegroundColor Cyan
$tasks = Get-ScheduledTask | Where-Object { $_.TaskName -like '*Win11*' }
foreach ($task in $tasks) {
    Write-Host "`nTask: $($task.TaskName)" -ForegroundColor Green
    Write-Host "State: $($task.State)"
    Write-Host "Principal: $($task.Principal.UserId)"
    Write-Host "Run Level: $($task.Principal.RunLevel)"
    
    # Get the action details
    $task.Actions | ForEach-Object {
        Write-Host "Execute: $($_.Execute)"
        Write-Host "Arguments: $($_.Arguments)" -ForegroundColor Yellow
    }
}
#endregion

#region How This Works
Write-Host "`nHOW THE SILENT UPGRADE WORKS:" -ForegroundColor Cyan
Write-Host @"

1. COMMAND LINE PARAMETERS:
   - /QuietInstall = No UI, completely silent
   - /SkipEULA = Attempts to bypass license agreement

2. RUNNING AS SYSTEM:
   - Scheduled task runs as SYSTEM account
   - SYSTEM context appears to bypass EULA requirement
   - No user interaction possible or needed

3. WHAT'S HAPPENING NOW:
   - Downloading Windows 11 files in background
   - Preparing upgrade silently
   - Will auto-restart when ready
   - Total process: 30-90 minutes

4. THIS IS FULLY SILENT - NO PROMPTS!
"@ -ForegroundColor Green
#endregion

Write-Host "`nTo stop the upgrade: schtasks /delete /tn 'Win11UpgradeTest_20250716180339' /f" -ForegroundColor Red