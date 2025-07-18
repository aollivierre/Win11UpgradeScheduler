# Windows 11 Silent Installation Assistant Integration Plan

## Executive Summary
We've proven that Windows 11 Installation Assistant CAN run completely silently when:
1. Run as SYSTEM via scheduled task  
2. Use `/QuietInstall /SkipEULA` parameters
3. Hardware meets requirements (with registry bypasses for flexibility)

This plan integrates our proven approach into your existing PSADT framework.

## Key Changes Required

### 1. Update Pre-Flight Checks Module (02-PreFlightChecks.psm1)

#### A. Storage Thresholds
```powershell
# Update module variables
$script:MinDiskSpaceGB = 25      # FAIL threshold (was 64)
$script:WarnDiskSpaceGB = 50     # WARN threshold (new)
$script:OfficialDiskSpaceGB = 64 # Official requirement

# Update Test-DiskSpace function
function Test-DiskSpace {
    # ... existing code ...
    
    if ($freeSpaceGB -lt $script:MinDiskSpaceGB) {
        Write-PreFlightLog -Message "FAIL: Only ${freeSpaceGB}GB free. Minimum ${script:MinDiskSpaceGB}GB required." -Severity Error
        return @{
            Passed = $false
            Message = "Insufficient disk space. Need at least ${script:MinDiskSpaceGB}GB free, have ${freeSpaceGB}GB"
            FreeSpaceGB = $freeSpaceGB
            RequiredGB = $script:MinDiskSpaceGB
            Severity = 'Error'
        }
    }
    elseif ($freeSpaceGB -lt $script:WarnDiskSpaceGB) {
        Write-PreFlightLog -Message "WARNING: Only ${freeSpaceGB}GB free. Recommended ${script:WarnDiskSpaceGB}GB." -Severity Warning
        return @{
            Passed = $true  # Still pass but with warning
            Message = "Low disk space warning. Have ${freeSpaceGB}GB, recommended ${script:WarnDiskSpaceGB}GB"
            FreeSpaceGB = $freeSpaceGB
            RequiredGB = $script:WarnDiskSpaceGB
            Severity = 'Warning'
        }
    }
    
    # ... rest of function
}
```

#### B. Add TPM Check Function
```powershell
function Test-TPMStatus {
    <#
    .SYNOPSIS
        Checks TPM status and version
    .DESCRIPTION
        Ensures at least TPM 1.2 is present (not bypassing if NO TPM)
    #>
    [CmdletBinding()]
    param()
    
    Write-PreFlightLog -Message "Checking TPM status"
    
    try {
        $tpm = Get-CimInstance -Namespace "Root\CIMv2\Security\MicrosoftTpm" -ClassName Win32_Tpm -ErrorAction SilentlyContinue
        
        if ($null -eq $tpm) {
            Write-PreFlightLog -Message "No TPM detected" -Severity Error
            return @{
                Passed = $false
                Message = "No TPM detected. At least TPM 1.2 is required."
                TPMPresent = $false
                TPMVersion = "None"
            }
        }
        
        # Check if TPM is present and enabled
        if (-not $tpm.IsEnabled_InitialValue) {
            Write-PreFlightLog -Message "TPM is present but not enabled" -Severity Warning
            return @{
                Passed = $false
                Message = "TPM is present but not enabled in BIOS/UEFI"
                TPMPresent = $true
                TPMVersion = "Disabled"
            }
        }
        
        # Get TPM version
        $tpmVersion = $tpm.SpecVersion
        if ($tpmVersion) {
            $versionParts = $tpmVersion.Split(',')
            $majorVersion = [decimal]$versionParts[0]
            
            Write-PreFlightLog -Message "TPM version detected: $majorVersion"
            
            if ($majorVersion -lt 1.2) {
                return @{
                    Passed = $false
                    Message = "TPM version $majorVersion is too old. At least TPM 1.2 required."
                    TPMPresent = $true
                    TPMVersion = $majorVersion
                }
            }
            
            # TPM 1.2 or higher is acceptable
            return @{
                Passed = $true
                Message = "TPM $majorVersion detected and enabled"
                TPMPresent = $true
                TPMVersion = $majorVersion
            }
        }
        
        # If we can't determine version but TPM is present and enabled
        return @{
            Passed = $true
            Message = "TPM detected and enabled"
            TPMPresent = $true
            TPMVersion = "Unknown"
        }
    }
    catch {
        Write-PreFlightLog -Message "Error checking TPM status: $_" -Severity Error
        # Don't fail if we can't check - let Windows decide
        return @{
            Passed = $true
            Message = "Unable to check TPM status"
            TPMPresent = "Unknown"
            TPMVersion = "Unknown"
        }
    }
}
```

### 2. Update Deploy-Application.ps1

