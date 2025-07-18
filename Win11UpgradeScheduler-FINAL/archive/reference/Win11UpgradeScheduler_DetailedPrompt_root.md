# Windows 11 Upgrade Scheduler - Detailed Implementation Prompt

## Project Background
We are developing a Windows 11 in-place upgrade scheduler using PowerShell App Deployment Toolkit (PSADT) v3.10.2 for enterprise deployment via ConnectWise RMM. The project has two phases:
1. **Detection Phase**: Determines Windows 11 eligibility (completed)
2. **Remediation Phase**: Schedules and executes the upgrade (current focus)

## Current State
We have a working PSADT implementation that:
- Shows upgrade information dialog
- Displays calendar picker for scheduling
- Creates Windows scheduled tasks
- Handles attended/unattended scenarios

However, the current implementation directly calls Windows 11 Installation Assistant from the scheduled task, which bypasses PSADT's session management and UI capabilities.

## Requirements for Enhancement

### 1. Task Scheduler Architecture Change
**Problem**: Current scheduled task directly calls `Windows11InstallationAssistant.exe /quiet`
**Solution**: Create an intermediate PSADT wrapper script that:
- Gets launched by the scheduled task instead
- Performs all the checks and UI interactions
- Then initiates the actual upgrade

**Implementation Details**:
- Create `Invoke-Win11Upgrade.ps1` in SupportFiles folder
- This script will be a mini PSADT deployment specifically for the scheduled execution
- Scheduled task calls this script instead of the installer directly

### 2. 30-Minute Warning Dialog
**Requirement**: When the scheduled time arrives, show a countdown warning
**Behavior**:
- **Attended (user logged in)**:
  - Show dialog: "Windows 11 upgrade will begin in 30 minutes"
  - Countdown timer visible
  - "Start Now" button to bypass countdown
  - After 30 minutes, auto-start upgrade
- **Unattended (no user/SYSTEM)**:
  - Skip dialog, proceed immediately
  - Log decision in PSADT logs

**Technical Notes**:
- Use PSADT's `Show-InstallationPrompt` with custom countdown
- Or create custom WPF dialog similar to calendar picker
- Must handle user walking away (timeout = proceed)

### 3. Calendar Picker Same-Day Scheduling
**Current**: MinDate = tomorrow
**New**: MinDate = today (with time validation)
**Requirements**:
- Allow scheduling for "tonight" (same day)
- Add time slots: 8 PM, 10 PM, 11 PM for same-day
- Validate selected time is at least 2 hours from current time
- Show warning if selecting time within next 4 hours

### 4. Sleep Mode and Wake Handling
**Challenge**: Computers might be asleep at scheduled time
**Solutions**:
```powershell
# In scheduled task settings:
$settings = New-ScheduledTaskSettingsSet `
    -WakeToRun `
    -StartWhenAvailable `
    -RestartCount 3 `
    -RestartInterval (New-TimeSpan -Minutes 10)
```
**Additional Considerations**:
- Check if system supports wake timers
- Log wake events
- Handle hybrid sleep/hibernation

### 5. Pre-flight Compatibility Re-check
**When**: At upgrade execution time (not during initial detection)
**What to check**:
- Disk space (minimum 20GB free recommended)
- Windows Update not running
- Critical services status
- Battery > 40% if laptop
- No pending reboot

**Implementation**:
```powershell
Function Test-PreFlightChecks {
    # Quick checks only - full compatibility already verified
    # Focus on changeable conditions
}
```

### 6. PSADT Integration Throughout
**Principle**: All user interactions through PSADT
**Benefits**:
- Consistent UI experience
- Proper session detection
- Centralized logging
- Error handling
- Progress tracking

## File Structure
```
Win11Scheduler-PSADT-v3/
├── Deploy-Application.ps1 (main script)
├── AppDeployToolkit/
│   └── [PSADT v3 files]
└── SupportFiles/
    ├── Show-UpgradeInformationDialog.ps1
    ├── Show-CalendarPicker.ps1 (needs update)
    ├── New-Win11UpgradeTask.ps1 (needs update)
    ├── Invoke-Win11Upgrade.ps1 (NEW - wrapper for scheduled task)
    └── Show-UpgradeCountdown.ps1 (NEW - 30-min warning)
```

## Coding Standards (from CLAUDE.md)
- PowerShell 5.1 compatibility (no PS7 features)
- Use `-eq`, `-ne`, etc. (never `==`, `!=`)
- Place `$null` on left side of comparisons
- No Unicode characters (bullets, special symbols)
- Use `#region` markers for organization
- Complete comment-based help for all functions
- NO PESTER TESTING - use script-based validation

## Testing Requirements
**CRITICAL**: Empirical validation required
- Test scheduled task creation and execution
- Test wake from sleep functionality
- Test 30-minute countdown in attended mode
- Test immediate execution in unattended mode
- Test same-day scheduling
- Test pre-flight checks
- Use SYSTEM context testing via PSExec

## ConnectWise RMM Constraints
- 150-second timeout for detection scripts
- Exit codes: 0 = success, 1 = needs remediation, 2 = not compatible
- Scripts run as SYSTEM by default
- No user interaction in detection phase

## Key Scenarios to Handle
1. **User schedules for tonight at 10 PM**
   - Computer locked but user logged in
   - Should show 30-min warning when user returns
   
2. **Boardroom PC - no one logged in**
   - Scheduled task runs at 2 AM
   - Should proceed silently without any UI
   
3. **User schedules then forgets**
   - 2 weeks later, in middle of work
   - 30-minute warning gives time to save
   
4. **Laptop on battery**
   - Check battery level
   - Warn if too low
   - Defer if critical

## Implementation Priority
1. Create `Invoke-Win11Upgrade.ps1` wrapper script
2. Update `New-Win11UpgradeTask.ps1` to call wrapper
3. Implement 30-minute countdown dialog
4. Update calendar picker for same-day scheduling
5. Add pre-flight checks to wrapper
6. Add wake-to-run support
7. Comprehensive testing

## Success Criteria
- Scheduled task calls PSADT wrapper, not installer directly
- 30-minute warning shown in attended scenarios
- Same-day scheduling works with proper validation
- Computer wakes from sleep for upgrade
- Pre-flight checks prevent failed upgrades
- All interactions use PSADT UI components
- Proper logging throughout process

## Additional Notes
- No registry bypass or requirement circumvention
- Respect all Microsoft Windows 11 requirements
- Maintain user-friendly experience
- Prioritize reliability over speed
- Document all edge cases handled

Remember: The goal is a production-ready, enterprise-grade Windows 11 upgrade scheduler that provides a seamless experience while maintaining full control through PSADT.