# Check VM specifications
Write-Host "Checking VM Specifications for Windows 11 Requirements..." -ForegroundColor Cyan
Write-Host ("=" * 60) -ForegroundColor Cyan

# RAM Check
$ram = Get-WmiObject Win32_ComputerSystem
$ramGB = [math]::Round($ram.TotalPhysicalMemory / 1GB, 2)
Write-Host "`nRAM: $ramGB GB" -ForegroundColor $(if ($ramGB -ge 4) { 'Green' } else { 'Red' })
Write-Host "Required: 4 GB minimum" -ForegroundColor Yellow

# CPU Check
$cpu = Get-WmiObject Win32_Processor
Write-Host "`nCPU: $($cpu.Name)"
Write-Host "Cores: $($cpu.NumberOfCores)"
Write-Host "Logical Processors: $($cpu.NumberOfLogicalProcessors)"

# Disk Space
$disk = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='C:'"
$freeGB = [math]::Round($disk.FreeSpace / 1GB, 2)
Write-Host "`nFree Disk Space: $freeGB GB" -ForegroundColor $(if ($freeGB -ge 64) { 'Green' } else { 'Yellow' })

# Check if bypass keys are still set
Write-Host "`nBypass Registry Keys Status:" -ForegroundColor Cyan
$labConfig = "HKLM:\SYSTEM\Setup\LabConfig"
if (Test-Path $labConfig) {
    $keys = Get-ItemProperty $labConfig
    Write-Host "BypassTPMCheck: $($keys.BypassTPMCheck)" -ForegroundColor Green
    Write-Host "BypassCPUCheck: $($keys.BypassCPUCheck)" -ForegroundColor Green
    Write-Host "BypassRAMCheck: $($keys.BypassRAMCheck)" -ForegroundColor Green
}

Write-Host "`nKilling any existing Installation Assistant processes..." -ForegroundColor Yellow
Get-Process -Name "*Windows11*" -ErrorAction SilentlyContinue | Stop-Process -Force

Write-Host "`nStarting fresh Installation Assistant attempt..." -ForegroundColor Green