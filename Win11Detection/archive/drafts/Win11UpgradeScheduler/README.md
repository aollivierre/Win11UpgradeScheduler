# Windows 11 Upgrade Scheduler - Enhanced PSADT Implementation

## Overview

This is an enhanced Windows 11 upgrade scheduler built on PowerShell App Deployment Toolkit (PSADT) v3.10.2. It provides enterprise-grade scheduling capabilities with improved user experience and reliability.

## Key Improvements

### 1. PSADT Wrapper Script
- **Scheduled Task Integration**: Tasks call a wrapper script instead of the installer directly
- **Session Detection**: Properly detects attended vs unattended sessions
- **30-Minute Countdown**: Shows countdown dialog for attended sessions with "Start Now" option
- **Pre-flight Checks**: Validates system readiness before starting upgrade

### 2. Enhanced Scheduling Options
- **Same-Day Scheduling**: Tonight at 8PM, 10PM, or 11PM
- **Quick Options**: Tomorrow morning/afternoon/evening
- **Custom Date/Time**: Full calendar picker for specific scheduling
- **Minimum Buffer**: Enforces 2-hour minimum scheduling ahead
- **Warning System**: Alerts when scheduling within 4 hours

### 3. Comprehensive Pre-Flight Checks
- **Disk Space**: Ensures 64GB free space available
- **Battery Level**: 50% minimum or AC power connected
- **Windows Updates**: Verifies no updates in progress
- **Pending Reboots**: Detects and prevents conflicts
- **System Resources**: Validates RAM and CPU availability

### 4. Power Management
- **Wake to Run**: Computer wakes from sleep for scheduled upgrades
- **Retry Logic**: Handles sleeping computers gracefully
- **Battery Safety**: Prevents upgrades on low battery

## Architecture

```
Win11UpgradeScheduler/
├── Deploy-Application.ps1          # Main PSADT deployment script
├── AppDeployToolkit/              # PSADT v3.10.2 framework
├── Files/                         # Windows 11 installation media
├── SupportFiles/
│   ├── ScheduledTaskWrapper.ps1   # Wrapper for scheduled execution
│   ├── Show-UpgradeInformationDialog.ps1
│   ├── Show-CalendarPicker.ps1
│   └── Modules/
│       ├── UpgradeScheduler.psm1  # Core scheduling functions
│       └── PreFlightChecks.psm1   # System validation functions
└── Tests/
    └── Test-UpgradeScheduler.ps1  # Comprehensive test suite
```

## Usage

### Interactive Deployment
```powershell
.\Deploy-Application.ps1
```

### Silent Deployment
```powershell
.\Deploy-Application.ps1 -DeployMode Silent
```

### From Scheduled Task (Wrapper)
```powershell
.\SupportFiles\ScheduledTaskWrapper.ps1 -PSADTPath "C:\Path\To\Package" -DeploymentType Install
```

## Module Functions

### UpgradeScheduler Module
- `New-UpgradeSchedule`: Creates scheduled task
- `Get-UpgradeSchedule`: Retrieves current schedule
- `Update-UpgradeSchedule`: Modifies existing schedule
- `Remove-UpgradeSchedule`: Cancels scheduled upgrade
- `New-QuickUpgradeSchedule`: Quick scheduling for tonight/tomorrow

### PreFlightChecks Module
- `Test-SystemReadiness`: Runs all pre-flight checks
- `Test-DiskSpace`: Validates available storage
- `Test-BatteryLevel`: Checks power status
- `Test-WindowsUpdateStatus`: Ensures no active updates
- `Test-PendingReboot`: Detects pending restarts

## Testing

Run the comprehensive test suite:
```powershell
.\Tests\Test-UpgradeScheduler.ps1 -TestType All -Verbose
```

Test specific components:
```powershell
# Test pre-flight checks only
.\Tests\Test-UpgradeScheduler.ps1 -TestType PreFlight

# Test scheduler functions
.\Tests\Test-UpgradeScheduler.ps1 -TestType Scheduler

# Test UI dialogs (requires interaction)
.\Tests\Test-UpgradeScheduler.ps1 -TestType UI -Verbose
```

## PowerShell Compatibility

This implementation is fully compatible with PowerShell 5.1 and follows strict coding standards:
- No PowerShell 7+ operators (`??`, `?.`)
- Proper null comparisons (`$null -eq $var`)
- No ternary operators
- ASCII-compatible strings only

## Deployment Scenarios

### Scenario 1: User Schedules for Tonight
1. User runs deployment during work hours
2. Selects "Tonight - 10PM"
3. Gets warning if less than 4 hours away
4. Computer wakes at 10PM
5. If user logged in: 30-minute countdown
6. If no user: Immediate silent upgrade

### Scenario 2: IT Pushes with Deadline
1. Deploy with SCCM/Intune
2. User sees information dialog with deadline
3. Can schedule within deadline period
4. Automatic scheduling if deadline approaching

### Scenario 3: Scheduled Task Execution
1. Task runs wrapper script at scheduled time
2. Wrapper performs pre-flight checks
3. Shows countdown if attended
4. Launches PSADT deployment
5. Cleans up task after success

## Logging

Logs are stored in:
- `%ProgramData%\Win11UpgradeScheduler\Logs\`
- `%ProgramData%\Logs\Software\` (PSADT logs)

Log files include:
- `SchedulerModule_YYYYMMDD.log`
- `PreFlightChecks_YYYYMMDD.log`
- `TaskWrapper_YYYYMMDD.log`
- PSADT deployment logs

## Requirements

- Windows 10 (any version from 1507 to 22H2)
- PowerShell 5.1 or later
- Administrative privileges
- 64GB free disk space
- 4GB RAM minimum
- Windows 11 compatible hardware

## Support

For issues or questions:
1. Check logs in `%ProgramData%\Win11UpgradeScheduler\Logs\`
2. Run test suite to validate components
3. Review pre-flight check results
4. Ensure PSADT files are not blocked