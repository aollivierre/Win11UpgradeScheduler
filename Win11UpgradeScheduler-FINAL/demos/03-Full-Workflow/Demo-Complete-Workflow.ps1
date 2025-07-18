# Full Integration Demo - Enhanced Win11 Upgrade Scheduler
Write-Host "`n=== FULL INTEGRATION DEMO ===" -ForegroundColor Cyan
Write-Host "This demonstrates the complete enhanced scheduling flow" -ForegroundColor Yellow

# Copy enhanced calendar picker to existing PSADT location
$sourcePicker = "C:\code\Windows\Win11UpgradeScheduler\SupportFiles\Show-EnhancedCalendarPicker.ps1"
$targetPath = "C:\code\Windows\Phase1-Detection\Win11Scheduler-PSADT-v3\SupportFiles\Show-EnhancedCalendarPicker.ps1"

if (Test-Path $sourcePicker) {
    Copy-Item -Path $sourcePicker -Destination $targetPath -Force
    Write-Host "`nEnhanced calendar picker copied to PSADT project" -ForegroundColor Green
}

# Show comparison
Write-Host "`n[COMPARISON] Original vs Enhanced Calendar Picker:" -ForegroundColor Yellow
Write-Host "Original Calendar Picker:" -ForegroundColor Cyan
Write-Host "  - Basic calendar only" -ForegroundColor White
Write-Host "  - No same-day options" -ForegroundColor White
Write-Host "  - 30-day range" -ForegroundColor White

Write-Host "`nEnhanced Calendar Picker:" -ForegroundColor Cyan
Write-Host "  - Tonight options (8PM, 10PM, 11PM)" -ForegroundColor Green
Write-Host "  - Tomorrow quick picks (Morning, Afternoon, Evening)" -ForegroundColor Green
Write-Host "  - 14-day limit enforced" -ForegroundColor Green
Write-Host "  - Warning for <4 hour scheduling" -ForegroundColor Green
Write-Host "  - Properly sized window" -ForegroundColor Green

# Demo the enhanced picker
Write-Host "`n[DEMO] Testing Enhanced Calendar Picker" -ForegroundColor Yellow
Write-Host "Press Enter to launch the enhanced picker..." -ForegroundColor Cyan
Read-Host

& $targetPath

Write-Host "`n[INTEGRATION POINTS]" -ForegroundColor Yellow
Write-Host "1. Scheduled Task Wrapper:" -ForegroundColor Cyan
Write-Host "   - Detects attended/unattended sessions" -ForegroundColor White
Write-Host "   - Shows 30-minute countdown for attended" -ForegroundColor White
Write-Host "   - Runs pre-flight checks first" -ForegroundColor White

Write-Host "`n2. Pre-Flight Checks:" -ForegroundColor Cyan
Write-Host "   - Disk space (64GB required)" -ForegroundColor White
Write-Host "   - Battery level (50% or AC power)" -ForegroundColor White
Write-Host "   - Windows Update status" -ForegroundColor White
Write-Host "   - Pending reboot detection" -ForegroundColor White

Write-Host "`n3. Schedule Creation:" -ForegroundColor Cyan
Write-Host "   - Creates Windows scheduled task" -ForegroundColor White
Write-Host "   - WakeToRun enabled" -ForegroundColor White
Write-Host "   - Retry on failure (3 times)" -ForegroundColor White
Write-Host "   - Runs as SYSTEM account" -ForegroundColor White

Write-Host "`n=== DEMO COMPLETE ===" -ForegroundColor Cyan
Write-Host "The enhanced scheduler provides a superior user experience with:" -ForegroundColor Yellow
Write-Host "- Intuitive same-day scheduling" -ForegroundColor Green
Write-Host "- Business-compliant 14-day deadline" -ForegroundColor Green
Write-Host "- Comprehensive system validation" -ForegroundColor Green
Write-Host "- Proper PSADT integration" -ForegroundColor Green