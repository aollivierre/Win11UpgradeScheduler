# Check Windows 11 Upgrade Status
Write-Host "Checking Windows 11 Upgrade Status..." -ForegroundColor Cyan
Write-Host ("=" * 50) -ForegroundColor Cyan

# Check for running processes
Write-Host "`nChecking for Windows 11 processes:"
$processes = Get-Process | Where-Object { $_.Name -like '*Windows11*' -or $_.Name -like '*Installation*' }
if ($processes) {
    $processes | Format-Table Name, Id, StartTime -AutoSize
} else {
    Write-Host "No Windows 11 Installation Assistant processes found!" -ForegroundColor Yellow
}

# Check scheduled tasks
Write-Host "`nChecking scheduled tasks:"
$tasks = Get-ScheduledTask | Where-Object { $_.TaskName -like '*Win11*' }
foreach ($task in $tasks) {
    Write-Host "Task: $($task.TaskName)" -ForegroundColor Green
    $info = $task | Get-ScheduledTaskInfo
    Write-Host "  State: $($task.State)"
    Write-Host "  Last Run Time: $($info.LastRunTime)"
    Write-Host "  Last Result: 0x$($info.LastTaskResult.ToString('X'))"
    Write-Host "  Next Run Time: $($info.NextRunTime)"
}

# Check if installer exists
Write-Host "`nChecking installer locations:"
$locations = @(
    "C:\Temp\Windows11InstallationAssistant.exe",
    "C:\Win11Upgrade\Windows11InstallationAssistant.exe",
    "C:\Win11.exe"
)
foreach ($path in $locations) {
    if (Test-Path $path) {
        $file = Get-Item $path
        Write-Host "Found: $path (Size: $([math]::Round($file.Length / 1MB, 2)) MB)" -ForegroundColor Green
    }
}

# Check Windows Update status
Write-Host "`nChecking Windows Update status:"
try {
    $updateSession = New-Object -ComObject Microsoft.Update.Session
    $updateSearcher = $updateSession.CreateUpdateSearcher()
    $searchResult = $updateSearcher.Search("IsInstalled=0")
    Write-Host "Pending updates: $($searchResult.Updates.Count)"
} catch {
    Write-Host "Could not check Windows Update status" -ForegroundColor Yellow
}