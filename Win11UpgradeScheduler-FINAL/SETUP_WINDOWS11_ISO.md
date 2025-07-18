# Windows 11 ISO Setup Instructions

## Overview
Based on empirical testing, the Windows 11 Installation Assistant's `/SkipEULA` parameter is broken by design. For true silent deployment, we must use setup.exe from the Windows 11 ISO with the `/EULA accept` parameter.

## Step 1: Download Windows 11 ISO

### Option A: Direct Download (Recommended)
1. Visit: https://www.microsoft.com/software-download/windows11
2. Scroll down to "Download Windows 11 Disk Image (ISO) for x64 devices"
3. Select "Windows 11 (multi-edition ISO for x64 devices)"
4. Choose your language
5. Click "64-bit Download" (~5.8 GB)

### Option B: Media Creation Tool
1. Download the Media Creation Tool from the same page
2. Run it and select "Create installation media"
3. Choose "ISO file"
4. Save to a known location

## Step 2: Extract ISO Contents

### Manual Method:
1. Right-click the downloaded ISO file
2. Select "Mount" (Windows 10/11)
3. Copy all contents to: `C:\code\Windows\Win11UpgradeScheduler-FINAL\src\Files\ISO\`
4. Unmount the ISO when done

### PowerShell Method:
```powershell
# Mount the ISO
$isoPath = "C:\Downloads\Win11_23H2_English_x64.iso"
$mountResult = Mount-DiskImage -ImagePath $isoPath -PassThru
$driveLetter = ($mountResult | Get-Volume).DriveLetter

# Copy contents
$destination = "C:\code\Windows\Win11UpgradeScheduler-FINAL\src\Files\ISO"
New-Item -ItemType Directory -Path $destination -Force
Copy-Item -Path "$($driveLetter):\*" -Destination $destination -Recurse -Force

# Unmount ISO
Dismount-DiskImage -ImagePath $isoPath
```

## Step 3: Verify Files

Ensure these critical files exist in the ISO folder:
- `setup.exe` (main installer)
- `sources\` folder (contains installation files)
- `boot\` folder
- `efi\` folder
- `support\` folder

## Step 4: File Structure

Your directory should look like this:
```
C:\code\Windows\Win11UpgradeScheduler-FINAL\src\Files\
├── ISO\
│   ├── setup.exe           # This is what we'll use
│   ├── autorun.inf
│   ├── boot\
│   ├── efi\
│   ├── sources\
│   ├── support\
│   └── [other ISO contents]
├── Windows11InstallationAssistant.exe  # Keep for reference
└── [other files]
```

## Step 5: Test Setup.exe

Test the silent parameters before deployment:
```powershell
# Test command (add /WhatIf to simulate without installing)
.\ISO\setup.exe /auto upgrade /quiet /eula accept /compat ignorewarning /noreboot /copylogs C:\temp\logs
```

## Important Notes

1. **File Size**: The ISO folder will be approximately 5.8GB
2. **Network Deployment**: Consider copying ISO contents to a network share for multiple deployments
3. **Cleanup**: The Installation Assistant .exe can be removed after confirming setup.exe works
4. **Version**: Always use the latest Windows 11 ISO for best compatibility

## Command-Line Parameters for setup.exe

### Working Silent Install:
```
setup.exe /auto upgrade /quiet /eula accept /compat ignorewarning /noreboot
```

### Parameters Explained:
- `/auto upgrade` - Automatic upgrade keeping files and apps
- `/quiet` - No user interaction required
- `/eula accept` - **KEY PARAMETER** - Accepts EULA silently
- `/compat ignorewarning` - Bypasses compatibility warnings
- `/noreboot` - Prevents automatic restart
- `/copylogs <path>` - Copies logs to specified location

## Validation

After extracting, verify setup.exe accepts the EULA parameter:
```powershell
# This should NOT show EULA prompt
.\ISO\setup.exe /? | Select-String "eula"
```

## Next Steps

Once the ISO is extracted and verified:
1. Update Deploy-Application.ps1 to use setup.exe path
2. Test deployment in a VM
3. Remove Installation Assistant references
4. Update documentation