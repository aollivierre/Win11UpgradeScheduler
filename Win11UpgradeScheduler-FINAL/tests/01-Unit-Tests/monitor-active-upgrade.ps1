# Monitor active Windows 11 upgrade
Write-Host "WINDOWS 11 UPGRADE IS ACTIVE!" -ForegroundColor Green -BackgroundColor Black
Write-Host ("=" * 60) -ForegroundColor Green

while ($true) {
    Clear-Host
    Write-Host "Windows 11 Silent Upgrade Monitor - $(Get-Date -Format 'HH:mm:ss')" -ForegroundColor Cyan
    Write-Host ("=" * 60) -ForegroundColor Cyan
    
    # Process status
    $process = Get-Process -Name "Windows11InstallationAssistant" -ErrorAction SilentlyContinue
    if ($process) {
        Write-Host "`nInstallation Assistant: RUNNING (PID: $($process.Id))" -ForegroundColor Green
        Write-Host "CPU Usage: $([math]::Round($process.CPU, 2))%"
        Write-Host "Memory: $([math]::Round($process.WorkingSet64 / 1MB, 2)) MB"
    } else {
        Write-Host "`nInstallation Assistant: NOT RUNNING" -ForegroundColor Red
    }
    
    # Upgrade folder status
    if (Test-Path "C:\`$WINDOWS.~BT") {
        $files = Get-ChildItem "C:\`$WINDOWS.~BT" -Recurse -Force -ErrorAction SilentlyContinue
        $size = ($files | Measure-Object -Property Length -Sum).Sum / 1GB
        Write-Host "`nUpgrade Folder: C:\`$WINDOWS.~BT" -ForegroundColor Yellow
        Write-Host "Total Size: $([math]::Round($size, 2)) GB" -ForegroundColor Green
        Write-Host "File Count: $($files.Count)"
        
        # Show recent files
        $recent = $files | Where-Object { $_.LastWriteTime -gt (Get-Date).AddMinutes(-5) } | 
                  Sort-Object LastWriteTime -Descending | Select-Object -First 5
        if ($recent) {
            Write-Host "`nRecent Activity:" -ForegroundColor Cyan
            $recent | ForEach-Object {
                Write-Host "  $($_.Name) - $($_.LastWriteTime.ToString('HH:mm:ss'))"
            }
        }
    }
    
    # Network activity
    Write-Host "`nChecking for downloads..." -ForegroundColor Yellow
    $netstat = netstat -n | Select-String ":443.*ESTABLISHED" | Select-String "microsoft|windowsupdate"
    if ($netstat) {
        Write-Host "Active downloads detected!" -ForegroundColor Green
    }
    
    Write-Host "`nPress Ctrl+C to stop monitoring" -ForegroundColor Gray
    Start-Sleep -Seconds 10
}