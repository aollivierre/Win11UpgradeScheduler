# Windows 11 Silent Upgrade - Implementation Handoff Document

## Overview
This document provides everything needed to implement the Windows 11 silent upgrade using Installation Assistant in the existing PSADT framework.

## Key Discovery
**Windows 11 Installation Assistant CAN run completely silently** when:
1. Executed as SYSTEM via scheduled task
2. Using `/QuietInstall /SkipEULA` parameters
3. Hardware meets requirements (with registry bypasses for flexibility)

## Files to Implement

### 1. Replace PreFlightChecks Module
**Current File:** `C:\Code\Windows\Win11UpgradeScheduler-FINAL\src\SupportFiles\Modules\02-PreFlightChecks.psm1`  
**New File:** `C:\code\Windows\02-PreFlightChecks-FINAL.psm1`

**Key Changes:**
- Removed TPM checking (hardware doesn't fluctuate)
- Added flexible storage thresholds (25GB fail, 50GB warn)
- Focus only on conditions that can change

### 2. Update Deploy-Application.ps1
**File:** `C:\Code\Windows\Win11UpgradeScheduler-FINAL\src\Deploy-Application-InstallationAssistant-Version.ps1`  
**Reference:** `C:\code\Windows\Deploy-Application-Installation-Section-Updated.ps1`

**Replace lines 426-525 (Installation section) with new code that:**
- Uses Installation Assistant instead of ISO
- Creates scheduled task as SYSTEM
- Sets registry bypasses (except TPM)
- Monitors briefly to ensure started
- Captures Installation Assistant logs

### 3. Archive ISO Method (Reference Only)
**Reference File:** `C:\code\Windows\Archive-ISO-Method-Reference.ps1`
- Contains original ISO-based code
- Not for production use
- Kept for reference only

## Implementation Steps

### Step 1: Update Pre-Flight Checks
```powershell
# Copy new module over existing
Copy-Item "C:\code\Windows\02-PreFlightChecks-FINAL.psm1" `
    -Destination "C:\Code\Windows\Win11UpgradeScheduler-FINAL\src\SupportFiles\Modules\02-PreFlightChecks.psm1" `
    -Force
```

### Step 2: Update Installation Section
1. Open `Deploy-Application-InstallationAssistant-Version.ps1`
2. Find the Installation region (around line 426)
3. Replace with code from `Deploy-Application-Installation-Section-Updated.ps1`
4. Ensure all PSADT variables are used ($dirFiles, $deployAppScriptFriendlyName, etc.)

### Step 3: Test Warning Scenarios
See `C:\code\Windows\Example-Warning-Handling.ps1` for expected user experiences

### Step 4: Verify Silent Execution
Use `C:\code\Windows\Testing-Silent-InstallationAssistant.ps1` to test

## Critical Implementation Details

### Registry Bypasses
```powershell
# Set these EXCEPT BypassTPMCheck
$bypassKeys = @{
    "BypassCPUCheck" = 1
    "BypassRAMCheck" = 1
    "BypassSecureBootCheck" = 1
    "BypassStorageCheck" = 1
    # NOT setting BypassTPMCheck - we require at least TPM 1.2
}
```

### Scheduled Task Creation
```powershell
$action = New-ScheduledTaskAction -Execute $setupPath -Argument "/QuietInstall /SkipEULA"
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
```

### Storage Thresholds
- **Fail:** < 25GB
- **Warn:** 25-50GB  
- **Pass:** > 50GB

## Testing Checklist

### Pre-Flight Scenarios
- [ ] Machine with 20GB free (should fail)
- [ ] Machine with 35GB free (should warn but allow proceed)
- [ ] Machine with 60GB free (should pass cleanly)
- [ ] Laptop on battery < 50% (should fail)
- [ ] System with pending reboot (should fail)
- [ ] High CPU usage (should warn)

### Deployment Modes
- [ ] Interactive - Upgrade Now
- [ ] Interactive - Schedule for later
- [ ] Silent/Unattended mode
- [ ] Verify countdown wrapper works

### Upgrade Verification
- [ ] Scheduled task creates successfully
- [ ] Installation Assistant runs as SYSTEM
- [ ] No EULA prompt appears
- [ ] C:\$WINDOWS.~BT folder created
- [ ] Logs captured properly

## Logging Locations

```
C:\ProgramData\Win11UpgradeScheduler\Logs\
    ├── PreFlightChecks_YYYYMMDD.log      # Pre-flight check results
    ├── SchedulerModule_YYYYMMDD.log      # Scheduling operations
    ├── TaskWrapper_YYYYMMDD.log           # Wrapper script logs
    └── InstallAssistant_YYYYMMDD_HHMMSS\ # Installation Assistant logs
```

## Common Issues and Solutions

### Issue: EULA prompt appears
**Solution:** Ensure running as SYSTEM via scheduled task, not regular admin

### Issue: Process starts but exits quickly
**Solution:** Check pre-flight logs - likely failed requirement

### Issue: Upgrade folder not created
**Solution:** Check if already on Windows 11 or if TPM missing

## Reference Documents

1. **Final Plan:** `Win11-Silent-InstallAssistant-FINAL-PLAN.md`
2. **FAQ:** `Win11-Silent-Upgrade-FAQ.md`
3. **Testing Script:** `Testing-Silent-InstallationAssistant.ps1`
4. **Warning Examples:** `Example-Warning-Handling.ps1`

## Key Benefits

1. **No ISO Required** - 4MB download vs 3GB+
2. **Truly Silent** - No EULA when run correctly
3. **Flexible Storage** - 25GB minimum vs 64GB official
4. **Simple Implementation** - No mount/unmount complexity
5. **Always Latest** - Installation Assistant downloads current version

## Contact for Questions

Implementation follows existing PSADT patterns. All custom code integrates with existing framework functions and variables.

**Remember:** The key to silent execution is running as SYSTEM via scheduled task!