#### A. Replace Installation Method (Lines 426-525)
```powershell
#region Installation
Write-Log -Message "Starting Windows 11 upgrade process" -Source $deployAppScriptFriendlyName

# Update progress
Show-InstallationProgress -StatusMessage 'Preparing Windows 11 upgrade...'

# Use Installation Assistant with our proven silent method
$setupPath = Join-Path -Path $dirFiles -ChildPath 'Windows11InstallationAssistant.exe'

If (Test-Path -Path $setupPath) {
    Write-Log -Message "Using Windows 11 Installation Assistant with proven silent method" -Source $deployAppScriptFriendlyName
    
    # Set registry bypass keys for hardware requirements
    Write-Log -Message "Setting registry bypass keys for flexibility" -Source $deployAppScriptFriendlyName
    
    $labConfigPath = "HKLM:\SYSTEM\Setup\LabConfig"
    if (!(Test-Path $labConfigPath)) {
        New-Item -Path "HKLM:\SYSTEM\Setup" -Name "LabConfig" -Force | Out-Null
    }
    
    # Set bypass keys (but NOT for TPM since we check that separately)
    Set-ItemProperty -Path $labConfigPath -Name "BypassCPUCheck" -Value 1 -Type DWord -Force
    Set-ItemProperty -Path $labConfigPath -Name "BypassRAMCheck" -Value 1 -Type DWord -Force
    Set-ItemProperty -Path $labConfigPath -Name "BypassSecureBootCheck" -Value 1 -Type DWord -Force
    Set-ItemProperty -Path $labConfigPath -Name "BypassStorageCheck" -Value 1 -Type DWord -Force
    # Note: NOT setting BypassTPMCheck - we require at least TPM 1.2
    
    Write-Log -Message "Registry bypass keys configured (TPM check NOT bypassed)" -Source $deployAppScriptFriendlyName
    
    # Create scheduled task to run as SYSTEM for silent execution
    $taskName = "Win11SilentUpgrade_$($installName -replace ' ','')_$(Get-Date -Format 'yyyyMMddHHmmss')"
    
    # Build the scheduled task action
    $action = New-ScheduledTaskAction -Execute $setupPath -Argument "/QuietInstall /SkipEULA"
    $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit (New-TimeSpan -Hours 3)
    
    Write-Log -Message "Creating scheduled task: $taskName" -Source $deployAppScriptFriendlyName
    
    try {
        # Register the task
        $task = Register-ScheduledTask -TaskName $taskName -Action $action -Principal $principal -Settings $settings -Force
        
        # Start the task immediately
        Write-Log -Message "Starting Windows 11 upgrade via scheduled task (SYSTEM context)" -Source $deployAppScriptFriendlyName
        Start-ScheduledTask -TaskName $taskName
        
        # Wait a moment for the task to start
        Start-Sleep -Seconds 5
        
        # Monitor the task
        $timeout = (Get-Date).AddHours(2)
        $lastStatus = ""
        
        while ((Get-Date) -lt $timeout) {
            $taskInfo = Get-ScheduledTaskInfo -TaskName $taskName -ErrorAction SilentlyContinue
            
            if ($null -eq $taskInfo) {
                Write-Log -Message "Task info not available" -Severity 2 -Source $deployAppScriptFriendlyName
                break
            }
            
            $taskState = (Get-ScheduledTask -TaskName $taskName).State
            
            if ($taskState -ne $lastStatus) {
                Write-Log -Message "Task state: $taskState" -Source $deployAppScriptFriendlyName
                $lastStatus = $taskState
            }
            
            if ($taskState -eq 'Ready' -and $taskInfo.LastTaskResult -ne $null) {
                # Task completed
                $exitCode = $taskInfo.LastTaskResult
                Write-Log -Message "Installation Assistant task completed with exit code: $exitCode" -Source $deployAppScriptFriendlyName
                
                # Clean up task
                Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
                
                if ($exitCode -eq 0) {
                    Write-Log -Message "Windows 11 upgrade initiated successfully" -Source $deployAppScriptFriendlyName
                    $mainExitCode = 0
                } else {
                    Write-Log -Message "Windows 11 upgrade failed with exit code: $exitCode" -Severity 3 -Source $deployAppScriptFriendlyName
                    $mainExitCode = $exitCode
                }
                break
            }
            
            # Update progress message periodically
            Show-InstallationProgress -StatusMessage "Windows 11 upgrade in progress...`n`nThis process may take 30-90 minutes.`nYour computer will restart automatically."
            
            # Check every 30 seconds
            Start-Sleep -Seconds 30
        }
        
        if ((Get-Date) -ge $timeout) {
            Write-Log -Message "Installation Assistant task timed out" -Severity 2 -Source $deployAppScriptFriendlyName
            # Don't fail - the upgrade continues in background
            $mainExitCode = 0
        }
        
        # Log collection
        $logPath = "$env:TEMP\Win11Upgrade_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        if (!(Test-Path $logPath)) {
            New-Item -Path $logPath -ItemType Directory -Force | Out-Null
        }
        
        # Copy Installation Assistant logs if available
        $assistantLogs = @(
            "$env:LOCALAPPDATA\Microsoft\Windows11InstallationAssistant",
            "$env:ProgramData\Microsoft\Windows11InstallationAssistant"
        )
        
        foreach ($logDir in $assistantLogs) {
            if (Test-Path $logDir) {
                Copy-Item -Path "$logDir\*" -Destination $logPath -Recurse -Force -ErrorAction SilentlyContinue
                Write-Log -Message "Copied logs from: $logDir" -Source $deployAppScriptFriendlyName
            }
        }
        
    }
    catch {
        Write-Log -Message "Failed to create/start scheduled task: $_" -Severity 3 -Source $deployAppScriptFriendlyName
        $mainExitCode = 1603
    }
}
Else {
    Write-Log -Message "Windows 11 Installation Assistant not found at: $setupPath" -Severity 3 -Source $deployAppScriptFriendlyName
    $mainExitCode = 1603
}
#endregion
```

#### B. Update Information Messages
Add to the upgrade information dialog or prompts:
```powershell
$upgradeInfo = @"
Windows 11 Upgrade Information:

