# Real-time monitoring of upgrade activity
Write-Host "MONITORING UPGRADE ACTIVITY..." -ForegroundColor Yellow

# Check if process is still alive
$process = Get-Process -Id 11028 -ErrorAction SilentlyContinue
if (-not $process) {
    Write-Host "PROCESS 11028 IS NO LONGER RUNNING!" -ForegroundColor Red
    
    # Check if a new process started
    $newProcess = Get-Process -Name "*Windows11*" -ErrorAction SilentlyContinue
    if ($newProcess) {
        Write-Host "Found new process: $($newProcess.Name) PID: $($newProcess.Id)" -ForegroundColor Green
    }
    
    # Check event log for errors
    Write-Host "`nChecking Event Log for Installation Assistant events..."
    Get-EventLog -LogName Application -Source "*Windows11*" -Newest 10 -ErrorAction SilentlyContinue | 
        Select-Object TimeGenerated, Message | Format-List
        
    # Check if computer is preparing to restart
    $pending = Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending"
    if ($pending) {
        Write-Host "`nREBOOT PENDING - Upgrade may have completed first phase!" -ForegroundColor Green
    }
} else {
    Write-Host "Process still running. Checking activity..." -ForegroundColor Green
    
    # Get handles to see what files it's accessing
    Write-Host "`nChecking file handles..."
    $handles = & handle.exe -p 11028 2>$null
    if ($handles) {
        Write-Host "Process has open handles (working on files)"
    }
    
    # Check child processes
    $children = Get-WmiObject Win32_Process -Filter "ParentProcessId = 11028"
    if ($children) {
        Write-Host "`nChild processes spawned:" -ForegroundColor Yellow
        $children | ForEach-Object { Write-Host "  - $($_.Name) (PID: $($_.ProcessId))" }
    }
}

# Final check - look for ANY Windows 11 related activity
Write-Host "`nSearching for ANY Windows 11 upgrade evidence..."
$locations = @(
    "$env:TEMP",
    "$env:LOCALAPPDATA\Temp",
    "C:\ProgramData"
)

$found = $false
foreach ($loc in $locations) {
    $files = Get-ChildItem $loc -Filter "*Windows11*" -Recurse -ErrorAction SilentlyContinue -Force | 
             Where-Object { $_.LastWriteTime -gt (Get-Date).AddMinutes(-30) }
    if ($files) {
        $found = $true
        Write-Host "`nFound in $loc`:" -ForegroundColor Green
        $files | ForEach-Object { Write-Host "  $($_.FullName)" -ForegroundColor Yellow }
    }
}