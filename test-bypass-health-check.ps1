# Test different parameters to bypass PC Health Check

Write-Host "Testing Windows 11 Installation Assistant bypass methods..." -ForegroundColor Cyan

# First, let's check what parameters are available
Write-Host "`nChecking available parameters:" -ForegroundColor Yellow
$testParams = @(
    @("/?", "Show help"),
    @("/Help", "Show help"),
    @("/Silent", "Silent mode"),
    @("/SilentInstall", "Silent install"),
    @("/Auto", "Automatic mode"),
    @("/ForceUpgrade", "Force upgrade"),
    @("/SkipCompatCheck", "Skip compatibility check"),
    @("/NoCompatCheck", "No compatibility check"),
    @("/BypassTPMCheck", "Bypass TPM check"),
    @("/BypassCPUCheck", "Bypass CPU check"),
    @("/DisableCompatCheck", "Disable compatibility check"),
    @("/Force", "Force install"),
    @("/MigrateDrivers", "Migrate drivers"),
    @("/Compat", "Compatibility mode"),
    @("/NoReboot", "No reboot"),
    @("/AcceptEULA", "Accept EULA")
)

$exePath = "C:\Win11Upgrade\Windows11InstallationAssistant.exe"

# Test help parameter to see available options
foreach ($param in $testParams) {
    Write-Host "`nTesting: $($param[0]) - $($param[1])"
    $proc = Start-Process -FilePath $exePath -ArgumentList $param[0] -PassThru -WindowStyle Hidden
    Start-Sleep -Seconds 2
    if ($proc.HasExited) {
        Write-Host "  Exit Code: $($proc.ExitCode)" -ForegroundColor Yellow
    } else {
        Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
        Write-Host "  Process started but was terminated" -ForegroundColor Gray
    }
}

Write-Host "`n`nAlternative approach - Registry modification:" -ForegroundColor Cyan
Write-Host "Some installers check these registry keys for bypass flags:"

$regKeys = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Setup\OOBE",
    "HKLM:\SYSTEM\Setup\LabConfig"
)

foreach ($key in $regKeys) {
    if (Test-Path $key) {
        Write-Host "`nFound: $key" -ForegroundColor Green
        Get-ItemProperty $key | Out-String
    }
}

Write-Host "`nKnown bypass registry values for Windows 11:" -ForegroundColor Yellow
Write-Host @"
HKLM:\SYSTEM\Setup\LabConfig:
  - BypassTPMCheck (DWORD) = 1
  - BypassCPUCheck (DWORD) = 1  
  - BypassRAMCheck (DWORD) = 1
  - BypassSecureBootCheck (DWORD) = 1
  - BypassStorageCheck (DWORD) = 1
"@