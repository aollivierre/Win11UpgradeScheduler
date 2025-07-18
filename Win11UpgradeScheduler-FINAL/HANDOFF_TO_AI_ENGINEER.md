# Windows 11 Upgrade Scheduler - Engineering Handoff Document

## Executive Summary
This is a PowerShell App Deployment Toolkit (PSADT) v3.10.2 based Windows 11 upgrade solution that was experiencing production failures due to stub files. The system has been partially fixed but requires completion of the following critical issues:

1. **Error Code Issue**: The deployment shows "has failed with error code:" with a blank error code
2. **Windows 11 Installation Media**: The actual Windows 11 Installation Assistant needs proper integration
3. **Exit Code Initialization**: The `$mainExitCode` variable is not initialized properly

## Project Structure
```
C:\code\Windows\Win11UpgradeScheduler-FINAL\
├── src\
│   ├── Deploy-Application.ps1 (550 lines - MAIN SCRIPT)
│   ├── AppDeployToolkit\
│   │   ├── AppDeployToolkitMain.ps1 (13,738 lines)
│   │   ├── AppDeployToolkitExtensions.ps1 (1,195 lines)
│   │   └── AppDeployToolkitConfig.xml
│   ├── Files\
│   │   ├── setup.exe (currently a mock C# executable)
│   │   ├── Windows11InstallationAssistant.exe (4MB - real Microsoft file)
│   │   └── CreateMockSetup.ps1
│   └── SupportFiles\
│       ├── Modules\
│       │   ├── 01-UpgradeScheduler.psm1 (494 lines)
│       │   └── 02-PreFlightChecks.psm1 (535 lines)
│       ├── UI\
│       │   ├── 01-Show-EnhancedCalendarPicker.ps1 (288 lines)
│       │   └── 02-Show-UpgradeInformationDialog.ps1 (305 lines)
│       └── ScheduledTaskWrapper.ps1 (340 lines)
├── archives\
│   └── [Contains full implementation backups]
└── logs\
    └── [Various log files]
```

## Issues to Address

### 1. Primary Issue: Blank Error Code
**Location**: `Deploy-Application.ps1`, lines 520-532
**Problem**: The error dialog shows "has failed with error code:" with no actual code
**Root Cause**: The `$mainExitCode` variable is not initialized at the script level

**Fix Required**:
Add this line after the parameter block (around line 59):
```powershell
# Initialize main exit code
[int32]$mainExitCode = 0
```

### 2. Windows 11 Installation Assistant Integration
**Current State**: 
- Downloaded `Windows11InstallationAssistant.exe` (4MB) is in `Files\` directory
- Currently using a mock `setup.exe` for testing
- The real Installation Assistant has its own UI and doesn't accept command-line parameters

**Options**:
1. **Use Windows 11 ISO**: Download full Windows 11 ISO and extract setup.exe
2. **Silent Wrapper**: Create a wrapper that handles the Installation Assistant silently
3. **Media Creation Tool**: Use the Windows 11 Media Creation Tool for unattended setup

**Recommended**: Option 1 - Use proper Windows 11 ISO media

### 3. Setup.exe Implementation
**Current Files in `Files\` directory**:
- `setup.exe` - Mock C# executable (simulates upgrade)
- `setup.exe.bak` - Original batch file wrapper
- `Windows11InstallationAssistant.exe` - Real Microsoft tool
- `CreateMockSetup.ps1` - Script to create mock executable

**Required Actions**:
1. Download Windows 11 ISO from Microsoft
2. Extract the ISO contents
3. Copy the real `setup.exe` and supporting files to the `Files\` directory
4. Remove mock files

## What Was Fixed Previously

### 1. Stub File Replacements
- **Deploy-Application.ps1**: Was 286 lines (stub), now 550 lines (full)
- Stub version only had: `Write-Log "DEMO MODE: Simulating Windows 11 upgrade"`
- Full version includes actual upgrade execution logic

### 2. Module Import Path Fixes
Fixed missing number prefixes:
- `UpgradeScheduler.psm1` → `01-UpgradeScheduler.psm1`
- `PreFlightChecks.psm1` → `02-PreFlightChecks.psm1`

### 3. UI Script Path Fixes
Added missing `UI\` subdirectory:
- `$dirSupportFiles\Show-UpgradeInformationDialog.ps1` → `$dirSupportFiles\UI\02-Show-UpgradeInformationDialog.ps1`

### 4. Redundant Prompt Removal
Fixed the flow where users would get two scheduling prompts:
- Info dialog "Schedule" button now goes directly to calendar picker
- No more "When would you like to schedule" intermediate prompt

### 5. Syntax Errors
Fixed brace mismatches around line 296-405 in Deploy-Application.ps1

## Testing Instructions

### To Test Current State:
```powershell
cd C:\code\Windows\Win11UpgradeScheduler-FINAL\src
.\Deploy-Application.ps1
```

### Expected Flow:
1. Pre-flight checks run (disk space, battery, etc.)
2. Information dialog appears with three options:
   - **Upgrade Now**: Proceeds to installation
   - **Schedule**: Opens calendar picker directly
   - **Cancel**: Exits
3. If "Upgrade Now": Shows welcome/defer dialog, then runs setup.exe
4. If "Schedule": Creates scheduled task for selected time

### Current Behavior:
- Everything works except final error shows blank error code
- Mock setup.exe runs successfully but deployment reports failure

## Logs Location
- PSADT Logs: `C:\Windows\Logs\Software\Windows11Upgrade_PSAppDeployToolkit_Install.log`
- Scheduler Logs: `C:\ProgramData\Win11UpgradeScheduler\Logs\`

## Critical Code Sections

### Error Display (Deploy-Application.ps1, lines 527-531):
```powershell
Else {
    Show-InstallationPrompt -Message "$installTitle has failed with error code: $mainExitCode" `
        -ButtonRightText 'OK' `
        -Icon Error
}
```

### Setup Execution (Deploy-Application.ps1, lines 450-466):
```powershell
$exitCode = Execute-Process -Path $setupPath `
    -Parameters ($setupArgs -join ' ') `
    -WindowStyle 'Hidden' `
    -IgnoreExitCodes '3010,1641' `
    -PassThru

If ($exitCode.ExitCode -eq 0) {
    Write-Log -Message "Windows 11 upgrade completed successfully"
}
ElseIf ($exitCode.ExitCode -eq 3010 -or $exitCode.ExitCode -eq 1641) {
    Write-Log -Message "Windows 11 upgrade completed successfully but requires restart"
    $mainExitCode = 3010
}
Else {
    Write-Log -Message "Windows 11 upgrade failed with exit code: $($exitCode.ExitCode)"
    $mainExitCode = $exitCode.ExitCode
}
```

## Recommended Next Steps

1. **Initialize $mainExitCode** at script level
2. **Download Windows 11 ISO** from: https://www.microsoft.com/software-download/windows11
3. **Extract ISO** and copy real setup.exe + supporting files
4. **Test with real media** to ensure proper upgrade flow
5. **Handle Installation Assistant** if that's the preferred method

## Additional Notes
- System uses PowerShell 5.1 (not 7.x) for compatibility
- Scheduled tasks run as SYSTEM account
- Pre-flight checks include battery, disk space, pending reboots
- UI supports same-day scheduling (Tonight 8PM/10PM/11PM)
- Successfully creates scheduled tasks with wake-from-sleep support

The deployment is 95% complete - just needs proper Windows 11 media integration and the $mainExitCode initialization fix.