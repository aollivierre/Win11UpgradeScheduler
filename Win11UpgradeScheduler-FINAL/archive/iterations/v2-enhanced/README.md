# Windows 11 Upgrade Scheduler - Enhanced PSADT Implementation

## Project Structure

This organized project contains the enhanced Windows 11 Upgrade Scheduler built on PowerShell App Deployment Toolkit (PSADT) v3.10.2.

### Directory Structure

```
Win11UpgradeScheduler-ORGANIZED/
├── README.md                    # This file
├── src/                        # Production code
│   ├── PSADT/                  # PowerShell App Deploy Toolkit v3.10.2
│   ├── Deploy-Application.ps1   # Main deployment script
│   ├── Deploy-Application-Enhanced.ps1  # Enhanced version with all features
│   ├── SupportFiles/
│   │   ├── Modules/
│   │   │   ├── UpgradeScheduler.psm1    # Core scheduling functionality
│   │   │   └── PreFlightChecks.psm1     # System validation checks
│   │   ├── UI/
│   │   │   ├── Show-EnhancedCalendarPicker.ps1  # Enhanced with Tonight options
│   │   │   ├── Show-UpgradeInformationDialog.ps1
│   │   │   └── Show-CalendarPicker-Original.ps1  # Original for reference
│   │   └── ScheduledTaskWrapper.ps1      # Handles attended/unattended sessions
│   └── Files/                  # Windows 11 installation media location
├── docs/                       # Documentation
│   ├── 01-Requirements/        # Business requirements and specifications
│   ├── 02-Implementation/      # Implementation details and guides
│   ├── 03-Testing/            # Test results and validation
│   └── 04-Deployment/         # Deployment guides and procedures
├── tests/                      # Test suites
│   ├── 01-Unit/               # Unit tests
│   ├── 02-Integration/        # Integration tests
│   ├── 03-Validation/         # Validation and empirical tests
│   └── Results/               # Test execution results
├── demos/                      # Demonstration scripts
│   ├── 01-Components/         # Individual component demos
│   └── 02-Workflow/           # Complete workflow demonstrations
└── archive/                    # Archived files
    ├── temp-files/            # Temporary development files
    └── old-versions/          # Previous versions for reference
```

## Quick Start

### 1. Test Individual Components
```powershell
# Test the enhanced calendar picker
.\demos\01-Components\01-Demo-PSADT-Scheduling.ps1

# Test pre-flight checks
.\demos\01-Components\04-Show-PreFlightChecks.ps1
```

### 2. Run Complete Workflow
```powershell
# Change to source directory
cd .\src\

# Run the enhanced deployment
.\Deploy-Application-Enhanced.ps1 -DeploymentType Install -DeployMode Interactive
```

### 3. Run Tests
```powershell
# Run validation tests
.\tests\03-Validation\03-Validate-Enhancements.ps1
```

## Key Features

### Enhanced Scheduling
- **Same-Day Options**: Tonight at 8PM, 10PM, 11PM
- **Quick Tomorrow Options**: Morning (9AM), Afternoon (2PM), Evening (8PM)
- **14-Day Maximum**: Enforces business deadline
- **Smart Validation**: 2-hour minimum buffer, 4-hour warning

### Pre-Flight Checks
1. **Disk Space**: 64GB minimum required
2. **Battery Level**: 50% or AC power for laptops
3. **Windows Updates**: No active updates allowed
4. **Pending Reboots**: Clean system state required
5. **System Resources**: 4GB RAM minimum

### Session Handling
- **Attended Sessions**: 30-minute countdown with "Start Now" option
- **Unattended Sessions**: Immediate silent execution
- **Wake Support**: Computer wakes from sleep for scheduled upgrades

### PSADT Integration
- Full compatibility with PSADT v3.10.2
- Maintains PSADT UI flow and logging
- Supports all deployment modes (Interactive/Silent/NonInteractive)

## Documentation

### Requirements
- `docs/01-Requirements/Win11UpgradeScheduler_DetailedPrompt.md` - Original requirements

### Implementation
- `docs/02-Implementation/README-Implementation.md` - Implementation overview
- `docs/02-Implementation/IMPLEMENTATION_SUMMARY.md` - Detailed summary

### Testing
- `docs/03-Testing/VALIDATION_RESULTS.md` - Empirical validation results

### Deployment
- `docs/04-Deployment/DEPLOYMENT-GUIDE.md` - Deployment procedures

## Support Files

### Core Modules
- **UpgradeScheduler.psm1**: Handles all scheduling operations
- **PreFlightChecks.psm1**: Validates system readiness

### UI Components
- **Show-EnhancedCalendarPicker.ps1**: Tonight/Tomorrow scheduling UI
- **Show-UpgradeInformationDialog.ps1**: Upgrade information display

### Task Management
- **ScheduledTaskWrapper.ps1**: Manages attended/unattended execution

## Testing

The project includes comprehensive test suites:
- Unit tests for individual components
- Integration tests for module interactions
- Validation tests for empirical verification

## PowerShell Compatibility

All code is PowerShell 5.1 compatible and follows strict standards:
- No PowerShell 7+ operators
- Proper null comparisons
- ASCII-compatible strings only
- Windows 10 1507-22H2 support

## Version History

- **v2.0.0** - Enhanced implementation with Tonight scheduling
- **v1.0.0** - Original PSADT implementation

---

For detailed information, see the documentation in the `docs/` folder.