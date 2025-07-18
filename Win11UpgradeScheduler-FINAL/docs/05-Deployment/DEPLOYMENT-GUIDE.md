# Windows 11 Upgrade Scheduler - Deployment Guide

## 📁 Clean Project Structure

This is the **dedicated, clean version** of the Windows 11 Upgrade Scheduler with PSADT v3.10.2 integration.

```
Win11Scheduler-PSADT-v3/
├── AppDeployToolkit/                    # PSADT v3.10.2 framework
│   ├── AppDeployToolkitMain.ps1        # Main PSADT engine
│   ├── AppDeployToolkitConfig.xml      # Configuration
│   └── [other PSADT files]
├── SupportFiles/                       # Custom project functions
│   ├── Show-UpgradeInformationDialog.ps1  # Information dialog
│   ├── Show-CalendarPicker.ps1            # Calendar picker
│   └── New-Win11UpgradeTask.ps1           # Task creation
├── Files/                              # Deployment files (empty - for Win11 setup)
├── Documentation/                      # Project docs
├── Deploy-Application-Complete.ps1    # PRODUCTION script
├── Deploy-Application-Test-Fixed.ps1  # TEST script (bypasses checks)
├── README.md                          # Project overview
└── DEPLOYMENT-GUIDE.md               # This file
```

## 🚀 Quick Start

### Testing (Recommended First)
```powershell
cd "Win11Scheduler-PSADT-v3"
PowerShell.exe -ExecutionPolicy Bypass -File "Deploy-Application-Test-Fixed.ps1" -DeployMode Interactive
```

### Production Deployment
```powershell
cd "Win11Scheduler-PSADT-v3"
PowerShell.exe -ExecutionPolicy Bypass -File "Deploy-Application-Complete.ps1" -DeployMode Interactive
```

## ✅ Pre-Deployment Checklist

- [ ] Run as Administrator
- [ ] PSADT files present in `AppDeployToolkit/` folder
- [ ] All 3 support files present in `SupportFiles/` folder
- [ ] Test script works before using production version
- [ ] Verify task creation in Task Scheduler after test

## 🎯 Expected Workflow

1. **PSADT Welcome Dialog** - Application detection and deferral options
2. **Upgrade Information Dialog** - Professional pre-upgrade information
3. **Calendar Picker** - Modern WPF date/time selection
4. **Task Creation** - Real Windows scheduled task creation
5. **Confirmation** - Success message with task details

## 📍 Task Location

Created tasks appear in:
**Task Scheduler Library > Microsoft > Windows > Win11Upgrade**

## 🔧 Customization

### Organization Branding
Edit `Deploy-Application-Complete.ps1`:
```powershell
[String]$organizationName = 'Your Company Name'
[Int]$deadlineDays = 30  # Adjust deadline
```

### Application Detection
Edit the `CloseApps` parameter:
```powershell
$welcomeResult = Show-InstallationWelcome -CloseApps 'iexplore,firefox,chrome,msedge,outlook,excel,winword,powerpnt'
```

## 🧪 Testing Notes

- Test script bypasses Windows 11 compatibility checks
- Creates tasks with prefix `Win11Upgrade_Clean_`
- Safe to run multiple times for testing
- Each run creates a unique timestamped task

## 📦 Enterprise Deployment

This project is designed for:
- **SCCM** - Use as Application or Package
- **Intune** - Deploy as Win32 app
- **GPO** - Use with startup/logon scripts
- **Manual** - IT technician deployment

## 🔒 Security

- Runs with SYSTEM privileges for task creation
- No hard-coded credentials
- Validates all user inputs
- Comprehensive error handling and logging

## 📞 Support

Tasks are logged to Windows Event Log and PSADT logs for troubleshooting.