# Check actual OS version
$os = Get-WmiObject Win32_OperatingSystem
Write-Host "Caption: $($os.Caption)"
Write-Host "Version: $($os.Version)"
Write-Host "BuildNumber: $($os.BuildNumber)"

# Check for Windows 11
$build = [int]$os.BuildNumber
if ($build -ge 22000) {
    Write-Host "This is Windows 11!" -ForegroundColor Green
} else {
    Write-Host "This is Windows 10" -ForegroundColor Yellow
}

# Check free disk space
$disk = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='C:'"
$freeGB = [math]::Round($disk.FreeSpace / 1GB, 2)
Write-Host "`nFree disk space: $freeGB GB"