# CONCRETE EVIDENCE OF WINDOWS 11 UPGRADE
Write-Host "`nGATHERING CONCRETE EVIDENCE..." -ForegroundColor Yellow -BackgroundColor Black
Write-Host ("=" * 70) -ForegroundColor Yellow

$evidence = @{
    Timestamp = Get-Date
    ProcessEvidence = @{}
    FileEvidence = @{}
    NetworkEvidence = @{}
}

# 1. CHECK PROCESS
Write-Host "`n1. PROCESS CHECK:" -ForegroundColor Cyan
$process = Get-Process -Name "Windows11InstallationAssistant" -ErrorAction SilentlyContinue
if ($process) {
    Write-Host "✓ FOUND: Windows11InstallationAssistant.exe (PID: $($process.Id))" -ForegroundColor Green
    $wmi = Get-WmiObject Win32_Process -Filter "ProcessId = $($process.Id)"
    Write-Host "  Command Line: $($wmi.CommandLine)" -ForegroundColor Yellow
    Write-Host "  Start Time: $($process.StartTime)" -ForegroundColor Yellow
    
    $evidence.ProcessEvidence = @{
        Found = $true
        PID = $process.Id
        CommandLine = $wmi.CommandLine
        StartTime = $process.StartTime
    }
} else {
    Write-Host "✗ Process NOT running" -ForegroundColor Red
    $evidence.ProcessEvidence.Found = $false
}

# 2. CHECK UPGRADE FOLDER
Write-Host "`n2. UPGRADE FOLDER CHECK:" -ForegroundColor Cyan
$btFolder = "C:\`$WINDOWS.~BT"
if (Test-Path $btFolder) {
    $folderInfo = Get-Item $btFolder -Force
    $files = Get-ChildItem $btFolder -Recurse -Force -ErrorAction SilentlyContinue
    $totalSize = ($files | Measure-Object -Property Length -Sum).Sum / 1GB
    
    Write-Host "✓ FOUND: $btFolder" -ForegroundColor Green
    Write-Host "  Created: $($folderInfo.CreationTime)" -ForegroundColor Yellow
    Write-Host "  Files: $($files.Count)" -ForegroundColor Yellow
    Write-Host "  Size: $([math]::Round($totalSize, 2)) GB" -ForegroundColor Yellow
    
    # Check for recent activity
    $recentFiles = $files | Where-Object { $_.LastWriteTime -gt (Get-Date).AddMinutes(-10) }
    if ($recentFiles) {
        Write-Host "  ✓ ACTIVE: $($recentFiles.Count) files modified in last 10 minutes" -ForegroundColor Green
    }
    
    $evidence.FileEvidence = @{
        FolderExists = $true
        Created = $folderInfo.CreationTime
        FileCount = $files.Count
        SizeGB = [math]::Round($totalSize, 2)
        RecentActivity = $recentFiles.Count -gt 0
    }
} else {
    Write-Host "✗ Upgrade folder NOT found" -ForegroundColor Red
    $evidence.FileEvidence.FolderExists = $false
}

# 3. CHECK NETWORK ACTIVITY
Write-Host "`n3. NETWORK ACTIVITY CHECK:" -ForegroundColor Cyan
if ($process) {
    $connections = & netstat -ano 2>$null | Select-String $process.Id | Select-String "ESTABLISHED"
    if ($connections) {
        Write-Host "✓ ACTIVE network connections for PID $($process.Id)" -ForegroundColor Green
        $evidence.NetworkEvidence.ActiveConnections = $true
    } else {
        Write-Host "✗ No active network connections" -ForegroundColor Yellow
        $evidence.NetworkEvidence.ActiveConnections = $false
    }
}

# 4. FINAL VERDICT
Write-Host "`n" + ("=" * 70) -ForegroundColor Green
Write-Host "CONCRETE EVIDENCE SUMMARY:" -ForegroundColor Green -BackgroundColor Black

$score = 0
if ($evidence.ProcessEvidence.Found) { 
    $score++
    Write-Host "✓ Installation Assistant process IS running" -ForegroundColor Green 
}
if ($evidence.FileEvidence.FolderExists) { 
    $score++
    Write-Host "✓ Windows upgrade folder EXISTS with $($evidence.FileEvidence.FileCount) files" -ForegroundColor Green 
}
if ($evidence.FileEvidence.RecentActivity) { 
    $score++
    Write-Host "✓ Files are being ACTIVELY written" -ForegroundColor Green 
}
if ($evidence.NetworkEvidence.ActiveConnections) { 
    $score++
    Write-Host "✓ Active network connections (downloading)" -ForegroundColor Green 
}

Write-Host "`nEVIDENCE SCORE: $score/4" -ForegroundColor $(if ($score -ge 3) {'Green'} else {'Yellow'})

if ($score -ge 3) {
    Write-Host "`n✓ CONFIRMED: WINDOWS 11 IS UPGRADING SILENTLY!" -ForegroundColor Green -BackgroundColor Black
    Write-Host "The upgrade is running in the background without any UI." -ForegroundColor Green
} else {
    Write-Host "`n⚠ PARTIAL EVIDENCE - Upgrade may be initializing" -ForegroundColor Yellow
}

# Save evidence
$evidence | ConvertTo-Json -Depth 3 | Out-File "C:\code\Windows\evidence-$(Get-Date -Format 'HHmmss').json"
Write-Host "`nEvidence saved to: evidence-$(Get-Date -Format 'HHmmss').json" -ForegroundColor Cyan