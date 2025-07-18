<#
.SYNOPSIS
    ARCHIVED - Windows 11 ISO-based Installation Method
    
.DESCRIPTION
    This file contains the original ISO-based Windows 11 upgrade approach from the PSADT implementation.
    Archived for reference purposes only - NOT for production use.
    
    We moved away from this method because:
    1. Requires distributing 3GB+ ISO files
    2. Complex mounting/unmounting logic
    3. Installation Assistant method is simpler and proven to work silently
    4. ISO gets outdated quickly
    
.NOTES
    Archived Date: 2025-01-17
    Original Source: Deploy-Application.ps1 lines 426-525
    Reason: Replaced with silent Installation Assistant method
#>

#region ARCHIVED ISO Installation Method

# Path to Windows 11 setup.exe from ISO
$setupPath = Join-Path -Path $dirFiles -ChildPath 'ISO\setup.exe'

# Fallback to Installation Assistant if ISO not available
$useInstallationAssistant = $false
If (-not (Test-Path -Path $setupPath)) {
    Write-Log -Message "Windows 11 ISO setup.exe not found at: $setupPath" -Severity 2 -Source $deployAppScriptFriendlyName
    Write-Log -Message "Checking for Installation Assistant as fallback..." -Source $deployAppScriptFriendlyName
    
    $setupPath = Join-Path -Path $dirFiles -ChildPath 'Windows11InstallationAssistant.exe'
    If (Test-Path -Path $setupPath) {
        $useInstallationAssistant = $true
        Write-Log -Message "Using Installation Assistant (Note: EULA acceptance will be required)" -Severity 2 -Source $deployAppScriptFriendlyName
    }
}

If (Test-Path -Path $setupPath) {
    # Build setup arguments based on which installer we're using
    $setupArgs = @()
    
    If ($useInstallationAssistant) {
        # Installation Assistant parameters (limited effectiveness)
        Write-Log -Message "WARNING: Installation Assistant requires manual EULA acceptance" -Severity 2 -Source $deployAppScriptFriendlyName
        
        If ($DeployMode -eq 'Silent' -or $DeployMode -eq 'NonInteractive') {
            $setupArgs += '/QuietInstall'
            $setupArgs += '/SkipEULA'  # Doesn't work but included for completeness
            $setupArgs += '/Auto', 'Upgrade'
            $setupArgs += '/NoRestartUI'
        }
        Else {
            $setupArgs += '/SkipEULA'  # Doesn't work but included for completeness
            $setupArgs += '/Auto', 'Upgrade'
        }
    }
    Else {
        # Windows 11 ISO setup.exe parameters (FULL SILENT SUPPORT)
        Write-Log -Message "Using Windows 11 ISO setup.exe with silent EULA acceptance" -Source $deployAppScriptFriendlyName
        
        # Core parameters for silent upgrade
        $setupArgs += '/auto', 'upgrade'
        $setupArgs += '/eula', 'accept'  # This actually works with setup.exe!
        $setupArgs += '/compat', 'ignorewarning'
        
        If ($DeployMode -eq 'Silent' -or $DeployMode -eq 'NonInteractive') {
            $setupArgs += '/quiet'
            $setupArgs += '/noreboot'
        }
        Else {
            # Interactive mode - show progress but skip manual steps
            $setupArgs += '/showoobe', 'none'
            $setupArgs += '/telemetry', 'disable'
        }
        
        # Additional parameters for better control
        $setupArgs += '/migratedrivers', 'all'
        $setupArgs += '/dynamicupdate', 'enable'
        $setupArgs += '/resizerecoverypartition', 'enable'
        
        # Log collection
        $logPath = Join-Path -Path $env:TEMP -ChildPath "Win11Upgrade_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        $setupArgs += '/copylogs', $logPath
    }
    
    Write-Log -Message "Executing Windows 11 setup with arguments: $($setupArgs -join ' ')" -Source $deployAppScriptFriendlyName
    If (-not $useInstallationAssistant) {
        Write-Log -Message "Setup will run silently with automatic EULA acceptance" -Source $deployAppScriptFriendlyName
    }
    
    $exitCode = Execute-Process -Path $setupPath `
        -Parameters ($setupArgs -join ' ') `
        -WindowStyle 'Normal' `
        -IgnoreExitCodes '3010,1641' `
        -PassThru
    
    If ($exitCode.ExitCode -eq 0) {
        Write-Log -Message "Windows 11 upgrade completed successfully" -Source $deployAppScriptFriendlyName
    }
    ElseIf ($exitCode.ExitCode -eq 3010 -or $exitCode.ExitCode -eq 1641) {
        Write-Log -Message "Windows 11 upgrade completed successfully but requires restart" -Source $deployAppScriptFriendlyName
        $mainExitCode = 3010
    }
    Else {
        Write-Log -Message "Windows 11 upgrade failed with exit code: $($exitCode.ExitCode)" -Severity 3 -Source $deployAppScriptFriendlyName
        $mainExitCode = $exitCode.ExitCode
    }
}
Else {
    Write-Log -Message "Windows 11 Installation Assistant not found at: $setupPath" -Severity 3 -Source $deployAppScriptFriendlyName
    $mainExitCode = 1603
}

