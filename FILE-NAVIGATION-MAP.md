# File Navigation Map for Windows 11 Silent Upgrade Implementation

## Directory Structure Overview

```
C:\Code\Windows\Win11UpgradeScheduler-FINAL\src\     [PRODUCTION CODE]
│
├── Deploy-Application-InstallationAssistant-Version.ps1  [MAIN SCRIPT TO UPDATE]
├── AppDeployToolkit\                                     [PSADT Framework - DO NOT MODIFY]
│   └── AppDeployToolkitMain.ps1
│
├── Files\                                                [Deployment Files]
│   ├── Windows11InstallationAssistant.exe               [4MB Installer - REQUIRED]
│   └── ISO\setup.exe                                    [OLD METHOD - IGNORE]
│
└── SupportFiles\                                         [Support Components]
    ├── ScheduledTaskWrapper.ps1                         [Countdown wrapper - NO CHANGES NEEDED]
    │
    ├── Modules\                                          [PowerShell Modules]
    │   ├── 01-UpgradeScheduler.psm1                     [Scheduler module - NO CHANGES NEEDED]
    │   └── 02-PreFlightChecks.psm1                     [REPLACE THIS FILE]
    │
    └── UI\                                               [UI Components - NO CHANGES NEEDED]
        ├── 01-Show-EnhancedCalendarPicker.ps1
        └── 02-Show-UpgradeInformationDialog.ps1

C:\code\Windows\                                          [NEW IMPLEMENTATION FILES]
│
├── IMPLEMENTATION-HANDOFF.md                             [START HERE - Main guide]
├── FILE-NAVIGATION-MAP.md                                [THIS FILE - Directory guide]
├── Win11-Silent-InstallAssistant-FINAL-PLAN.md          [Detailed plan]
│
├── 02-PreFlightChecks-FINAL.psm1                        [NEW - Copy to production]
├── Deploy-Application-Installation-Section-Updated.ps1    [NEW - Installation code]
│
├── Archive-ISO-Method-Reference.ps1                      [Reference only - old ISO method]
├── Example-Warning-Handling.ps1                          [Reference - warning scenarios]
├── Testing-Silent-InstallationAssistant.ps1             [Testing script]
└── Win11-Silent-Upgrade-FAQ.md                           [FAQ for troubleshooting]
```

## Implementation File Map

### 1. Files to REPLACE

| Current Production File | Replace With | Purpose |
|------------------------|--------------|---------|
| `C:\Code\Windows\Win11UpgradeScheduler-FINAL\src\SupportFiles\Modules\02-PreFlightChecks.psm1` | `C:\code\Windows\02-PreFlightChecks-FINAL.psm1` | Remove TPM checks, add flexible storage |

### 2. Files to UPDATE

| File to Update | Reference Code Location | What to Change |
|----------------|------------------------|----------------|
| `C:\Code\Windows\Win11UpgradeScheduler-FINAL\src\Deploy-Application-InstallationAssistant-Version.ps1` | `C:\code\Windows\Deploy-Application-Installation-Section-Updated.ps1` | Replace lines 426-525 (Installation section) |

### 3. Files to VERIFY EXIST

| Required File | Location | Purpose |
|--------------|----------|---------|
| Windows11InstallationAssistant.exe | `C:\Code\Windows\Win11UpgradeScheduler-FINAL\src\Files\` | Main installer (4MB) |

### 4. Files to IGNORE (Old Method)

| File | Location | Why Ignore |
|------|----------|------------|
| setup.exe | `C:\Code\Windows\Win11UpgradeScheduler-FINAL\src\Files\ISO\` | Old ISO method |

### 5. Files for REFERENCE Only

| Reference File | Location | Purpose |
|----------------|----------|---------|
| Archive-ISO-Method-Reference.ps1 | `C:\code\Windows\` | Old ISO code archived |
| Example-Warning-Handling.ps1 | `C:\code\Windows\` | Shows warning scenarios |
| Testing-Silent-InstallationAssistant.ps1 | `C:\code\Windows\` | Test silent execution |

## Code Section Map

### In Deploy-Application.ps1

```powershell
# Line numbers and sections:

