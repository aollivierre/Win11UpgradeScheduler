# Demo Individual Enhanced Components
Write-Host "`n=== ENHANCED PSADT COMPONENTS DEMONSTRATION ===" -ForegroundColor Cyan

$basePath = "C:\code\Windows\Phase1-Detection\Win11Scheduler-PSADT-v3"

# Menu
Write-Host "`nSelect component to test:" -ForegroundColor Yellow
Write-Host "1. Enhanced Calendar Picker (with Tonight options)" -ForegroundColor White
Write-Host "2. Pre-Flight Checks Module" -ForegroundColor White
Write-Host "3. Upgrade Information Dialog" -ForegroundColor White
Write-Host "4. Complete PSADT Flow (Interactive)" -ForegroundColor White
Write-Host "5. View Scheduling Module Features" -ForegroundColor White
Write-Host "Q. Quit" -ForegroundColor White

$choice = Read-Host "`nEnter choice (1-5 or Q)"

switch ($choice) {
    '1' {
        Write-Host "`n[ENHANCED CALENDAR PICKER]" -ForegroundColor Cyan
        Write-Host "Features:" -ForegroundColor Yellow
        Write-Host "- Tonight options: 8PM, 10PM, 11PM" -ForegroundColor Green
        Write-Host "- Tomorrow quick picks: Morning, Afternoon, Evening" -ForegroundColor Green
        Write-Host "- 14-day maximum (business requirement)" -ForegroundColor Green
        Write-Host "- Warning for <4 hour scheduling" -ForegroundColor Green
        
        $pickerPath = "C:\code\Windows\Win11UpgradeScheduler\SupportFiles\Show-EnhancedCalendarPicker.ps1"
        if (Test-Path $pickerPath) {
            Write-Host "`nLaunching enhanced calendar picker..." -ForegroundColor Yellow
            & $pickerPath
        }
    }
    
    '2' {
        Write-Host "`n[PRE-FLIGHT CHECKS MODULE]" -ForegroundColor Cyan
        $modulePath = "C:\code\Windows\Win11UpgradeScheduler\SupportFiles\Modules\PreFlightChecks.psm1"
        
        if (Test-Path $modulePath) {
            Import-Module $modulePath -Force
            
            Write-Host "Running system readiness checks..." -ForegroundColor Yellow
            $results = Test-SystemReadiness -Verbose
            
            Write-Host "`nResults:" -ForegroundColor Cyan
            Write-Host "System Ready: $($results.IsReady)" -ForegroundColor $(if ($results.IsReady) { 'Green' } else { 'Red' })
            
            if ($results.Checks) {
                Write-Host "`nDetailed Checks:" -ForegroundColor Yellow
                foreach ($check in $results.Checks.GetEnumerator()) {
                    $passed = $check.Value.Passed
                    Write-Host "  $($check.Key): $(if ($passed) { 'PASS' } else { 'FAIL' })" -ForegroundColor $(if ($passed) { 'Green' } else { 'Red' })
                    if ($check.Value.Message) {
                        Write-Host "    $($check.Value.Message)" -ForegroundColor Gray
                    }
                }
            }
        }
    }
    
    '3' {
        Write-Host "`n[UPGRADE INFORMATION DIALOG]" -ForegroundColor Cyan
        $dialogPath = "$basePath\SupportFiles\Show-UpgradeInformationDialog.ps1"
        
        if (Test-Path $dialogPath) {
            Write-Host "Launching upgrade information dialog..." -ForegroundColor Yellow
            & $dialogPath
        }
    }
    
    '4' {
        Write-Host "`n[COMPLETE PSADT FLOW]" -ForegroundColor Cyan
        Write-Host "This will launch the full enhanced PSADT deployment" -ForegroundColor Yellow
        Write-Host "Press Enter to continue or Ctrl+C to cancel" -ForegroundColor Gray
        Read-Host
        
        $enhancedDeploy = "$basePath\Deploy-Application-Enhanced.ps1"
        if (Test-Path $enhancedDeploy) {
            Set-Location $basePath
            & powershell.exe -ExecutionPolicy Bypass -File $enhancedDeploy -DeploymentType Install -DeployMode Interactive
        }
    }
    
    '5' {
        Write-Host "`n[SCHEDULING MODULE FEATURES]" -ForegroundColor Cyan
        Write-Host "The enhanced UpgradeScheduler.psm1 module provides:" -ForegroundColor Yellow
        
        Write-Host "`nCore Functions:" -ForegroundColor White
        Write-Host "  - New-UpgradeSchedule: Creates scheduled task with validation" -ForegroundColor Gray
        Write-Host "  - New-QuickUpgradeSchedule: Tonight/Tomorrow quick scheduling" -ForegroundColor Gray
        Write-Host "  - Get-UpgradeSchedule: Retrieves current schedule" -ForegroundColor Gray
        Write-Host "  - Update-UpgradeSchedule: Modifies existing schedule" -ForegroundColor Gray
        Write-Host "  - Remove-UpgradeSchedule: Cancels scheduled upgrade" -ForegroundColor Gray
        
        Write-Host "`nKey Features:" -ForegroundColor White
        Write-Host "  - 2-hour minimum scheduling buffer" -ForegroundColor Green
        Write-Host "  - Wake computer support (WakeToRun)" -ForegroundColor Green
        Write-Host "  - Retry logic (3 attempts, 10-min intervals)" -ForegroundColor Green
        Write-Host "  - Configuration persistence" -ForegroundColor Green
        Write-Host "  - SYSTEM account execution" -ForegroundColor Green
        
        Write-Host "`nScheduling Options:" -ForegroundColor White
        Write-Host "  Tonight:" -ForegroundColor Yellow
        Write-Host "    - 8:00 PM" -ForegroundColor Gray
        Write-Host "    - 10:00 PM" -ForegroundColor Gray
        Write-Host "    - 11:00 PM" -ForegroundColor Gray
        Write-Host "  Tomorrow:" -ForegroundColor Yellow
        Write-Host "    - Morning (9:00 AM)" -ForegroundColor Gray
        Write-Host "    - Afternoon (2:00 PM)" -ForegroundColor Gray
        Write-Host "    - Evening (8:00 PM)" -ForegroundColor Gray
    }
    
    'Q' {
        Write-Host "`nExiting demo..." -ForegroundColor Yellow
        exit
    }
    
    default {
        Write-Host "`nInvalid choice" -ForegroundColor Red
    }
}

Write-Host "`n=== DEMO COMPLETE ===" -ForegroundColor Cyan