- The upgrade will download approximately 4GB of data
- Process takes 30-90 minutes
- Your computer will restart multiple times
- All files and applications will be preserved
- Upgrade runs completely in the background

Storage Requirements:
- Minimum: 25GB free space (hard requirement)
- Recommended: 50GB free space
- Current free space: $($preFlightResults.Checks.DiskSpace.FreeSpaceGB)GB

The upgrade will run silently without any prompts or user interaction required.
"@
```

### 3. Create Installation Assistant Log Monitor

Create a new support file: `SupportFiles\Get-InstallationAssistantStatus.ps1`
```powershell
function Get-InstallationAssistantStatus {
    <#
    .SYNOPSIS
        Gets the status of Windows 11 Installation Assistant
    .DESCRIPTION
        Checks if Installation Assistant is running and retrieves progress
    #>
    [CmdletBinding()]
    param()
    
    $status = @{
        IsRunning = $false
        ProcessId = $null
        UpgradeFolderExists = $false
        UpgradeFolderSizeGB = 0
        EstimatedProgress = 0
    }
    
    # Check for process
    $process = Get-Process -Name "Windows11InstallationAssistant" -ErrorAction SilentlyContinue
    if ($process) {
        $status.IsRunning = $true
        $status.ProcessId = $process.Id
    }
    
    # Check for upgrade folder
    $upgradeFolder = "C:\`$WINDOWS.~BT"
    if (Test-Path $upgradeFolder) {
        $status.UpgradeFolderExists = $true
        $files = Get-ChildItem $upgradeFolder -Recurse -Force -ErrorAction SilentlyContinue
        $sizeBytes = ($files | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
        $status.UpgradeFolderSizeGB = [math]::Round($sizeBytes / 1GB, 2)
        
        # Estimate progress based on folder size (typical upgrade is 3-5GB)
        $status.EstimatedProgress = [math]::Min(100, [math]::Round(($status.UpgradeFolderSizeGB / 4) * 100, 0))
    }
    
    return $status
}
```

### 4. Update Test-SystemReadiness to Include Warnings

In `Test-SystemReadiness` function, handle warnings:
```powershell
$results = @{
    IsReady = $true
    Issues = @()
    Warnings = @()  # Add warnings array
    Checks = @{}
}

# In disk check section:
if (-not $diskCheck.Passed -and $diskCheck.Severity -eq 'Error') {
    $results.IsReady = $false
    $results.Issues += $diskCheck.Message
}
elseif ($diskCheck.Severity -eq 'Warning') {
    $results.Warnings += $diskCheck.Message
}

# Add TPM check
Write-Verbose "Checking TPM status..."
$tpmCheck = Test-TPMStatus
$results.Checks['TPM'] = $tpmCheck
if (-not $tpmCheck.Passed) {
    $results.IsReady = $false
    $results.Issues += $tpmCheck.Message
}
```

## Benefits of This Approach

1. **Proven Silent Execution**: No EULA prompts, completely unattended
2. **Simpler Implementation**: No ISO mounting/unmounting complexity
3. **Smaller Download**: 4MB installer vs 3GB+ ISO
4. **Flexible Storage**: 25GB minimum with warnings at 50GB
5. **Smart TPM Handling**: Requires at least TPM 1.2 (not bypassing completely)
6. **Better Logging**: Installation Assistant logs are captured
7. **PSADT Integration**: Uses existing countdown and UI capabilities

## Testing Steps

1. Test pre-flight checks with various storage scenarios
2. Verify TPM detection works correctly  
3. Test scheduled task creation as SYSTEM
4. Verify silent execution without EULA
5. Test attended vs unattended flows
6. Verify logging and status monitoring

## Questions/Clarifications Needed

1. Should we add a progress monitoring window option during the upgrade?
2. Do you want to keep the ISO method as a fallback option?
3. Should we add network bandwidth checks since it downloads 4GB?
4. Do you want email/webhook notifications on completion?

This approach leverages our proven silent Installation Assistant method while maintaining all the robust features of your existing PSADT implementation!