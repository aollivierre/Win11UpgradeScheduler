# Windows 11 Upgrade Scheduler - Project Map

## Production Code (src/)

### Main Scripts
1. **Deploy-Application-Enhanced.ps1** - Primary deployment script with all enhancements
2. **Deploy-Application.ps1** - Standard PSADT deployment script

### Core Modules (src/SupportFiles/Modules/)
1. **UpgradeScheduler.psm1**
   - `New-UpgradeSchedule` - Creates scheduled task
   - `New-QuickUpgradeSchedule` - Tonight/Tomorrow scheduling
   - `Get-UpgradeSchedule` - Retrieves schedule
   - `Update-UpgradeSchedule` - Modifies schedule
   - `Remove-UpgradeSchedule` - Cancels schedule

2. **PreFlightChecks.psm1**
   - `Test-SystemReadiness` - Runs all checks
   - `Test-DiskSpace` - 64GB validation
   - `Test-BatteryLevel` - Power validation
   - `Test-WindowsUpdateStatus` - Update conflicts
   - `Test-PendingReboot` - Reboot detection
   - `Test-SystemResources` - RAM/CPU checks

### UI Components (src/SupportFiles/UI/)
1. **Show-EnhancedCalendarPicker.ps1** - Tonight options + 14-day calendar
2. **Show-UpgradeInformationDialog.ps1** - Information display
3. **Show-CalendarPicker-Original.ps1** - Original for reference

### Task Management (src/SupportFiles/)
1. **ScheduledTaskWrapper.ps1** - Session detection and countdown handling

## Documentation (docs/)

### 01-Requirements/
- **Win11UpgradeScheduler_DetailedPrompt.md** - Original requirements

### 02-Implementation/
- **README-Implementation.md** - Implementation guide
- **IMPLEMENTATION_SUMMARY.md** - Feature summary

### 03-Testing/
- **VALIDATION_RESULTS.md** - Test results

### 04-Deployment/
- **DEPLOYMENT-GUIDE.md** - Deployment procedures
- **README-Original-PSADT.md** - Original PSADT documentation

## Tests (tests/)

### 01-Unit/
- Individual component tests from PSADT v3

### 02-Integration/
- **01-Test-UpgradeScheduler.ps1** - Module integration tests

### 03-Validation/
- **01-Test-Empirical-Validation.ps1** - Basic validation
- **02-Test-Complete-Validation.ps1** - Comprehensive validation
- **03-Validate-Enhancements.ps1** - Enhancement verification

## Demonstrations (demos/)

### 01-Components/
1. **01-Demo-PSADT-Scheduling.ps1** - PSADT UI demonstration
2. **02-Demo-Enhanced-Scheduling.ps1** - Scheduling features demo
3. **03-Demo-Individual-Components.ps1** - Component selector
4. **04-Show-PreFlightChecks.ps1** - Pre-flight demonstration

### 02-Workflow/
1. **01-Demo-Full-Integration.ps1** - Complete integration demo
2. **02-Test-Complete-PSADT-Workflow.ps1** - Full workflow test

## Key Enhancements Implemented

### 1. Same-Day Scheduling
- Tonight: 8PM, 10PM, 11PM (auto-disabled if time passed)
- Warning for <4 hour scheduling
- 2-hour minimum buffer enforced

### 2. Enhanced UI
- Combined quick options and calendar
- 14-day maximum (business requirement)
- Improved window sizing (580x420)

### 3. Pre-Flight Validation
- 5 comprehensive system checks
- Fail-safe design
- Detailed logging

### 4. Session Management
- Attended: 30-minute countdown
- Unattended: Silent execution
- "Start Now" option available

### 5. Power Management
- WakeToRun enabled
- Battery safety checks
- Retry logic (3x, 10-min intervals)

## Quick Reference

### Run Enhanced Deployment
```powershell
cd .\src\
.\Deploy-Application-Enhanced.ps1 -DeploymentType Install -DeployMode Interactive
```

### Test Calendar Picker
```powershell
.\src\SupportFiles\UI\Show-EnhancedCalendarPicker.ps1
```

### Run Pre-Flight Checks
```powershell
Import-Module .\src\SupportFiles\Modules\PreFlightChecks.psm1
Test-SystemReadiness
```

### View Demonstrations
```powershell
.\demos\01-Components\03-Demo-Individual-Components.ps1
```