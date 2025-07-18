# Windows 11 Silent Installation Assistant - FINAL Implementation Plan

## Executive Summary
This plan details the integration of our proven silent Windows 11 Installation Assistant method into the existing PSADT framework. The Installation Assistant runs completely silently when executed as SYSTEM via scheduled task with `/QuietInstall /SkipEULA` parameters.

## Key Decisions from Planning Session

### 1. **No ISO Fallback**
- ISO method code will be archived in separate reference file
- Production code will use Installation Assistant exclusively
- Simpler, cleaner implementation

### 2. **No Progress Monitoring Window**
- Upgrade runs silently in background
- No additional UI complexity
- Users informed it takes 30-90 minutes

### 3. **No Network Bandwidth Checks**
- Let upgrade download at full speed
- No throttling or bandwidth warnings
- Simpler implementation

### 4. **Local Logging Only**
- No email/webhook notifications
- Comprehensive local logs for troubleshooting
- RMM/Intune can handle alerting if needed

### 5. **TPM Checks in Detection Phase Only**
- TPM is hardware - doesn't fluctuate
- Should be checked during initial detection/compatibility
- NOT in pre-flight checks before upgrade execution

## Updated Pre-Flight Checks (Things That Fluctuate)

### What SHOULD be in Pre-Flight:
1. **Disk Space** - Can change between scheduling and execution
2. **Battery Level** - Critical for laptops, changes constantly  
3. **Windows Updates** - Don't want concurrent updates
4. **Pending Reboots** - System state can change
5. **System Resources** - CPU/Memory usage fluctuates

### What should NOT be in Pre-Flight:
1. **TPM Status** - Hardware, doesn't change
2. **CPU Model** - Hardware, doesn't change
3. **RAM Amount** - Hardware, doesn't change
4. **Windows Version** - Relatively stable

## Implementation Changes Required

### 1. Update Pre-Flight Checks Module (02-PreFlightChecks.psm1)

#### Remove TPM Check Function
- Delete `Test-TPMStatus` function entirely
- Remove TPM from `Test-SystemReadiness`
- Keep only checks for fluctuating conditions

#### Update Storage Thresholds
```powershell
$script:MinDiskSpaceGB = 25      # FAIL threshold
$script:WarnDiskSpaceGB = 50     # WARN threshold  
$script:OfficialDiskSpaceGB = 64 # Reference only
```

### 2. Create Detection Script (Separate)

Create new file: `Test-Win11Compatibility.ps1` for one-time checks:
```powershell
# This runs during detection phase, not remediation
function Test-Win11Compatibility {
    $compatible = $true
    $issues = @()
    
    # Check TPM (at least 1.2)
    $tpm = Get-CimInstance -Namespace "Root\CIMv2\Security\MicrosoftTpm" -ClassName Win32_Tpm -ErrorAction SilentlyContinue
    if (!$tpm -or !$tpm.IsEnabled_InitialValue) {
        $compatible = $false
        $issues += "No TPM or TPM disabled"
    }
    
    # Check CPU architecture
    # Check UEFI vs BIOS
    # Check Windows 10 version
    # etc.
    
    return @{
        Compatible = $compatible
        Issues = $issues
    }
}
```

### 3. Update Deploy-Application.ps1

#### Installation Section (Lines 426-525)
Replace entirely with Installation Assistant method:
```powershell
# Use Installation Assistant with proven silent method
$setupPath = Join-Path -Path $dirFiles -ChildPath 'Windows11InstallationAssistant.exe'

If (Test-Path -Path $setupPath) {
    # Set registry bypasses (except TPM)
    # Create scheduled task as SYSTEM
    # Run with /QuietInstall /SkipEULA
    # Monitor briefly to ensure started
    # Log everything
}
```

#### Pre-Installation Section Updates
- Remove any TPM checks
- Show warnings for disk space 25-50GB
- Use existing countdown wrapper functionality

### 4. Archive ISO Method Code

Create: `Archive-ISO-Method-Reference.ps1`
- Copy original ISO-based installation code
- Document why we moved away from it
- Keep for reference only

### 5. Logging Structure

```
C:\ProgramData\Win11UpgradeScheduler\Logs\
    ├── PreFlightChecks_YYYYMMDD.log
    ├── SchedulerModule_YYYYMMDD.log
    ├── TaskWrapper_YYYYMMDD.log
    └── InstallAssistant_YYYYMMDD_HHMMSS\
        └── [Installation Assistant logs copied here]
```

## File Changes Summary

### Files to Modify:
1. **SupportFiles\Modules\02-PreFlightChecks.psm1**
   - Remove TPM checking
   - Update storage thresholds
   - Keep only fluctuating checks

2. **Deploy-Application.ps1**
   - Replace Installation section (lines 426-525)
   - Update pre-installation messaging
   - Remove ISO references

3. **SupportFiles\ScheduledTaskWrapper.ps1**
   - Already compatible, no changes needed

### Files to Create:
1. **Archive-ISO-Method-Reference.ps1**
   - Original ISO installation code
   - Documentation of approach

2. **Test-Win11Compatibility.ps1** (Optional)
   - One-time compatibility checks
   - Includes TPM, CPU, etc.

## Testing Checklist

1. **Pre-Flight Checks**
   - [ ] Test with 20GB free (should fail)
   - [ ] Test with 35GB free (should warn but proceed)
   - [ ] Test with 60GB free (should pass)
   - [ ] Test with low battery
   - [ ] Test with pending Windows Updates
   - [ ] Test with pending reboot

2. **Installation Flow**
   - [ ] Test attended mode with "Upgrade Now"
   - [ ] Test attended mode with scheduling
   - [ ] Test unattended/silent mode
   - [ ] Verify scheduled task creation
   - [ ] Verify SYSTEM execution
   - [ ] Confirm no EULA prompt

3. **Logging**
   - [ ] Verify all log files created
   - [ ] Check Installation Assistant logs copied
   - [ ] Confirm no sensitive data logged

## Benefits of Final Approach

1. **Simplicity**
   - Single installation method (no ISO)
   - No complex progress monitoring
   - Clear separation of detection vs pre-flight

2. **Reliability**
   - Proven silent execution method
   - Only check things that can change
   - Comprehensive logging

3. **User Experience**
   - Clear warnings for low disk space
   - Existing countdown functionality
   - Background execution without interruption

## Handoff Notes for Implementation

1. Start with updating the pre-flight checks module (remove TPM)
2. Archive the ISO method code from current Deploy-Application.ps1
3. Replace installation section with Installation Assistant approach
4. Test each scenario in the testing checklist
5. Ensure all paths use existing PSADT variables ($dirFiles, etc.)
6. Maintain existing error handling patterns

## Key Technical Details

**Silent Execution Command:**
```
Windows11InstallationAssistant.exe /QuietInstall /SkipEULA
```

**Must run as SYSTEM via scheduled task for silent EULA bypass**

**Registry Bypasses to Set:**
- BypassCPUCheck = 1
- BypassRAMCheck = 1  
- BypassSecureBootCheck = 1
- BypassStorageCheck = 1
- BypassTPMCheck = NOT SET (TPM required)

**Expected Timeline:**
- Download: 10-30 minutes (4GB)
- Preparation: 20-40 minutes
- Installation: 20-30 minutes
- Total: 30-90 minutes with automatic restarts

This plan provides a clean, simple implementation that leverages our proven silent Installation Assistant method while maintaining all the robustness of the PSADT framework.