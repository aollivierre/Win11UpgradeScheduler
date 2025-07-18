# Check for Installation Assistant specific logs
Write-Host "CHECKING INSTALLATION ASSISTANT LOGS AND ARTIFACTS" -ForegroundColor Cyan
Write-Host ("=" * 50) -ForegroundColor Cyan

# Check event logs for Installation Assistant
Write-Host "`nChecking Event Logs for Installation Assistant:" -ForegroundColor Yellow
try {
    $events = Get-WinEvent -FilterHashtable @{LogName='Application'; ProviderName='*Windows*11*Installation*'} -MaxEvents 10 -ErrorAction SilentlyContinue
    if ($events) {
        Write-Host "Found Installation Assistant events:" -ForegroundColor Green
        $events | Select-Object -First 5 | ForEach-Object {
            Write-Host "  $($_.TimeCreated): $($_.Message.Substring(0, [Math]::Min(100, $_.Message.Length)))..." -ForegroundColor Gray
        }
    }
} catch {}

# Check specific Installation Assistant locations
Write-Host "`nChecking Installation Assistant file locations:" -ForegroundColor Yellow
$locations = @(
    "C:\Program Files\Windows 11 Installation Assistant",
    "C:\Program Files (x86)\Windows 11 Installation Assistant",
    "$env:LOCALAPPDATA\Microsoft\Windows11InstallationAssistant",
    "$env:TEMP\Windows11InstallationAssistant"
)

foreach ($loc in $locations) {
    if (Test-Path $loc) {
        Write-Host "FOUND: $loc" -ForegroundColor Green
        Get-ChildItem $loc -ErrorAction SilentlyContinue | Select-Object -First 5 | ForEach-Object {
            Write-Host "  - $($_.Name) (Modified: $($_.LastWriteTime))" -ForegroundColor Gray
        }
    }
}

# Check scheduled task history
Write-Host "`nChecking Scheduled Task History:" -ForegroundColor Yellow
$task = Get-ScheduledTask -TaskName "Win11SilentUpgrade_183436" -ErrorAction SilentlyContinue
if ($task) {
    $info = $task | Get-ScheduledTaskInfo
    Write-Host "Task: $($task.TaskName)" -ForegroundColor Green
    Write-Host "  State: $($task.State)" -ForegroundColor Yellow
    Write-Host "  Last Run Time: $($info.LastRunTime)" -ForegroundColor Yellow
    Write-Host "  Last Result: 0x$($info.LastTaskResult.ToString('X'))" -ForegroundColor Yellow
    
    if ($info.LastTaskResult -eq 0) {
        Write-Host "  EVIDENCE: Task completed successfully!" -ForegroundColor Green
    }
}

# Check Windows Setup logs
Write-Host "`nChecking Windows Setup Logs:" -ForegroundColor Yellow
$setupLog = "C:\Windows\Panther\setupact.log"
if (Test-Path $setupLog) {
    $assistantRefs = Select-String -Path $setupLog -Pattern "Windows11InstallationAssistant" -SimpleMatch
    if ($assistantRefs) {
        Write-Host "FOUND Installation Assistant references in setup log:" -ForegroundColor Green
        Write-Host "  Count: $($assistantRefs.Count) references" -ForegroundColor Yellow
    }
}