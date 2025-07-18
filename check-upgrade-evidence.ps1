#region Check for Concrete Evidence of Windows 11 Upgrade

Write-Host "SEARCHING FOR CONCRETE EVIDENCE OF UPGRADE..." -ForegroundColor Yellow
Write-Host ("=" * 60) -ForegroundColor Yellow

#region Check Process Activity
Write-Host "`n1. PROCESS ACTIVITY CHECK:" -ForegroundColor Cyan
$process = Get-Process -Name "Windows11InstallationAssistant" -ErrorAction SilentlyContinue
if ($process) {
    Write-Host "Process Status: RUNNING (PID: $($process.Id))" -ForegroundColor Green
    $wmi = Get-WmiObject Win32_Process -Filter "ProcessId = $($process.Id)"
    $perfData = Get-WmiObject Win32_PerfFormattedData_PerfProc_Process -Filter "IDProcess = $($process.Id)" -ErrorAction SilentlyContinue
    if ($perfData) {
        Write-Host "CPU Usage: $($perfData.PercentProcessorTime)%"
        Write-Host "Working Set: $([math]::Round($process.WorkingSet64 / 1MB, 2)) MB"
        Write-Host "Virtual Memory: $([math]::Round($process.VirtualMemorySize64 / 1MB, 2)) MB"
    }
} else {
    Write-Host "Process Status: NOT FOUND!" -ForegroundColor Red
}
#endregion

#region Check for Windows Upgrade Folders
Write-Host "`n2. WINDOWS UPGRADE FOLDERS:" -ForegroundColor Cyan
$upgradeFolders = @(
    "C:\`$WINDOWS.~BT",
    "C:\`$WINDOWS.~WS", 
    "C:\Windows10Upgrade",
    "C:\ESD",
    "$env:LOCALAPPDATA\Microsoft\Windows10Upgrade"
)

$foundEvidence = $false
foreach ($folder in $upgradeFolders) {
    if (Test-Path $folder) {
        $foundEvidence = $true
        $info = Get-Item $folder -Force
        Write-Host "FOUND: $folder" -ForegroundColor Green
        Write-Host "  Created: $($info.CreationTime)"
        Write-Host "  Modified: $($info.LastWriteTime)"
        
        # Check size
        try {
            $size = (Get-ChildItem $folder -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1GB
            Write-Host "  Size: $([math]::Round($size, 2)) GB" -ForegroundColor Yellow
        } catch {}
    }
}

if (-not $foundEvidence) {
    Write-Host "No Windows upgrade folders found yet" -ForegroundColor Red
}
#endregion

#region Check Installation Assistant Logs
Write-Host "`n3. INSTALLATION ASSISTANT LOGS:" -ForegroundColor Cyan
$logLocations = @(
    "$env:LOCALAPPDATA\Microsoft\Windows11InstallationAssistant",
    "$env:TEMP\Windows11InstallationAssistant",
    "C:\Win11Upgrade"
)

foreach ($location in $logLocations) {
    if (Test-Path $location) {
        Write-Host "Checking: $location" -ForegroundColor Yellow
        Get-ChildItem $location -Filter "*.log" -ErrorAction SilentlyContinue | ForEach-Object {
            Write-Host "  LOG: $($_.Name) (Size: $([math]::Round($_.Length / 1KB, 2)) KB)" -ForegroundColor Green
            Write-Host "  Modified: $($_.LastWriteTime)"
        }
    }
}
#endregion

#region Check Network Activity
Write-Host "`n4. NETWORK CONNECTIONS (Download Activity):" -ForegroundColor Cyan
try {
    $connections = netstat -an | Select-String "11028" | Select-String "ESTABLISHED"
    if ($connections) {
        Write-Host "Active network connections found for PID 11028:" -ForegroundColor Green
        $connections | ForEach-Object { Write-Host "  $_" }
    } else {
        Write-Host "No active network connections for this process" -ForegroundColor Yellow
    }
} catch {}
#endregion

#region Check Disk Activity
Write-Host "`n5. RECENT FILE ACTIVITY:" -ForegroundColor Cyan
$recentFiles = Get-ChildItem C:\ -Recurse -ErrorAction SilentlyContinue | 
    Where-Object { $_.LastWriteTime -gt (Get-Date).AddMinutes(-15) -and $_.Name -like "*Windows*11*" } |
    Select-Object -First 10

if ($recentFiles) {
    Write-Host "Recently modified Windows 11 related files:" -ForegroundColor Green
    $recentFiles | ForEach-Object {
        Write-Host "  $($_.FullName) - $($_.LastWriteTime)" -ForegroundColor Yellow
    }
}
#endregion

Write-Host "`nCONCLUSION:" -ForegroundColor Cyan
if ($process -and $foundEvidence) {
    Write-Host "UPGRADE IS ACTIVELY RUNNING - Evidence found!" -ForegroundColor Green
} elseif ($process) {
    Write-Host "Process is running but no file evidence yet - may still be initializing" -ForegroundColor Yellow
} else {
    Write-Host "Cannot confirm upgrade is running" -ForegroundColor Red
}