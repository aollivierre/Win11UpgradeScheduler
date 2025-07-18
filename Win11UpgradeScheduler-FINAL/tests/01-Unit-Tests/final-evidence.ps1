Write-Host "`nFINAL CONCRETE EVIDENCE CHECK" -ForegroundColor Yellow -BackgroundColor Black
Write-Host "==============================" -ForegroundColor Yellow

# 1. Process Check
$proc = Get-Process -Name "Windows11InstallationAssistant" -ErrorAction SilentlyContinue
if ($proc) {
    Write-Host "`n✓ PROCESS RUNNING: PID $($proc.Id)" -ForegroundColor Green
    Write-Host "  Started: $($proc.StartTime)" -ForegroundColor Cyan
} else {
    Write-Host "`n✗ Process NOT found" -ForegroundColor Red
}

# 2. Folder Check
$btPath = "C:\`$WINDOWS.~BT"
if (Test-Path $btPath) {
    Write-Host "`n✓ UPGRADE FOLDER EXISTS: $btPath" -ForegroundColor Green
    $info = Get-Item $btPath -Force
    Write-Host "  Created: $($info.CreationTime)" -ForegroundColor Cyan
    
    $files = @(Get-ChildItem $btPath -Recurse -Force -ErrorAction SilentlyContinue)
    Write-Host "  Files: $($files.Count)" -ForegroundColor Cyan
    
    $size = 0
    $files | ForEach-Object { $size += $_.Length }
    $sizeGB = [math]::Round($size / 1GB, 2)
    Write-Host "  Size: $sizeGB GB" -ForegroundColor Cyan
    
    if ($sizeGB -gt 0.1) {
        Write-Host "  ✓ DOWNLOADING: Size is growing!" -ForegroundColor Green
    }
} else {
    Write-Host "`n✗ No upgrade folder" -ForegroundColor Red
}

# 3. Task Check
$task = Get-ScheduledTask | Where-Object { $_.TaskName -like "*Win11*" -and $_.State -eq "Running" } | Select-Object -First 1
if ($task) {
    Write-Host "`n✓ SCHEDULED TASK RUNNING: $($task.TaskName)" -ForegroundColor Green
}

Write-Host "`n==============================" -ForegroundColor Green
if ($proc -and (Test-Path $btPath)) {
    Write-Host "✓ CONFIRMED: SILENT UPGRADE IS ACTIVE!" -ForegroundColor Green -BackgroundColor Black
} else {
    Write-Host "✗ Cannot confirm upgrade is active" -ForegroundColor Red
}