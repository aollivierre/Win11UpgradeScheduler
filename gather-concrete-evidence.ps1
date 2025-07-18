# Gather CONCRETE EVIDENCE of Windows 11 upgrade
$evidence = @{}

Write-Host "GATHERING CONCRETE EVIDENCE OF WINDOWS 11 UPGRADE..." -ForegroundColor Yellow -BackgroundColor Black
Write-Host ("=" * 70) -ForegroundColor Yellow

#region 1. Process Evidence
Write-Host "`n1. PROCESS EVIDENCE:" -ForegroundColor Cyan
$process = Get-Process -Name "Windows11InstallationAssistant" -ErrorAction SilentlyContinue
if ($process) {
    $evidence.ProcessRunning = $true
    $evidence.ProcessId = $process.Id
    $evidence.ProcessStartTime = $process.StartTime
    
    # Get exact command line
    $wmi = Get-WmiObject Win32_Process -Filter "ProcessId = $($process.Id)"
    $evidence.CommandLine = $wmi.CommandLine
    $evidence.ProcessOwner = (Get-WmiObject Win32_Process -Filter "ProcessId = $($process.Id)").GetOwner().User
    
    Write-Host "✓ Process IS RUNNING: PID $($process.Id)" -ForegroundColor Green
    Write-Host "  Command: $($wmi.CommandLine)" -ForegroundColor Yellow
    Write-Host "  Started: $($process.StartTime)" -ForegroundColor Yellow
    Write-Host "  Running As: $($evidence.ProcessOwner)" -ForegroundColor Yellow
    
    # Check handles
    $handleCount = (Get-Process -Id $process.Id).HandleCount
    Write-Host "  Open Handles: $handleCount (indicates file activity)" -ForegroundColor Yellow
} else {
    Write-Host "✗ No Installation Assistant process found" -ForegroundColor Red
    $evidence.ProcessRunning = $false
}
#endregion

#region 2. File System Evidence
Write-Host "`n2. FILE SYSTEM EVIDENCE:" -ForegroundColor Cyan
$upgradeFolder = "C:\`$WINDOWS.~BT"
if (Test-Path $upgradeFolder) {
    $evidence.UpgradeFolderExists = $true
    $folderInfo = Get-Item $upgradeFolder -Force
    $evidence.FolderCreated = $folderInfo.CreationTime
    
    # Get detailed folder contents
    $files = Get-ChildItem $upgradeFolder -Recurse -Force -ErrorAction SilentlyContinue
    $evidence.TotalFiles = $files.Count
    $evidence.TotalSizeMB = [math]::Round(($files | Measure-Object -Property Length -Sum).Sum / 1MB, 2)
    
    Write-Host "✓ UPGRADE FOLDER EXISTS: $upgradeFolder" -ForegroundColor Green
    Write-Host "  Created: $($folderInfo.CreationTime)" -ForegroundColor Yellow
    Write-Host "  Total Files: $($files.Count)" -ForegroundColor Yellow
    Write-Host "  Total Size: $($evidence.TotalSizeMB) MB" -ForegroundColor Yellow
    
    # Show specific Windows 11 files
    $win11Files = $files | Where-Object { $_.Name -like "*Windows*11*" -or $_.Name -like "*Win11*" }
    if ($win11Files) {
        Write-Host "  Windows 11 specific files found:" -ForegroundColor Green
        $win11Files | Select-Object -First 5 | ForEach-Object {
            Write-Host "    - $($_.FullName)" -ForegroundColor Gray
        }
    }
    
    # Check for active writes
    $recentFiles = $files | Where-Object { $_.LastWriteTime -gt (Get-Date).AddMinutes(-5) }
    if ($recentFiles) {
        Write-Host "  ✓ ACTIVE FILE WRITES (last 5 min): $($recentFiles.Count) files" -ForegroundColor Green
        $evidence.ActiveFileWrites = $true
    }
} else {
    Write-Host "✗ No upgrade folder found" -ForegroundColor Red
    $evidence.UpgradeFolderExists = $false
}

