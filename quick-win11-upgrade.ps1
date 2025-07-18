# Quick Windows 11 Upgrade Test Script
# Run this as Administrator on the target Windows 10 machine

param(
    [string]$AssistantPath = "C:\Temp\Windows11InstallationAssistant.exe"
)

Write-Host "Windows 11 Quick Upgrade Script" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan

# Create temp directory
$tempDir = "C:\Temp"
if (!(Test-Path $tempDir)) {
    New-Item -Path $tempDir -ItemType Directory -Force
}

# Download Windows 11 Installation Assistant if not present
if (!(Test-Path $AssistantPath)) {
    Write-Host "Downloading Windows 11 Installation Assistant..." -ForegroundColor Yellow
    $url = "https://go.microsoft.com/fwlink/?linkid=2171764"
    Invoke-WebRequest -Uri $url -OutFile $AssistantPath -UseBasicParsing
    Write-Host "Download complete!" -ForegroundColor Green
}

# Check current Windows version
$os = Get-WmiObject Win32_OperatingSystem
Write-Host "`nCurrent OS: $($os.Caption) Build $($os.BuildNumber)" -ForegroundColor Yellow

# Display free disk space
$disk = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='C:'"
$freeGB = [math]::Round($disk.FreeSpace / 1GB, 2)
Write-Host "Free disk space: $freeGB GB" -ForegroundColor $(if ($freeGB -lt 64) { 'Red' } else { 'Green' })

Write-Host "`nStarting Windows 11 upgrade..." -ForegroundColor Green
Write-Host "NOTE: You may need to accept EULA manually!" -ForegroundColor Yellow

# Start the upgrade
Start-Process -FilePath $AssistantPath -ArgumentList "/QuietInstall", "/SkipEULA" -Wait

Write-Host "`nUpgrade process started. Your computer will restart automatically." -ForegroundColor Green