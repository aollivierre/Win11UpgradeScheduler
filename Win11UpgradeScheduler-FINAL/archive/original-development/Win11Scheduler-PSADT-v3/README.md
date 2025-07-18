# Windows 11 Upgrade Scheduler - PSADT v3 Implementation

This is a complete enterprise-grade Windows 11 upgrade scheduling solution built with PowerShell App Deployment Toolkit (PSADT) v3.10.2.

## 📁 Project Structure

```
Win11Scheduler-PSADT-v3/
├── AppDeployToolkit/           # PSADT v3.10.2 framework files
├── SupportFiles/               # Custom dialog and function files
│   ├── Show-UpgradeInformationDialog.ps1  # Pre-upgrade information dialog
│   ├── Show-CalendarPicker.ps1             # WPF calendar picker
│   └── New-Win11UpgradeTask.ps1            # Scheduled task creation
├── Files/                      # Deployment files (Windows 11 setup, etc.)
├── Documentation/              # Project documentation
├── Deploy-Application-Complete.ps1  # Production deployment script
└── Deploy-Application-Test.ps1      # Test version (bypasses compatibility)
```

## 🚀 Features

- **Complete PSADT v3.10.2 Integration**: Full enterprise deployment framework
- **Professional User Experience**: Multi-stage dialog workflow
- **Actual Task Creation**: Creates real Windows scheduled tasks (not simulation)
- **WPF Calendar Picker**: Modern date/time selection interface
- **Enterprise Compliance**: Follows Microsoft task organization standards
- **Deferral Management**: User can defer upgrades with tracking
- **Comprehensive Logging**: Full audit trail of all operations

## 🔧 Usage

### Production Deployment
```powershell
PowerShell.exe -ExecutionPolicy Bypass -File "Deploy-Application-Complete.ps1" -DeployMode Interactive
```

### Testing (Bypasses Compatibility Checks)
```powershell
PowerShell.exe -ExecutionPolicy Bypass -File "Deploy-Application-Test.ps1" -DeployMode Interactive
```

## 📋 Workflow

1. **PSADT Welcome Dialog**
   - Detects and closes running applications
   - Provides deferral options (if available)
   - Enterprise branding and messaging

2. **Windows 11 Upgrade Information Dialog**
   - Displays upgrade requirements and process details
   - Shows organization name and deadline information
   - Options: Upgrade Now | Schedule | Remind Me Later

3. **WPF Calendar Picker**
   - Modern calendar interface for date selection
   - Time picker for scheduling
   - Constraint validation (within deadline period)

4. **Scheduled Task Creation**
   - Creates task in `\Microsoft\Windows\Win11Upgrade\`
   - Runs with SYSTEM privileges and highest elevation
   - Configures retry logic and power settings

## 🎯 Scheduled Tasks Location

Created tasks can be found in Task Scheduler at:
**Task Scheduler Library > Microsoft > Windows > Win11Upgrade**

## 📝 System Requirements

- Windows 10 (any version) for scheduling Windows 11 upgrades
- PowerShell 5.0 or later
- Administrator privileges for task creation
- .NET Framework 4.0+ (for WPF dialogs)

## 🔐 Security Features

- Input validation and sanitization
- Proper error handling and logging
- No hard-coded credentials or secrets
- Enterprise-standard task permissions

## 📊 Exit Codes

- `0`: Success
- `1602`: User cancelled
- `1618`: User deferred
- `69001`: System compatibility check failed
- `69002`: Task creation failed
- `69003-69005`: Missing required files
- `60001`: General error

## 🧪 Testing

The project includes comprehensive testing capabilities:
- Standalone task creation verification
- Debug scripts for troubleshooting
- Test deployment script with bypassed checks

## 📧 Support

This implementation follows enterprise deployment best practices and is suitable for SCCM, Intune, or other enterprise deployment tools.