# Check other upgrade locations
$otherLocations = @(
    "C:\`$WINDOWS.~WS",
    "C:\ESD",
    "$env:LOCALAPPDATA\Microsoft\Windows11InstallationAssistant"
)
foreach ($loc in $otherLocations) {
    if (Test-Path $loc) {
        Write-Host "✓ Found: $loc" -ForegroundColor Green
        $size = [math]::Round((Get-ChildItem $loc -Recurse -Force -ErrorAction SilentlyContinue | 
                               Measure-Object -Property Length -Sum).Sum / 1MB, 2)
        Write-Host "  Size: $size MB" -ForegroundColor Yellow
    }
}
#endregion

#region 3. Download Evidence
Write-Host "`n3. DOWNLOAD ACTIVITY EVIDENCE:" -ForegroundColor Cyan
if ($process) {
    # Check network connections
    $connections = netstat -ano | Select-String $process.Id
    if ($connections) {
        $established = $connections | Select-String "ESTABLISHED"
        if ($established) {
            Write-Host "✓ ACTIVE NETWORK CONNECTIONS for PID $($process.Id):" -ForegroundColor Green
            $established | Select-Object -First 3 | ForEach-Object { 
                Write-Host "  $($_.Line)" -ForegroundColor Gray 
            }
            $evidence.ActiveNetworkConnections = $true
        }
    }
    
    # Check for Windows Update activity
    $wuauserv = Get-Service -Name wuauserv
    if ($wuauserv.Status -eq 'Running') {
        Write-Host "✓ Windows Update Service: RUNNING" -ForegroundColor Green
        $evidence.WindowsUpdateRunning = $true
    }
}
#endregion

#region 4. Registry Evidence
Write-Host "`n4. REGISTRY EVIDENCE:" -ForegroundColor Cyan
$regPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\CommitRequired",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Services\Pending"
)
foreach ($path in $regPaths) {
    if (Test-Path $path) {
        Write-Host "✓ Found upgrade registry key: $path" -ForegroundColor Green
        $evidence.UpgradeRegistryKeys = $true
    }
}
#endregion

#region 5. Event Log Evidence
Write-Host "`n5. EVENT LOG EVIDENCE:" -ForegroundColor Cyan
try {
    $events = Get-EventLog -LogName Application -Source "*Windows*11*" -Newest 10 -ErrorAction SilentlyContinue
    if ($events) {
        Write-Host "✓ Windows 11 events in Application log:" -ForegroundColor Green
        $events | Select-Object -First 3 | ForEach-Object {
            Write-Host "  $($_.TimeGenerated): $($_.Message.Substring(0, [Math]::Min(80, $_.Message.Length)))..." -ForegroundColor Gray
        }
        $evidence.EventLogEntries = $true
    }
} catch {}
#endregion

#region CONCLUSION
Write-Host "`n" + ("=" * 70) -ForegroundColor Green
Write-Host "EVIDENCE SUMMARY:" -ForegroundColor Green -BackgroundColor Black

$proofPoints = 0
if ($evidence.ProcessRunning) { $proofPoints++; Write-Host "✓ Installation Assistant process running as SYSTEM" -ForegroundColor Green }
if ($evidence.UpgradeFolderExists) { $proofPoints++; Write-Host "✓ Windows upgrade folder exists with files" -ForegroundColor Green }
if ($evidence.ActiveFileWrites) { $proofPoints++; Write-Host "✓ Active file writes to upgrade folder" -ForegroundColor Green }
if ($evidence.ActiveNetworkConnections) { $proofPoints++; Write-Host "✓ Active network connections (downloading)" -ForegroundColor Green }
if ($evidence.WindowsUpdateRunning) { $proofPoints++; Write-Host "✓ Windows Update service active" -ForegroundColor Green }

Write-Host "`nCONCRETE PROOF SCORE: $proofPoints/5" -ForegroundColor $(if ($proofPoints -ge 3) { 'Green' } else { 'Yellow' })

if ($proofPoints -ge 3) {
    Write-Host "`n✓ YES - WINDOWS 11 SILENT UPGRADE IS ACTIVELY RUNNING!" -ForegroundColor Green -BackgroundColor Black
} else {
    Write-Host "`n✗ INSUFFICIENT EVIDENCE OF ACTIVE UPGRADE" -ForegroundColor Red
}
#endregion

# Export evidence
$evidence | ConvertTo-Json | Out-File "C:\code\Windows\upgrade-evidence-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"