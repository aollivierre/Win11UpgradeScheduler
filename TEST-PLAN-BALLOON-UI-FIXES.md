# Test Plan: Balloon Notification and UI Fixes

## Overview
This test plan verifies the fixes implemented for:
1. Balloon notifications showing misleadingly when preflight checks fail
2. Empty UI dialog when running as scheduled task in system context

## Test Scenarios

### 1. Normal Execution - Preflight Check Failure
**Setup**: Run the script directly (not as scheduled task) with a condition that causes preflight check failure (e.g., pending reboot)

**Command**:
```powershell
PowerShell.exe -ExecutionPolicy Bypass -File "C:\code\Win11UpgradeScheduler\Win11UpgradeScheduler-FINAL\src\Deploy-Application-InstallationAssistant-Version.ps1"
```

**Expected Results**:
- ✓ Preflight check failure dialog shows with proper error message
- ✓ NO balloon notifications appear (neither "Installation complete" nor "Installation incomplete")
- ✓ Script exits with code 1618
- ✓ No second Exit-Script call from Finally block

### 2. Scheduled Task Execution - Preflight Check Failure
**Setup**: Create and run scheduled task as SYSTEM with a condition that causes preflight check failure

**Commands**:
```powershell
# Create scheduled task
$taskAction = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File `"C:\code\Win11UpgradeScheduler\Win11UpgradeScheduler-FINAL\src\SupportFiles\ScheduledTaskWrapper.ps1`" -PSADTPath `"C:\code\Win11UpgradeScheduler\Win11UpgradeScheduler-FINAL\src`""
$taskPrincipal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -RunLevel Highest
$taskSettings = New-ScheduledTaskSettings -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
Register-ScheduledTask -TaskName "TestWin11Upgrade" -Action $taskAction -Principal $taskPrincipal -Settings $taskSettings -Force

# Run the task
Start-ScheduledTask -TaskName "TestWin11Upgrade"
```

**Expected Results**:
- ✓ Preflight check failure dialog shows to the active user (via Execute-ProcessAsUser)
- ✓ Dialog contains proper error message (not empty)
- ✓ NO balloon notifications appear
- ✓ Scheduled task is removed due to failure
- ✓ Script exits with code 1618

### 3. Normal Execution - Successful Preflight Checks
**Setup**: Run the script directly with all preflight checks passing

**Expected Results**:
- ✓ Normal upgrade flow proceeds
- ✓ Balloon notifications work as expected during actual installation

### 4. Scheduled Task Execution - Successful Preflight Checks
**Setup**: Run scheduled task with all preflight checks passing

**Expected Results**:
- ✓ Countdown dialog shows properly (if attended session)
- ✓ Upgrade proceeds normally
- ✓ UI prompts display correctly to user

## Changes Made

### 1. Balloon Notification Fix
- Added `$configShowBalloonNotifications = $false` before Exit-Script when preflight checks fail
- Added `$script:PreflightCheckFailed = $true` flag
- Updated Finally block to check both `$script:OSCheckFailed` and `$script:PreflightCheckFailed`

### 2. UI Display Fix for System Context
- Created `Show-ScheduledPrompt` function that:
  - Detects if running as SYSTEM in scheduled mode
  - Uses Execute-ProcessAsUser to show prompts in user context
  - Falls back to regular Show-InstallationPrompt if not SYSTEM
- Updated scheduled mode preflight failure to use Show-ScheduledPrompt

## Verification Steps
1. Check logs in `C:\ProgramData\Win11UpgradeScheduler\Logs` for proper execution flow
2. Verify no balloon notifications appear when preflight checks fail
3. Confirm UI dialogs show properly with correct text in all scenarios
4. Ensure scheduled task is cleaned up on failure

## Known Issues to Watch
- Execute-ProcessAsUser requires an active user session
- Temporary scripts are created in %TEMP% and should be cleaned up
- Path resolution in temporary scripts needs correct $PSScriptRoot value