#endregion

#region ISO Method Notes and Parameters

<#
ISO SETUP.EXE PARAMETERS REFERENCE:

Core Parameters:
/auto upgrade              - Automatic upgrade mode
/eula accept              - Accept EULA (works with setup.exe, NOT Installation Assistant)
/quiet                    - Silent installation
/noreboot                 - Suppress automatic reboot
/compat ignorewarning     - Ignore compatibility warnings

Display Options:
/showoobe none            - Skip OOBE
/telemetry disable        - Disable telemetry collection

Migration Options:
/migratedrivers all       - Migrate all drivers
/dynamicupdate enable     - Enable dynamic updates during upgrade
/resizerecoverypartition enable - Resize recovery partition if needed

Logging:
/copylogs <path>          - Copy setup logs to specified path

Exit Codes:
0     - Success
3010  - Success, reboot required
1641  - Success, installer initiated reboot
Other - Various failure codes

WHY ISO METHOD IS COMPLEX:

1. Distribution Challenge:
   - Must distribute 3GB+ ISO file to all endpoints
   - Network bandwidth considerations
   - Storage space on endpoints
   - ISO gets outdated quickly

2. Mounting Complexity:
   - Some implementations mount ISO as drive
   - Must handle mount/unmount operations
   - Potential for stuck mounts

3. File Extraction:
   - Alternative to mounting is extracting ISO
   - Requires additional disk space
   - Cleanup considerations

4. Version Management:
   - ISO becomes outdated with new Windows 11 releases
   - Must track and update ISO files
   - Installation Assistant always downloads latest

COMPARISON WITH INSTALLATION ASSISTANT:

ISO Method:
- Full control over parameters
- EULA acceptance works with /eula accept
- Complex distribution
- 3GB+ initial download

Installation Assistant Method (Our Choice):
- 4MB initial download
- Always latest version
- Silent when run as SYSTEM
- Simpler distribution
- Proven to work with /QuietInstall /SkipEULA

#>

#endregion

#region Example ISO Mounting Approach (Not Used)

<#
# Some implementations mount the ISO first
$isoPath = Join-Path -Path $dirFiles -ChildPath 'Windows11.iso'
if (Test-Path $isoPath) {
    # Mount ISO
    $mountResult = Mount-DiskImage -ImagePath $isoPath -PassThru
    $driveLetter = ($mountResult | Get-Volume).DriveLetter
    
    # Run setup from mounted drive
    $setupPath = "${driveLetter}:\setup.exe"
    
    # ... run setup ...
    
    # Unmount ISO
    Dismount-DiskImage -ImagePath $isoPath
}

# This approach has several issues:
# - Requires administrative rights to mount
# - Can leave orphaned mounts if script fails
# - More complex error handling needed
# - Additional cleanup required
#>

#endregion