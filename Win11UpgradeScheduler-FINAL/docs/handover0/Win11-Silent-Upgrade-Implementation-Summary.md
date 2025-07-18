# Windows 11 Silent Upgrade Implementation Summary

## Overview
This implementation leverages our **proven discovery** that Windows 11 Installation Assistant CAN run completely silently when executed as SYSTEM via scheduled task with `/QuietInstall /SkipEULA` parameters.

## Key Implementation Changes

### 1. Storage Requirements (Updated in PreFlightChecks Module)
- **FAIL**: < 25GB (hard stop)
- **WARN**: 25-50GB (proceed with warning)  
- **PASS**: > 50GB (optimal)

Based on our test showing actual usage of ~36GB plus Windows.old backup.

### 2. TPM Requirements (New in PreFlightChecks Module)
- **FAIL**: No TPM detected
- **FAIL**: TPM present but disabled
- **WARN**: TPM 1.2 (acceptable but not ideal)
- **PASS**: TPM 2.0+ (recommended)

We do NOT bypass TPM completely - at least TPM 1.2 is required for security.

### 3. Installation Method (Deploy-Application.ps1)
Replaced ISO-based approach with Installation Assistant:

```powershell
# Old approach (lines 433-495):
$setupPath = Join-Path -Path $dirFiles -ChildPath 'ISO\setup.exe'
# Complex ISO mounting, EULA parameters that only work with setup.exe

# New approach:
$setupPath = Join-Path -Path $dirFiles -ChildPath 'Windows11InstallationAssistant.exe'
# Create scheduled task as SYSTEM
# Run with /QuietInstall /SkipEULA
# Completely silent, no user interaction needed!
```

### 4. Registry Bypass Configuration
Sets bypass keys for flexibility but NOT for TPM:
- BypassCPUCheck = 1
- BypassRAMCheck = 1  
- BypassSecureBootCheck = 1
- BypassStorageCheck = 1
- BypassTPMCheck = NOT SET (we check TPM separately)

### 5. Process Monitoring
- Verifies Installation Assistant starts correctly
- Checks for C:\$WINDOWS.~BT folder creation
- Monitors process running as SYSTEM
- Captures logs from multiple locations

## User Experience Flow

### Attended Mode
1. Pre-flight checks with warnings displayed
2. Option to "Upgrade Now" or "Schedule"
3. If scheduled: Uses existing calendar picker and countdown
4. Clear messaging about silent background operation

### Unattended Mode  
1. Silent pre-flight checks
2. Immediate scheduled task creation
3. Upgrade runs completely silently
4. No user prompts or interaction

## Advantages Over ISO Method

| Aspect | ISO Method | Installation Assistant |
|--------|------------|----------------------|
| Download Size | 3GB+ ISO | 4MB installer |
| Silent EULA | Only with setup.exe | Works with SYSTEM account |
| Complexity | Mount/unmount ISO | Simple executable |
| Parameters | Many complex options | Just /QuietInstall /SkipEULA |
| Official Support | Yes | Yes |

## Testing Recommendations

1. **Test Storage Scenarios**
   - Machine with 20GB free (should fail)
   - Machine with 35GB free (should warn but proceed)
   - Machine with 60GB free (should pass)

2. **Test TPM Scenarios**
   - VM with no TPM (should fail)
   - Machine with TPM 1.2 (should warn but proceed)
   - Machine with TPM 2.0 (should pass)

3. **Test Deployment Modes**
   - Interactive with immediate upgrade
   - Interactive with scheduling
   - Silent/unattended deployment

4. **Monitor Upgrade Progress**
   - Check Task Manager for Windows11InstallationAssistant.exe
   - Verify C:\$WINDOWS.~BT folder grows
   - Confirm no UI appears

## Important Notes

1. **EULA Bypass Works!** - When run as SYSTEM via scheduled task
2. **No ISO Required** - Installation Assistant downloads everything
3. **Flexible Storage** - 25GB minimum vs 64GB official
4. **TPM Required** - At least 1.2 for security (not fully bypassed)
5. **Logging Enhanced** - Captures Installation Assistant logs

## Files Modified

1. **SupportFiles\Modules\02-PreFlightChecks.psm1**
   - Added flexible storage thresholds
   - Added TPM checking function
   - Added warning severity support

2. **Deploy-Application.ps1** (Installation section only)
   - Replaced ISO method with Installation Assistant
   - Added scheduled task creation as SYSTEM
   - Enhanced progress messaging
   - Added log collection

## Next Steps

1. Replace the existing PreFlightChecks module with the updated version
2. Update the Installation section in Deploy-Application.ps1
3. Test the countdown wrapper functionality
4. Validate on Windows 10 test machines

This implementation maintains all existing PSADT features while using our proven silent Installation Assistant approach!