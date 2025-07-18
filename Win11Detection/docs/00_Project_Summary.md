# Windows 11 Detection Script - Project Summary

## Overview
This project contains a comprehensive Windows 11 compatibility detection script specifically designed for ConnectWise RMM deployment in enterprise environments.

## Script Details
- **Name**: Win11_Detection_ConnectWise.ps1
- **Version**: 3.1
- **Date**: 2025-01-15
- **Lines of Code**: 518 (optimized from 960)
- **Execution Time**: ~0.3 seconds average

## Key Capabilities

### 1. Operating System Detection
- Identifies Windows 7, 8, 8.1, 10, and 11
- **Minimum Windows 10**: Version 2004 (Build 19041)
- Excludes legacy OS from upgrade path

### 2. Virtual Machine Detection
Automatically excludes VMs from upgrade eligibility:
- VMware
- Hyper-V
- VirtualBox
- KVM
- Xen
- Parallels
- QEMU

### 3. Hardware Compatibility Checks
- Downloads and executes Microsoft's HardwareReadiness.ps1
- TPM 2.0 verification
- Secure Boot capability
- UEFI firmware
- CPU compatibility
- RAM check (4GB minimum)
- Storage check (64GB minimum)
- DirectX 12 support
- WDDM 2.0 driver model

### 4. Previous Upgrade Detection
- Checks for existing PSADT scheduled tasks
- Reads previous upgrade results from results.json
- Prevents duplicate upgrade attempts

### 5. Risk Assessment
Categorizes incompatibility issues:
- **CRITICAL**: Hardware replacement required
- **HIGH**: Hardware upgrades needed
- **MEDIUM**: Software/driver updates may resolve
- **LOW**: Minor issues unlikely to prevent upgrade

## ConnectWise RMM Integration

### Output Format
```
Win11_Compatible: [YES|NO|VIRTUAL_MACHINE|ALREADY_WIN11|etc]
Win11_Status: [READY_FOR_UPGRADE|NO_ACTION|NOT_COMPATIBLE|CHECK_FAILED]
Win11_Reason: [Detailed reason text]
Win11_OSVersion: [OS caption]
Win11_Build: [Build number]
Win11_ScheduledTask: [YES|NO]
Win11_PreviousAttempt: [NONE|SUCCESS|FAILED|IN_PROGRESS]
Win11_CheckDate: [YYYY-MM-DD HH:MM:SS]
```

### Exit Codes
- `0`: No action needed
- `1`: Remediation required (ready for upgrade)
- `2`: Not compatible

### Timeout
- Script timeout: 140 seconds (ConnectWise limit: 150 seconds)

## Testing Summary

### Test Coverage
- 13 comprehensive test cases
- 100% pass rate
- All 17 required features verified present

### Performance
- Execution time: 0.16-0.29 seconds
- Well within ConnectWise timeout limits
- Efficient network operations

### Compatibility
- PowerShell 5.1 compliant
- No PowerShell 7+ features used
- Proper error handling throughout

## Deployment Notes

1. **Session Detection**: Removed from this version as PSADT v3 handles attended/unattended scenarios
2. **Proxy Support**: Automatic system proxy configuration with TLS 1.2
3. **Error Handling**: Comprehensive try-catch blocks with proper exit codes
4. **Cleanup**: Automatic removal of temporary files

## File Organization

The project has been organized into a clean structure:
- `src/` - Production script
- `docs/` - All documentation
- `tests/` - Complete test suite
- `archive/` - Historical versions

This organization ensures easy maintenance and deployment while preserving the development history.