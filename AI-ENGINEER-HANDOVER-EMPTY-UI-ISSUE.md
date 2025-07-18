# AI Engineer Handover: Critical Empty UI Dialog Issue in SYSTEM Context

## CRITICAL ISSUE SUMMARY
When Windows 11 Upgrade Scheduler runs as a scheduled task under SYSTEM account and preflight checks fail, it attempts to show an error dialog to the logged-in user. However, the dialog appears EMPTY with only a red X icon and no text. This is a critical user experience failure that must be fixed.

## OBJECTIVE
Fix the empty UI dialog issue so that when running as SYSTEM via scheduled task, error messages display properly to the logged-in user with full text content.

## TECHNICAL BACKGROUND

### Architecture Overview
1. **Main Script**: `C:\code\Win11UpgradeScheduler\Win11UpgradeScheduler-FINAL\src\Deploy-Application-InstallationAssistant-Version.ps1`
2. **Scheduled Task Wrapper**: `C:\code\Win11UpgradeScheduler\Win11UpgradeScheduler-FINAL\src\SupportFiles\ScheduledTaskWrapper.ps1`
3. **PSADT Toolkit**: `C:\code\Win11UpgradeScheduler\Win11UpgradeScheduler-FINAL\src\AppDeployToolkit\AppDeployToolkitMain.ps1`

### Execution Flow
1. Scheduled task runs `ScheduledTaskWrapper.ps1` as SYSTEM
2. Wrapper performs preflight checks via `C:\code\Win11UpgradeScheduler\Win11UpgradeScheduler-FINAL\src\SupportFiles\Modules\02-PreFlightChecks.psm1`
3. When checks fail, wrapper needs to show error to user
4. Since running as SYSTEM, uses `Execute-ProcessAsUser` to show UI in user context
5. Creates temporary PowerShell script in `%TEMP%` (e.g., `PreFlightError_20250718114611.ps1`)
6. Temporary script loads PSADT and calls `Show-InstallationPrompt`

### The Problem
The temporary script executes but `Show-InstallationPrompt` shows empty dialog. Evidence from Process Explorer:
- Parent: `wscript.exe /e:vbscript C:\Windows\SystemTemp\PSAppDeployToolkit\ExecuteAsUser\RunHidden.vbs`
- Child: `powershell.exe -ExecutionPolicy Bypass -File "C:\Windows\TEMP\PreFlightError_20250718114611.ps1"`
- Result: PSADT dialog appears but with NO TEXT

## WHAT HAS BEEN ATTEMPTED

### Attempt 1: Fixed Script Generation Format
**File**: `C:\code\Win11UpgradeScheduler\Win11UpgradeScheduler-FINAL\src\SupportFiles\ScheduledTaskWrapper.ps1`
**Lines**: 347-370
**Change**: Switched from string concatenation to here-string format
```powershell
$errorScript = @"
# Load PSADT toolkit
. '$toolkitMain'

# Show the prompt
Show-InstallationPrompt -Message "$escapedMessage" -ButtonRightText 'OK' -Icon Error
"@
```
**Result**: Still shows empty dialog

