# ServiceUI.exe Issue - AI Agent Handover Document

## Problem Summary
When a Windows 11 upgrade scheduled task runs from Task Scheduler in SYSTEM context, ServiceUI.exe fails to display UI in the user's interactive session. The tool encounters token manipulation errors (Error 5: Access Denied, Error 6: Invalid Handle) and ultimately fails with CreateProcessAsUser Error 2.

## Current User Experience
1. User schedules Windows 11 upgrade through PSADT interactive UI
2. Scheduled task is created successfully and runs at specified time
3. **Expected**: UI appears showing upgrade progress in user's session
4. **Actual**: No UI visible; ServiceUI.exe fails silently with token errors
5. Upgrade may proceed in background without user awareness

## Technical Context

### ServiceUI.exe Purpose
- MDT tool to display UI from Session 0 (SYSTEM/Services) in user sessions
- Attaches to user process (explorer.exe) to create UI in that session
- Requires token duplication and privilege elevation across session boundaries

### Current Implementation
```powershell
# From 01-UpgradeScheduler.psm1, lines 169-172
$serviceUIPath = Join-Path -Path $PSADTPath -ChildPath 'AppDeployToolkit\ServiceUI.exe'
$arguments = "-process:explorer.exe " + ($psCommand -join ' ')
$taskAction = New-ScheduledTaskAction -Execute $serviceUIPath -Argument $arguments
```

### Error Details
```
OpenProcessToken Error: 5 (Access Denied)
DuplicateTokenEx Error: 6 (Invalid Handle)  
SetTokenInformation Error: 6 (Invalid Handle)
AdjustTokenPrivileges Error: 6 (Invalid Handle)
CreateProcessAsUser Error: 2 (File Not Found)
Exit Code: -1
```

## Root Cause Analysis
1. **Session 0 Isolation**: Windows security prevents services from interacting with user desktop
2. **Token Security**: Modern Windows restricts cross-session token manipulation
3. **SYSTEM Context Limitations**: Even with highest privileges, SYSTEM cannot always manipulate user tokens
4. **Security Hardening**: Each Windows update tightens these restrictions further

## Files to Review (in order)

### 1. CLAUDE.md
**Location**: `C:\Code\Windows\CLAUDE.md`
**Purpose**: Project-specific coding standards and PowerShell compatibility requirements
**Key Points**: 
- PowerShell 5.1 compatibility requirements
- No Pester testing allowed
- Specific operator restrictions

### 2. Core Module - Scheduler
**Location**: `C:\Code\Windows\Win11UpgradeScheduler-FINAL\src\SupportFiles\Modules\01-UpgradeScheduler.psm1`
**Review**: 
- Lines 155-187: ServiceUI.exe integration logic
- Lines 206-215: Task principal configuration (SYSTEM account)
- Function: `New-Win11UpgradeTask`

### 3. Scheduled Task Wrapper
**Location**: `C:\Code\Windows\Win11UpgradeScheduler-FINAL\src\SupportFiles\ScheduledTaskWrapper.ps1`
**Review**:
- Lines 74-111: User session detection
- Lines 117-127: Deployment script execution
- Pre-flight checks and logging

### 4. Main Deployment Script  
**Location**: `C:\Code\Windows\Win11UpgradeScheduler-FINAL\src\Deploy-Application-InstallationAssistant-Version.ps1`
**Review**:
- How it expects to interact with users
- UI display requirements
- PSADT framework usage

### 5. Test Scripts
**Location**: `C:\Code\Windows\Win11UpgradeScheduler-FINAL\src\Test-ScheduledTaskUI.ps1`
**Review**: Lines 19-26 specifically acknowledge this issue

## Potential Solutions to Investigate

### Option 1: Use PSADT's Execute-ProcessAsUser
PSADT provides this function to run processes in user context from SYSTEM:
```powershell
Execute-ProcessAsUser -Path "powershell.exe" -Parameters $arguments
```

### Option 2: Modify Task Principal
Run task as logged-in user instead of SYSTEM:
```powershell
$taskPrincipal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -RunLevel Highest
```

### Option 3: Alternative UI Methods
- Windows Toast Notifications (work from SYSTEM)
- Write status to file, use separate user-context watcher
- Use Windows Task Scheduler's built-in "Run only when user is logged on"

### Option 4: Enhanced ServiceUI Wrapper
Create intermediate script that:
1. Detects if running as SYSTEM
2. Uses WMI/CIM to create process in user session
3. Falls back to direct execution if in user context

## Testing Requirements

1. **Test Environment Setup**:
   - Windows 10/11 machine with active user session
   - PSADT toolkit installed
   - ServiceUI.exe present in toolkit
   - Admin privileges for testing

2. **Test Scenarios**:
   - Manual task execution while logged in
   - Scheduled execution with user logged in
   - Scheduled execution with locked screen
   - Multiple user sessions

3. **Success Criteria**:
   - UI visible in user session when task runs
   - Proper error handling if UI cannot be displayed
   - User informed of upgrade status

## Recommended Approach

1. **First**: Try using PSADT's `Execute-ProcessAsUser` instead of ServiceUI.exe
2. **Second**: If that fails, implement a hybrid approach:
   - Check if running as SYSTEM
   - If yes, use alternative UI method
   - If no, run directly with UI
3. **Third**: Consider architectural change to avoid SYSTEM context entirely

## Code References
- ServiceUI command construction: `01-UpgradeScheduler.psm1:169-172`
- Task creation: `01-UpgradeScheduler.psm1:206-224`
- Session detection: `ScheduledTaskWrapper.ps1:74-111`

## Additional Context
- User has already tried both x86 and x64 versions of ServiceUI.exe
- Direct PowerShell execution works fine (bypasses ServiceUI)
- Issue only occurs when running from scheduled task as SYSTEM
- This is a known limitation of ServiceUI.exe in modern Windows

## Expected Outcome
The AI agent should implement a solution that ensures users see upgrade UI when the scheduled task runs, regardless of the security context. The solution must be compatible with PowerShell 5.1 and follow all guidelines in CLAUDE.md.