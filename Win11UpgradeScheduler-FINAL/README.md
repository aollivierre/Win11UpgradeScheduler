# Windows 11 Upgrade Scheduler

A comprehensive solution for scheduling Windows 11 upgrades using PowerShell App Deployment Toolkit (PSADT) v3.10.2.

## Overview

This project provides an enterprise-ready Windows 11 upgrade scheduler with enhanced user experience features including:
- Interactive calendar picker for scheduling upgrades
- "Tonight" quick scheduling options (6 PM, 8 PM, 10 PM, Midnight)
- Pre-flight system validation checks
- Seamless integration with PSADT for deployment
- Support for both interactive and silent deployments

## Project Structure

```
Win11UpgradeScheduler-FINAL/
├── src/                      # Production-ready source code
│   ├── Deploy-Application.ps1     # Main PSADT deployment script
│   ├── AppDeployToolkit/         # PSADT framework (v3.10.2)
│   └── SupportFiles/            # Modules and UI components
├── docs/                     # Project documentation
├── tests/                    # Test scripts and results
├── demos/                    # Demonstration scripts
├── tools/                    # Deployment and development tools
└── archive/                  # Previous versions and iterations
```

## Quick Start

1. **Run a Quick Demo**
   ```powershell
   .\demos\01-Quick-Start\Demo-QuickStart.ps1
   ```

2. **Deploy the Solution**
   ```powershell
   .\src\Deploy-Application.ps1
   ```

## Key Features

### Enhanced Scheduling
- Visual calendar picker with date/time selection
- Quick "Tonight" options for same-day scheduling
- Business hours validation
- Weekend scheduling support

### Pre-Flight Checks
- Hardware compatibility validation
- Disk space verification
- Battery and power status checks
- TPM and Secure Boot validation

### PSADT Integration
- Full support for PSADT deployment modes
- Silent and interactive installation options
- Proper session detection and user notification
- Scheduled task creation for deferred upgrades

## Requirements

- Windows 10 version 1903 or later
- PowerShell 5.1
- Administrative privileges
- Windows 11 installation media (place in `src\Files\`)

## Documentation

- [Implementation Guide](docs/03-Implementation/README-Implementation.md)
- [Deployment Guide](docs/05-Deployment/DEPLOYMENT-GUIDE.md)
- [Validation Results](docs/04-Testing/VALIDATION_RESULTS.md)

## Testing

Run the complete test suite:
```powershell
.\tests\03-System-Tests\05-Run-Validation.ps1
```

## Support

For issues or questions, please refer to the documentation in the `docs/` folder.

## License

This project is provided as-is for enterprise Windows 11 deployment scenarios.