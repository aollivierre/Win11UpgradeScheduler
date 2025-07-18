# Windows 11 Upgrade Scheduler - Implementation Update

## Major Change: Switching from Installation Assistant to ISO-based Setup

### Date: January 16, 2025

Based on extensive research and empirical testing, we've discovered that the Windows 11 Installation Assistant's `/SkipEULA` parameter is **broken by design** and cannot bypass the EULA acceptance requirement. This makes it unsuitable for unattended/silent deployments.

## Changes Made

### 1. Archived Previous Version
- Original Installation Assistant version archived to: `archive\versions\Deploy-Application-v2.0-InstallationAssistant-[timestamp].ps1`
- Backup copy created as: `Deploy-Application-InstallationAssistant-Version.ps1`

### 2. Updated Deploy-Application.ps1
The script now:
- **Primary method**: Uses `setup.exe` from Windows 11 ISO (located in `Files\ISO\setup.exe`)
- **Fallback method**: Uses Installation Assistant if ISO not available (with EULA warning)
- **Smart detection**: Automatically detects which installer is available

### 3. Key Improvements

#### ISO Setup.exe (Preferred):
```powershell
# Silent upgrade with EULA acceptance
setup.exe /auto upgrade /eula accept /quiet /compat ignorewarning /noreboot
```
- ✅ **EULA automatically accepted** with `/eula accept`
- ✅ True silent installation possible
- ✅ No user interaction required
- ✅ Perfect for overnight/scheduled deployments

#### Installation Assistant (Fallback):
```powershell
# Best effort parameters (EULA still required)
Windows11InstallationAssistant.exe /QuietInstall /SkipEULA /Auto Upgrade
```
- ❌ EULA popup still appears
- ❌ Requires user to click "Accept and Install"
- ⚠️ Not suitable for unattended deployment

## Required Actions

### 1. Obtain Windows 11 ISO
1. Download from: https://www.microsoft.com/software-download/windows11
2. Choose "Windows 11 (multi-edition ISO for x64 devices)"
3. Download the ~5.8GB ISO file

### 2. Extract ISO Contents
```powershell
# Mount ISO
$iso = Mount-DiskImage -ImagePath "C:\Downloads\Win11_23H2.iso" -PassThru
$drive = ($iso | Get-Volume).DriveLetter

# Copy to deployment folder
Copy-Item -Path "$($drive):\*" -Destination "C:\code\Windows\Win11UpgradeScheduler-FINAL\src\Files\ISO\" -Recurse

# Unmount
Dismount-DiskImage -ImagePath "C:\Downloads\Win11_23H2.iso"
```

### 3. Verify Setup
Ensure these files exist:
- `src\Files\ISO\setup.exe`
- `src\Files\ISO\sources\`
- `src\Files\ISO\boot\`

## Benefits of This Approach

1. **True Silent Deployment**: No user interaction required
2. **EULA Acceptance**: Properly handled with `/eula accept`
3. **Scheduled Task Compatible**: Works perfectly for 2AM deployments
4. **Enterprise Ready**: Same method used by SCCM/MDT
5. **Fallback Option**: Still supports Installation Assistant if needed

## Testing

### Test Silent Deployment:
```powershell
cd C:\code\Windows\Win11UpgradeScheduler-FINAL\src
.\Deploy-Application.ps1 -DeployMode Silent
```

### Expected Behavior:
- With ISO: Completely silent, no popups
- With Assistant only: EULA popup appears once

## Log Locations
- PSADT Log: `C:\Windows\Logs\Software\Windows11_PSAppDeployToolkit_*.log`
- Setup Logs: Copied to temp folder with timestamp

## Important Notes

1. **File Size**: ISO folder will be ~5.8GB
2. **Deployment Package**: Total size increases significantly
3. **Network Considerations**: May want to use network share for ISO files
4. **Cleanup**: Can remove Installation Assistant after confirming ISO works

## Conclusion

This update transforms the deployment from a semi-interactive process (requiring EULA acceptance) to a fully automated solution suitable for enterprise deployment. The change is necessary due to Microsoft's intentional limitation in the Installation Assistant tool.