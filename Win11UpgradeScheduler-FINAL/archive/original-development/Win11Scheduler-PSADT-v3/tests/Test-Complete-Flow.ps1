# Test Complete Windows 11 Upgrade Scheduler Flow
# Shows Information Dialog -> Calendar Picker -> Confirmation

# Define Write-Log function for testing
function Write-Log {
    param(
        [string]$Message, 
        [string]$Source = 'Test', 
        [string]$Severity = 'Info'
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Severity) {
        'Error' { 'Red' }
        'Warning' { 'Yellow' }
        'Info' { 'Green' }
        'Debug' { 'Cyan' }
        default { 'White' }
    }
    Write-Host "[$timestamp] [$Source] [$Severity] $Message" -ForegroundColor $color
}

# Set location
Set-Location 'C:\Code\Windows\Windows11InPlaceUpgrade\Win11Scheduler'

try {
    Write-Host "=== Windows 11 Upgrade Scheduler - Complete Flow Test ===" -ForegroundColor Cyan
    Write-Host ""
    
    # Load dialog functions
    Write-Host "Loading dialog functions..." -ForegroundColor Yellow
    . '.\src\SupportFiles\Show-UpgradeInformationDialog.ps1'
    . '.\src\SupportFiles\Show-CalendarPicker.ps1'
    Write-Host "Functions loaded successfully!" -ForegroundColor Green
    Write-Host ""
    
    # Step 1: Show Information Dialog
    Write-Host "STEP 1: Displaying upgrade information and requirements..." -ForegroundColor Yellow
    $userChoice = Show-UpgradeInformationDialog -OrganizationName "ABC Corporation" -DeadlineDays 14
    
    Write-Host "User choice: $userChoice" -ForegroundColor Green
    Write-Host ""
    
    # Step 2: Handle user choice
    switch ($userChoice) {
        'Schedule' {
            Write-Host "STEP 2: User chose to schedule - launching calendar picker..." -ForegroundColor Yellow
            $selectedDate = Show-CalendarPicker -MinDate (Get-Date).AddDays(1) -MaxDate (Get-Date).AddDays(14)
            
            if ($selectedDate) {
                Write-Host ""
                Write-Host "=== SCHEDULING SUCCESSFUL ===" -ForegroundColor Green
                Write-Host "Selected Date/Time: $($selectedDate.ToString('MMMM dd, yyyy \a\t h:mm tt'))" -ForegroundColor Green
                Write-Host "ISO Format: $($selectedDate.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Cyan
                Write-Host ""
                Write-Host "In a real deployment, this would:" -ForegroundColor Yellow
                Write-Host "- Create a scheduled task for Windows 11 upgrade" -ForegroundColor Gray
                Write-Host "- Configure the task to run at the selected time" -ForegroundColor Gray
                Write-Host "- Set up all necessary parameters and permissions" -ForegroundColor Gray
                Write-Host "- Notify the user of successful scheduling" -ForegroundColor Gray
            } else {
                Write-Host "User cancelled calendar selection" -ForegroundColor Yellow
            }
        }
        
        'UpgradeNow' {
            Write-Host "STEP 2: User chose immediate upgrade" -ForegroundColor Red
            Write-Host "In a real deployment, this would start the upgrade immediately" -ForegroundColor Yellow
        }
        
        'RemindLater' {
            Write-Host "STEP 2: User chose to be reminded later" -ForegroundColor Yellow
            Write-Host "In a real deployment, this would schedule a reminder" -ForegroundColor Gray
        }
        
        default {
            Write-Host "STEP 2: User cancelled or closed dialog" -ForegroundColor Yellow
        }
    }
    
    Write-Host ""
    Write-Host "=== TEST COMPLETED SUCCESSFULLY ===" -ForegroundColor Green
    
} catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
}