### Attempt 2: Added Debug Logging
**File**: Same as above
**Change**: Added extensive logging to temporary script
```powershell
Add-Content -Path "`$env:TEMP\PreFlightError_Debug.log" -Value "[`$(Get-Date)] Starting PreFlightError script"
```
**Purpose**: Track if toolkit loads and where it fails
**Check**: Look for `C:\Users\[Username]\AppData\Local\Temp\PreFlightError_Debug.log`

### Attempt 3: Created Show-ScheduledPrompt Function
**File**: `C:\code\Win11UpgradeScheduler\Win11UpgradeScheduler-FINAL\src\Deploy-Application-InstallationAssistant-Version.ps1`
**Lines**: 137-204
**Purpose**: Handle UI display when running as SYSTEM in scheduled mode
**Status**: Function exists but scheduled task wrapper doesn't use it

## KEY FILES TO INVESTIGATE

### 1. Scheduled Task Wrapper - WHERE ERROR ORIGINATES
```
C:\code\Win11UpgradeScheduler\Win11UpgradeScheduler-FINAL\src\SupportFiles\ScheduledTaskWrapper.ps1
```
**Focus on**:
- Lines 340-380: The SYSTEM context error display logic
- Variable `$toolkitMain` path construction
- How `Execute-ProcessAsUser` is called

### 2. PSADT Execute-ProcessAsUser Function
```
C:\code\Win11UpgradeScheduler\Win11UpgradeScheduler-FINAL\src\AppDeployToolkit\AppDeployToolkitMain.ps1
```
**Search for**: `Function Execute-ProcessAsUser`
**Also check**: `RunHidden.vbs` usage

### 3. Preflight Module
```
C:\code\Win11UpgradeScheduler\Win11UpgradeScheduler-FINAL\src\SupportFiles\Modules\02-PreFlightChecks.psm1
```
**Focus on**: How error messages are formatted and returned

### 4. Test Files for Reference
```
C:\code\Win11UpgradeScheduler\Create-TestScheduledTask.ps1
C:\code\Win11UpgradeScheduler\TEST-PLAN-BALLOON-UI-FIXES.md
```

## CRITICAL DEBUGGING STEPS

### 1. Capture Temporary Script Content
When scheduled task runs, immediately check:
```
C:\Users\[ActiveUser]\AppData\Local\Temp\PreFlightError_*.ps1
```
Verify the script content and paths are correct.

### 2. Check Debug Log
```
C:\Users\[ActiveUser]\AppData\Local\Temp\PreFlightError_Debug.log
```
This should show if toolkit loads and where execution fails.

### 3. Process Monitor
Use ProcMon to trace:
- File access when loading AppDeployToolkitMain.ps1
- Registry access for UI language detection
- Any ACCESS DENIED errors

## HYPOTHESES TO TEST

### Hypothesis 1: Path Resolution Issue
The toolkit path might not resolve correctly when Execute-ProcessAsUser switches context.
**Test**: Hard-code absolute paths in the temporary script

### Hypothesis 2: Variable Scope Issue
Variables like `$deployAppScriptFriendlyName` might not be available in the temporary script context.
**Test**: Ensure all required variables are defined in the temporary script

### Hypothesis 3: UI Language Detection Failure
PSADT might fail to detect UI language when running via Execute-ProcessAsUser.
**Test**: Force English UI messages in the temporary script

### Hypothesis 4: Double-Escaping Issue
The message might be getting double-escaped during script generation.
**Test**: Log the exact message content at each stage

## TESTING METHODOLOGY

### 1. Create Test Scheduled Task
```powershell
# Run this to create test task:
C:\code\Win11UpgradeScheduler\Create-TestScheduledTask.ps1
```

### 2. Simulate Preflight Failure
Ensure system has a condition that fails preflight (e.g., pending reboot)

### 3. Run Task and Capture
```powershell
Start-ScheduledTask -TaskName "TestWin11UpgradeUI"
```

### 4. Verify Fix
- Dialog should show WITH TEXT
- No empty dialog
- Error message clearly visible

## EXPECTED SOLUTION APPROACH

1. **First**: Add comprehensive logging to understand exact failure point
2. **Identify**: Is it path issue, variable scope, or PSADT initialization?
3. **Fix**: Modify script generation in ScheduledTaskWrapper.ps1
4. **Test**: Run as SYSTEM via scheduled task
5. **Validate**: Ensure dialog shows with proper text

## SUCCESS CRITERIA
- Error dialog displays with full error text when running as SYSTEM
- No empty dialogs
- Consistent behavior across different error conditions
- Debug logs show successful execution path

## ADDITIONAL CONTEXT
- This is PowerShell 5.1 on Windows 10
- PSADT version 3.10.2
- Running in Hyper-V VM
- User is RDP connected (not console session)

## CRITICAL NOTE
Do NOT assume the fix works without empirical testing. The issue MUST be validated by:
1. Creating the scheduled task
2. Running it as SYSTEM
3. Confirming the dialog shows WITH TEXT
4. Checking all debug logs

This is a critical UX issue that makes the application appear broken to users. The fix must be thorough and properly tested.