Lines 1-125:     # Header and initialization - NO CHANGES
Lines 126-425:   # Pre-Installation section - NO CHANGES
Lines 426-525:   # Installation section - REPLACE THIS ENTIRE SECTION
Lines 526-602:   # Post-Installation - NO CHANGES
```

### Key Variables to Use

```powershell
# These PSADT variables are already defined:
$dirFiles           # = Join-Path -Path $PSScriptRoot -ChildPath 'Files'
$dirSupportFiles    # = Join-Path -Path $PSScriptRoot -ChildPath 'SupportFiles'
$deployAppScriptFriendlyName  # For logging
$installName        # = 'Windows 11 Upgrade'
```

## Implementation Steps Guide

### Step 1: Start Here
```
Read: C:\code\Windows\IMPLEMENTATION-HANDOFF.md
```

### Step 2: Replace PreFlightChecks
```powershell
# Source file
$source = "C:\code\Windows\02-PreFlightChecks-FINAL.psm1"

# Destination
$dest = "C:\Code\Windows\Win11UpgradeScheduler-FINAL\src\SupportFiles\Modules\02-PreFlightChecks.psm1"

# Copy command
Copy-Item $source -Destination $dest -Force
```

### Step 3: Update Installation Section
```
1. Open: C:\Code\Windows\Win11UpgradeScheduler-FINAL\src\Deploy-Application-InstallationAssistant-Version.ps1
2. Find: Line 426 (start of Installation region)
3. Reference: C:\code\Windows\Deploy-Application-Installation-Section-Updated.ps1
4. Replace: Lines 426-525 with new code
```

### Step 4: Verify Installation Assistant
```powershell
# Check if exists
Test-Path "C:\Code\Windows\Win11UpgradeScheduler-FINAL\src\Files\Windows11InstallationAssistant.exe"
```

## Log File Locations

### During Development/Testing
```
C:\ProgramData\Win11UpgradeScheduler\Logs\
├── PreFlightChecks_YYYYMMDD.log
├── SchedulerModule_YYYYMMDD.log
└── TaskWrapper_YYYYMMDD.log
```

### PSADT Logs
```
C:\Windows\Logs\Software\
└── Windows_11_23H2_PSAppDeployToolkit_Install.log
```

## Quick Reference Commands

### Test Pre-Flight Checks
```powershell
Import-Module "C:\code\Windows\02-PreFlightChecks-FINAL.psm1" -Force
$results = Test-SystemReadiness -Verbose
$results | ConvertTo-Json -Depth 3
```

### Test Silent Execution
```powershell
& "C:\code\Windows\Testing-Silent-InstallationAssistant.ps1"
```

### Find Specific Code
```powershell
# Find installation section in production
Select-String -Path "C:\Code\Windows\Win11UpgradeScheduler-FINAL\src\Deploy-Application-InstallationAssistant-Version.ps1" -Pattern "#region Installation" -Context 5,5
```

## Important Notes

1. **DO NOT MODIFY** AppDeployToolkit folder - it's the core framework
2. **Installation Assistant** must be in Files folder (4MB file)
3. **ScheduledTaskWrapper.ps1** already handles countdown - no changes needed
4. **UI Scripts** in SupportFiles\UI\ work as-is - no changes needed
5. **Test on Windows 10** machine to see full upgrade process

## Troubleshooting Paths

If something doesn't work, check these in order:
1. PreFlightChecks log: `C:\ProgramData\Win11UpgradeScheduler\Logs\PreFlightChecks_YYYYMMDD.log`
2. PSADT main log: `C:\Windows\Logs\Software\Windows_11_23H2_PSAppDeployToolkit_Install.log`
3. Scheduled task: `Get-ScheduledTask | Where-Object {$_.TaskName -like "*Win11*"}`
4. Installation Assistant process: `Get-Process -Name "*Windows11*"`

This map provides complete navigation for implementing the Windows 11 silent upgrade!