# Minimal Windows 11 Upgrade Script - Replicates your successful upgrade
# This bypasses pre-flight checks like disk space

param(
    [switch]$SkipDownload
)

$ErrorActionPreference = 'Stop'

Write-Host @"
==================================================
Windows 11 Upgrade - Minimal Test Script
==================================================
This replicates the successful upgrade method
"@ -ForegroundColor Cyan

# Setup paths
$workDir = "C:\Win11Upgrade"
$assistantPath = "$workDir\Windows11InstallationAssistant.exe"
$logPath = "$workDir\upgrade.log"

# Create working directory
if (!(Test-Path $workDir)) {
    New-Item -Path $workDir -ItemType Directory -Force | Out-Null
}

# Download Installation Assistant
if (!$SkipDownload -and !(Test-Path $assistantPath)) {
    Write-Host "`nDownloading Windows 11 Installation Assistant..." -ForegroundColor Yellow
    try {
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri "https://go.microsoft.com/fwlink/?linkid=2171764" -OutFile $assistantPath -UseBasicParsing
        Write-Host "Download complete!" -ForegroundColor Green
    }
    catch {
        Write-Host "Download failed! Error: $_" -ForegroundColor Red
        exit 1
    }
}

# System info
Write-Host "`nSystem Information:" -ForegroundColor Yellow
$os = Get-WmiObject Win32_OperatingSystem
$disk = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='C:'"
$freeGB = [math]::Round($disk.FreeSpace / 1GB, 2)

Write-Host "Current OS: $($os.Caption) Build $($os.BuildNumber)"
Write-Host "Free disk: $freeGB GB $(if ($freeGB -lt 64) { '(Below 64GB requirement!)' })"
Write-Host "Computer: $env:COMPUTERNAME"
Write-Host "User: $env:USERDOMAIN\$env:USERNAME"

# Create scheduled task to run as SYSTEM (this might help with EULA)
Write-Host "`nCreating scheduled task to run upgrade as SYSTEM..." -ForegroundColor Yellow

$taskName = "Win11UpgradeTest_$(Get-Date -Format 'yyyyMMddHHmmss')"
$action = New-ScheduledTaskAction -Execute $assistantPath -Argument "/QuietInstall /SkipEULA"
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries

try {
    Register-ScheduledTask -TaskName $taskName -Action $action -Principal $principal -Settings $settings -Force | Out-Null
    Write-Host "Scheduled task created successfully" -ForegroundColor Green
    
    Write-Host "`nStarting Windows 11 upgrade..." -ForegroundColor Green
    Start-ScheduledTask -TaskName $taskName
    
    Write-Host @"

UPGRADE STARTED!
================
Monitor progress:
1. Check for Installation Assistant window
2. Watch for "Working on updates" screen
3. System will reboot automatically

To check task status:
Get-ScheduledTask -TaskName '$taskName' | Get-ScheduledTaskInfo

"@ -ForegroundColor Cyan
    
}
catch {
    Write-Host "Failed to create/start scheduled task: $_" -ForegroundColor Red
    Write-Host "`nTrying direct execution instead..." -ForegroundColor Yellow
    Start-Process -FilePath $assistantPath -ArgumentList "/QuietInstall", "/SkipEULA"
}

Write-Host "Script complete. Upgrade is running in background." -ForegroundColor Green