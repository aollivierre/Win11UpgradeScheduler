# Set Windows 11 bypass registry keys
Write-Host "Setting Windows 11 compatibility bypass registry keys..." -ForegroundColor Cyan

# Create LabConfig key if it doesn't exist
$labConfigPath = "HKLM:\SYSTEM\Setup\LabConfig"
if (!(Test-Path $labConfigPath)) {
    New-Item -Path "HKLM:\SYSTEM\Setup" -Name "LabConfig" -Force | Out-Null
    Write-Host "Created LabConfig key" -ForegroundColor Green
}

# Set bypass values
$bypassValues = @{
    "BypassTPMCheck" = 1
    "BypassCPUCheck" = 1
    "BypassRAMCheck" = 1
    "BypassSecureBootCheck" = 1
    "BypassStorageCheck" = 1
}

foreach ($key in $bypassValues.Keys) {
    Set-ItemProperty -Path $labConfigPath -Name $key -Value $bypassValues[$key] -Type DWord -Force
    Write-Host "Set $key = 1" -ForegroundColor Yellow
}

Write-Host "`nRegistry keys set successfully!" -ForegroundColor Green
Write-Host "These keys tell Windows Setup to bypass hardware requirements" -ForegroundColor Cyan

# Now try the installation assistant again with bypass keys set
Write-Host "`nStarting Installation Assistant with bypass keys active..." -ForegroundColor Yellow

# Kill any existing processes first
Get-Process -Name "*Windows11*" -ErrorAction SilentlyContinue | Stop-Process -Force

# Try with scheduled task again
$taskName = "Win11BypassTest"
$action = New-ScheduledTaskAction -Execute "C:\Win11Upgrade\Windows11InstallationAssistant.exe" -Argument "/QuietInstall /SkipEULA"
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -RunLevel Highest
Register-ScheduledTask -TaskName $taskName -Action $action -Principal $principal -Force | Out-Null
Start-ScheduledTask -TaskName $taskName

Write-Host "`nStarted with bypass registry keys active" -ForegroundColor Green
Write-Host "Monitor with: Get-Process *Windows11*" -ForegroundColor Yellow