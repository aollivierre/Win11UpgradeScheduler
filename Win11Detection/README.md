# Windows 11 Detection Script for ConnectWise RMM

## Project Structure

```
Win11Detection/
├── README.md                           # This file
├── src/                               # Production-ready source code
│   └── Win11_Detection_ConnectWise.ps1 # Final detection script (v3.1)
├── docs/                              # Documentation
│   ├── 01_Test_Report.md              # Comprehensive validation report
│   └── 02_Validation_Requirements.md   # Testing requirements and procedures
├── tests/                             # Test suite
│   ├── 01_unit_tests/                 # Unit tests for individual components
│   │   ├── 01_test_vm_detection.ps1   # Virtual machine detection tests
│   │   ├── 02_test_previous_results.ps1 # Results.json handling tests
│   │   ├── 03_test_output_parsing.ps1 # Output format validation
│   │   └── 04_test_ps51_compatibility.ps1 # PowerShell 5.1 compatibility
│   ├── 02_integration_tests/          # Integration and system tests
│   │   ├── 01_test_ms_download.ps1    # Microsoft script download test
│   │   └── 02_test_feature_comparison.ps1 # Feature completeness validation
│   └── 03_validation_results/         # Test execution results
│       └── Test_Report_20250715.md    # Validation results snapshot
└── archive/                           # Historical versions and drafts
    ├── old_versions/                  # Previous script iterations
    │   ├── 01_Win11_Detection_ConnectWise_v1.ps1
    │   ├── 02_Win11_Detection_ConnectWise_Complete.ps1
    │   ├── 03_Win11_Detection_ConnectWise_v2_960lines_WithSession.ps1
    │   └── 04_Win11_Detection_Complete_v2.ps1
    └── drafts/                        # Development drafts and experiments
        ├── Deploy-Application-Test.ps1
        ├── Deploy-Application-Test-Fixed.ps1
        └── Test-SessionDetection.ps1
```

## Quick Start

### Production Script
The production-ready detection script is located at:
```
src/Win11_Detection_ConnectWise.ps1
```

### Key Features
- Windows 11 compatibility detection for physical machines
- Virtual machine exclusion (VMware, Hyper-V, VirtualBox, etc.)
- Minimum Windows 10 version: 2004 (Build 19041)
- Hardware compatibility checks via Microsoft's HardwareReadiness.ps1
- DirectX 12 and WDDM 2.0 detection
- Corporate proxy support with TLS 1.2
- ConnectWise RMM formatted output
- 140-second execution timeout

### Exit Codes
- `0` = No action needed (VM, Already Win11, Win7/8, scheduled, or completed)
- `1` = Remediation required (Win10 2004+ eligible for upgrade)
- `2` = Not compatible (hardware/software requirements not met)

## Testing

### Run All Tests
```powershell
# Unit Tests
Get-ChildItem "tests\01_unit_tests\*.ps1" | ForEach-Object { & $_.FullName }

# Integration Tests
Get-ChildItem "tests\02_integration_tests\*.ps1" | ForEach-Object { & $_.FullName }
```

### Test Results
See `docs/01_Test_Report.md` for comprehensive validation results.

## Documentation

- **Test Report**: `docs/01_Test_Report.md` - Complete validation results
- **Validation Requirements**: `docs/02_Validation_Requirements.md` - Testing procedures

## Version History

### v3.1 (Current - 2025-01-15)
- Final production version
- Removed session detection (handled by PSADT v3)
- Enhanced documentation for Windows 10 minimum requirements
- All tests passing, 100% feature complete

### Previous Versions
See `archive/old_versions/` for historical versions including the 960-line version with session detection.

## Requirements

- PowerShell 5.1 (Windows PowerShell)
- Administrative privileges
- Internet connectivity for Microsoft script download
- ConnectWise RMM agent
- Windows 10 version 2004 (Build 19041) or later for upgrade eligibility

## Support

This script is designed for ConnectWise RMM deployment on enterprise systems. It has been thoroughly tested and validated for production use.