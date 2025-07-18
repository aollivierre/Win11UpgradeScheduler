# Test script to verify deployment functionality
Write-Host "Testing Windows 11 Upgrade Scheduler Deployment" -ForegroundColor Cyan
Write-Host "=" * 60

# Change to src directory
Set-Location "$PSScriptRoot\src"

# Test 1: Check if modules load correctly
Write-Host "`nTest 1: Loading modules..." -ForegroundColor Yellow
try {
    Import-Module ".\SupportFiles\Modules\01-UpgradeScheduler.psm1" -Force
    Import-Module ".\SupportFiles\Modules\02-PreFlightChecks.psm1" -Force
    Write-Host "SUCCESS: Modules loaded" -ForegroundColor Green
    
    # List available commands
    Write-Host "`nAvailable upgrade scheduler commands:"
    Get-Command -Module *Upgrade* | Format-Table Name, CommandType
} catch {
    Write-Host "FAILED: $_" -ForegroundColor Red
}

# Test 2: Check if UI scripts exist and can be loaded
Write-Host "`nTest 2: Loading UI scripts..." -ForegroundColor Yellow
try {
    . ".\SupportFiles\UI\01-Show-EnhancedCalendarPicker.ps1"
    . ".\SupportFiles\UI\02-Show-UpgradeInformationDialog.ps1"
    Write-Host "SUCCESS: UI scripts loaded" -ForegroundColor Green
} catch {
    Write-Host "FAILED: $_" -ForegroundColor Red
}

# Test 3: Test calendar picker directly
Write-Host "`nTest 3: Testing calendar picker function..." -ForegroundColor Yellow
if (Get-Command Show-EnhancedCalendarPicker -ErrorAction SilentlyContinue) {
    Write-Host "Calendar picker function is available" -ForegroundColor Green
    Write-Host "Run this to test it: Show-EnhancedCalendarPicker" -ForegroundColor Gray
} else {
    Write-Host "Calendar picker function NOT FOUND" -ForegroundColor Red
}

# Test 4: Check for Windows 11 media
Write-Host "`nTest 4: Checking for Windows 11 installation media..." -ForegroundColor Yellow
$setupPath = ".\Files\setup.exe"
if (Test-Path $setupPath) {
    Write-Host "SUCCESS: Windows 11 setup.exe found" -ForegroundColor Green
} else {
    Write-Host "WARNING: Windows 11 setup.exe not found at: $setupPath" -ForegroundColor Yellow
    Write-Host "You need to place Windows 11 installation media in the Files directory" -ForegroundColor Gray
}

# Test 5: Pre-flight checks
Write-Host "`nTest 5: Running pre-flight checks..." -ForegroundColor Yellow
if (Get-Command Test-SystemReadiness -ErrorAction SilentlyContinue) {
    $results = Test-SystemReadiness
    if ($results.IsReady) {
        Write-Host "SUCCESS: System is ready for upgrade" -ForegroundColor Green
    } else {
        Write-Host "WARNING: System has issues:" -ForegroundColor Yellow
        $results.Issues | ForEach-Object { Write-Host "  - $_" -ForegroundColor Gray }
    }
} else {
    Write-Host "Pre-flight check function not available" -ForegroundColor Red
}

Write-Host "`n" + ("=" * 60)
Write-Host "Deployment script location: .\Deploy-Application.ps1" -ForegroundColor Cyan
Write-Host "To run interactively: .\Deploy-Application.ps1" -ForegroundColor Green
Write-Host "To run silently: .\Deploy-Application.ps1 -DeployMode Silent" -ForegroundColor Green