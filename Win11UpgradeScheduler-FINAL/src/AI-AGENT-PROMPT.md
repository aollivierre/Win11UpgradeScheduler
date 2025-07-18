# AI Agent Task: Fix ServiceUI.exe UI Display Issue in Windows 11 Upgrade Scheduler

## Your Mission
Fix the issue where ServiceUI.exe fails to display UI when the Windows 11 upgrade scheduled task runs in SYSTEM context. Users should see the upgrade UI in their interactive session when the scheduled task executes.

## Critical Requirements
1. **Read CLAUDE.md first** - Contains PowerShell 5.1 compatibility requirements and coding standards
2. **No Pester testing** - Use script-based testing only
3. **Maintain backward compatibility** - Solution must work on Windows 10 and 11
4. **Follow PSADT patterns** - Use existing framework capabilities

## Problem Statement
When the scheduled task runs:
- ServiceUI.exe fails with token manipulation errors
- No UI is visible to the logged-in user
- Errors: Access Denied (5), Invalid Handle (6), File Not Found (2)

## Your Tasks

### 1. Initial Analysis (Read these files in order)
```
1. C:\Code\Windows\CLAUDE.md (MANDATORY - coding standards)
2. C:\Code\Windows\Win11UpgradeScheduler-FINAL\src\SERVICEUI-ISSUE-HANDOVER.md (detailed issue analysis)
3. C:\Code\Windows\Win11UpgradeScheduler-FINAL\src\SupportFiles\Modules\01-UpgradeScheduler.psm1
4. C:\Code\Windows\Win11UpgradeScheduler-FINAL\src\SupportFiles\ScheduledTaskWrapper.ps1
5. C:\Code\Windows\Win11UpgradeScheduler-FINAL\src\Deploy-Application-InstallationAssistant-Version.ps1
```

### 2. Implement Solution
Choose and implement ONE of these approaches:

**Option A: Use PSADT's Execute-ProcessAsUser**
- Replace ServiceUI.exe with PSADT's built-in function
- Modify task creation in `01-UpgradeScheduler.psm1`
- Update `ScheduledTaskWrapper.ps1` to use new method

**Option B: Hybrid Context Detection**
- Detect if running as SYSTEM
- Use appropriate UI method based on context
- Implement fallback mechanisms

**Option C: Task Principal Modification**
- Change scheduled task to run as user instead of SYSTEM
- Ensure proper privilege elevation
- Handle multiple user scenarios

### 3. Testing Checklist
- [ ] Create test script to verify UI visibility
- [ ] Test manual task execution
- [ ] Test scheduled execution with user logged in
- [ ] Test with locked screen
- [ ] Verify error handling

### 4. Implementation Guidelines
- All code must be PowerShell 5.1 compatible
- Use proper error handling with try/catch
- Add detailed logging for troubleshooting
- Preserve existing functionality
- Comment your changes clearly

## Expected Deliverables
1. Modified code that fixes the UI display issue
2. Test script demonstrating the fix works
3. Brief explanation of chosen approach and why
4. Any additional files created or modified

## Success Criteria
- UI appears in user session when scheduled task runs
- No token manipulation errors
- Works in both attended and locked sessions
- Graceful fallback if UI cannot be displayed

## Quick Start Commands
```powershell
# Test current implementation (will fail)
cd C:\Code\Windows\Win11UpgradeScheduler-FINAL\src
.\Test-ScheduledTaskUI.ps1

# View scheduled tasks
Get-ScheduledTask | Where-Object {$_.TaskName -like "*Win11*"}

# Manual test of ServiceUI
& ".\AppDeployToolkit\ServiceUI.exe" -process:explorer.exe powershell.exe -ExecutionPolicy Bypass -File ".\Test-UI.ps1"
```

## Important Notes
- ServiceUI.exe is already present in `.\AppDeployToolkit\`
- The scheduled task name is "Win11_Upgrade_[timestamp]"
- DeployMode must remain "Interactive" for UI display
- PSADT AppDeployToolkitMain.ps1 has Execute-ProcessAsUser function

Remember: Read CLAUDE.md first for coding standards!