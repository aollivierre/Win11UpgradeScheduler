# Live Demo of Enhanced Win11 Upgrade Scheduler with PSADT UI
Write-Host "`n=== PSADT Win11 Upgrade Scheduler LIVE DEMO ===" -ForegroundColor Cyan
Write-Host "This will demonstrate the actual UI components" -ForegroundColor Yellow

# Set working directory to existing PSADT project
$PSADTPath = "C:\code\Windows\Phase1-Detection\Win11Scheduler-PSADT-v3"
Set-Location $PSADTPath

Write-Host "`nUsing PSADT from: $PSADTPath" -ForegroundColor Green

# Option 1: Show Calendar Picker
Write-Host "`n[1] Testing Calendar Picker UI..." -ForegroundColor Yellow
Write-Host "Press Enter to show the Calendar Picker dialog" -ForegroundColor Cyan
Read-Host

try {
    & "$PSADTPath\SupportFiles\Show-CalendarPicker.ps1"
} catch {
    Write-Host "Calendar picker error: $_" -ForegroundColor Red
}

# Option 2: Show Information Dialog
Write-Host "`n[2] Testing Upgrade Information Dialog..." -ForegroundColor Yellow
Write-Host "Press Enter to show the Upgrade Information dialog" -ForegroundColor Cyan
Read-Host

try {
    & "$PSADTPath\SupportFiles\Show-UpgradeInformationDialog.ps1"
} catch {
    Write-Host "Information dialog error: $_" -ForegroundColor Red
}

# Option 3: Run the full PSADT deployment in demo mode
Write-Host "`n[3] Testing Full PSADT Deployment..." -ForegroundColor Yellow
Write-Host "This will run the actual PSADT deployment script" -ForegroundColor Yellow
Write-Host "Press Enter to launch PSADT (or Ctrl+C to skip)" -ForegroundColor Cyan
Read-Host

try {
    Write-Host "Launching PSADT Deploy-Application.ps1..." -ForegroundColor Green
    & powershell.exe -ExecutionPolicy Bypass -File "$PSADTPath\Deploy-Application-Complete.ps1" -DeploymentType Install -DeployMode Interactive
} catch {
    Write-Host "PSADT launch error: $_" -ForegroundColor Red
}