# Test scheduling functionality directly
Write-Host "Testing Windows 11 Upgrade Scheduling Functions" -ForegroundColor Cyan
Write-Host "=" * 60

# Change to src directory and load modules
Set-Location "$PSScriptRoot\src"

# Load modules
Import-Module ".\SupportFiles\Modules\01-UpgradeScheduler.psm1" -Force
Import-Module ".\SupportFiles\Modules\02-PreFlightChecks.psm1" -Force

# Load UI scripts
. ".\SupportFiles\UI\01-Show-EnhancedCalendarPicker.ps1"

Write-Host "`nTest 1: Show Calendar Picker" -ForegroundColor Yellow
$selection = Show-EnhancedCalendarPicker
Write-Host "You selected: $selection" -ForegroundColor Green

if ($selection) {
    Write-Host "`nTest 2: Parse and Schedule" -ForegroundColor Yellow
    
    if ($selection -match '^(Tonight|Tomorrow) - (.+)$') {
        $when = $Matches[1]
        $time = $Matches[2]
        
        Write-Host "Parsed: When=$when, Time=$time" -ForegroundColor Gray
        
        try {
            Write-Host "Creating schedule..." -ForegroundColor Gray
            New-QuickUpgradeSchedule -When $when -Time $time -PSADTPath "$PSScriptRoot\src" -DeployMode Interactive
            
            Write-Host "`nTest 3: Verify Schedule" -ForegroundColor Yellow
            $schedule = Get-UpgradeSchedule
            
            if ($schedule) {
                Write-Host "SUCCESS: Upgrade scheduled for $($schedule.NextRunTime)" -ForegroundColor Green
                Write-Host "Task State: $($schedule.State)" -ForegroundColor Gray
                
                # Show the scheduled task
                Get-ScheduledTask -TaskName "Windows11UpgradeScheduled" -ErrorAction SilentlyContinue | 
                    Select-Object TaskName, State, @{Name="NextRun";Expression={($_.Triggers[0].StartBoundary)}} |
                    Format-Table
            }
        } catch {
            Write-Host "ERROR: $_" -ForegroundColor Red
            Write-Host $_.Exception.Message -ForegroundColor Red
            Write-Host $_.ScriptStackTrace -ForegroundColor Gray
        }
    } elseif ($selection -is [datetime]) {
        Write-Host "Custom date selected: $selection" -ForegroundColor Gray
        # Handle custom date scheduling
    }
}

Write-Host "`nDone!" -ForegroundColor Cyan