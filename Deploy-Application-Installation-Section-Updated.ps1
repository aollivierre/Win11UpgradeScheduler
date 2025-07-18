#region Installation Section Update
# Replace lines 426-525 in Deploy-Application.ps1 with this updated installation section

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
    $bypassKeys = @{
        "BypassCPUCheck" = 1
        "BypassRAMCheck" = 1
        "BypassSecureBootCheck" = 1
        "BypassStorageCheck" = 1
        # Note: NOT setting BypassTPMCheck - we require at least TPM 1.2
    }
    
    foreach ($key in $bypassKeys.Keys) {
        Set-ItemProperty -Path $labConfigPath -Name $key -Value $bypassKeys[$key] -Type DWord -Force
        Write-Log -Message "Set registry bypass: $key = 1" -Source $deployAppScriptFriendlyName
    }
    
    Write-Log -Message "Registry bypass keys configured (TPM check NOT bypassed)" -Source $deployAppScriptFriendlyName
    
    # Create scheduled task to run as SYSTEM for silent execution
    $taskName = "Win11SilentUpgrade_$($installName -replace ' ','')_$(Get-Date -Format 'yyyyMMddHHmmss')"
    
    # Build the scheduled task action
    $action = New-ScheduledTaskAction -Execute $setupPath -Argument "/QuietInstall /SkipEULA"
    $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    $settings = New-ScheduledTaskSettingsSet `
        -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries `
        -ExecutionTimeLimit (New-TimeSpan -Hours 3) `
        -RestartCount 2 `
        -RestartInterval (New-TimeSpan -Minutes 10)
    
    Write-Log -Message "Creating scheduled task: $taskName" -Source $deployAppScriptFriendlyName
    
    try {
        # Register the task
        $task = Register-ScheduledTask -TaskName $taskName -Action $action -Principal $principal -Settings $settings -Force
        
        # Start the task immediately
        Write-Log -Message "Starting Windows 11 upgrade via scheduled task (SYSTEM context)" -Source $deployAppScriptFriendlyName
        Start-ScheduledTask -TaskName $taskName
        
        # Update progress message
        Show-InstallationProgress -StatusMessage @"
Windows 11 upgrade is now running silently in the background.

Important information:
- The upgrade will download approximately 4GB
- Process takes 30-90 minutes
- Your computer will restart automatically
- All files and applications will be preserved

You can continue using your computer normally.
"@
        
        # Wait a moment for the task to start
        Start-Sleep -Seconds 10
        
        # Check if Installation Assistant is actually running
        $assistantProcess = Get-Process -Name "Windows11InstallationAssistant" -ErrorAction SilentlyContinue
        
        if ($assistantProcess) {
            Write-Log -Message "Installation Assistant is running (PID: $($assistantProcess.Id))" -Source $deployAppScriptFriendlyName
            
            # Log initial process information
            $wmiProcess = Get-WmiObject Win32_Process -Filter "ProcessId = $($assistantProcess.Id)"
            if ($wmiProcess) {
                Write-Log -Message "Process command line: $($wmiProcess.CommandLine)" -Source $deployAppScriptFriendlyName
                $owner = $wmiProcess.GetOwner()
                Write-Log -Message "Process owner: $($owner.Domain)\$($owner.User)" -Source $deployAppScriptFriendlyName
            }
            
            # Create log directory for Installation Assistant logs
            $logPath = "$env:ProgramData\Win11UpgradeScheduler\Logs\InstallAssistant_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
            if (!(Test-Path $logPath)) {
                New-Item -Path $logPath -ItemType Directory -Force | Out-Null
            }
            
            # Monitor for a short time to ensure it's running properly
            $monitorEndTime = (Get-Date).AddMinutes(5)
            $upgradeStarted = $false
            
            while ((Get-Date) -lt $monitorEndTime -and -not $upgradeStarted) {
                # Check if process is still running
                $assistantProcess = Get-Process -Name "Windows11InstallationAssistant" -ErrorAction SilentlyContinue
                
                if (-not $assistantProcess) {
                    # Process ended - check scheduled task status
                    $taskInfo = Get-ScheduledTaskInfo -TaskName $taskName -ErrorAction SilentlyContinue
                    if ($taskInfo) {
                        $exitCode = $taskInfo.LastTaskResult
                        Write-Log -Message "Installation Assistant ended with exit code: $exitCode" -Severity $(if ($exitCode -eq 0) { 1 } else { 3 }) -Source $deployAppScriptFriendlyName
                        
                        if ($exitCode -ne 0) {
                            # Task failed - clean up
                            Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
                            $mainExitCode = $exitCode
                            break
                        }
                    }
                    break
                }
                
                # Check if Windows upgrade folder is being created
                if (Test-Path "C:\`$WINDOWS.~BT") {
                    Write-Log -Message "Windows upgrade folder detected - upgrade is progressing" -Source $deployAppScriptFriendlyName
                    $upgradeStarted = $true
                    $mainExitCode = 0
                    break
                }
                
                Start-Sleep -Seconds 30
            }
            
            if ($upgradeStarted -or $assistantProcess) {
                Write-Log -Message "Windows 11 upgrade initiated successfully and running in background" -Source $deployAppScriptFriendlyName
                $mainExitCode = 0
                
                # Provide information to user if not silent
                if ($DeployMode -ne 'Silent') {
                    Show-InstallationPrompt -Message @"
Windows 11 upgrade has started successfully!

The upgrade is running silently in the background.
Your computer will:
- Download Windows 11 files (approximately 4GB)
- Prepare the upgrade automatically
- Restart when ready (you'll see a notification)

You can continue working normally. The entire process takes 30-90 minutes.

To check progress, look for the Windows 11 Installation Assistant in Task Manager.
"@ -ButtonRightText 'OK' -Icon Information -Timeout 30
                }
            }
            else {
                Write-Log -Message "Installation Assistant may have encountered an issue" -Severity 2 -Source $deployAppScriptFriendlyName
            }
            
            # Copy Installation Assistant logs if available
            $assistantLogLocations = @(
                "$env:LOCALAPPDATA\Microsoft\Windows11InstallationAssistant",
                "$env:ProgramData\Microsoft\Windows11InstallationAssistant",
                "$env:TEMP\Windows11InstallationAssistant"
            )
            
            foreach ($logDir in $assistantLogLocations) {
                if (Test-Path $logDir) {
                    try {
                        Copy-Item -Path "$logDir\*" -Destination $logPath -Recurse -Force -ErrorAction SilentlyContinue
                        Write-Log -Message "Copied Installation Assistant logs from: $logDir" -Source $deployAppScriptFriendlyName
                    }
                    catch {
                        Write-Log -Message "Failed to copy logs from $logDir`: $_" -Severity 2 -Source $deployAppScriptFriendlyName
                    }
                }
            }
            
        }
        else {
            Write-Log -Message "Installation Assistant process not detected after starting task" -Severity 2 -Source $deployAppScriptFriendlyName
            
            # Check task status
            $taskInfo = Get-ScheduledTaskInfo -TaskName $taskName -ErrorAction SilentlyContinue
            if ($taskInfo -and $taskInfo.LastTaskResult -ne $null) {
                Write-Log -Message "Task exit code: $($taskInfo.LastTaskResult)" -Severity 2 -Source $deployAppScriptFriendlyName
                $mainExitCode = $taskInfo.LastTaskResult
            }
            else {
                # Assume it's starting slowly
                Write-Log -Message "Installation Assistant may be starting - continuing" -Source $deployAppScriptFriendlyName
                $mainExitCode = 0
            }
        }
        
        # Note: We don't clean up the scheduled task here because the upgrade continues in background
        # The task will be cleaned up after successful completion or by the wrapper script
        
    }
    catch {
        Write-Log -Message "Failed to create/start scheduled task: $_" -Severity 3 -Source $deployAppScriptFriendlyName
        
        # Try to clean up if task was partially created
        try {
            Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
        }
        catch {}
        
        $mainExitCode = 1603
    }
}
Else {
    Write-Log -Message "Windows 11 Installation Assistant not found at: $setupPath" -Severity 3 -Source $deployAppScriptFriendlyName
    
    # Check for ISO as fallback
    $isoSetupPath = Join-Path -Path $dirFiles -ChildPath 'ISO\setup.exe'
    if (Test-Path -Path $isoSetupPath) {
        Write-Log -Message "Found ISO setup.exe - consider using Installation Assistant for simpler deployment" -Severity 2 -Source $deployAppScriptFriendlyName
        Show-InstallationPrompt -Message "Windows 11 Installation Assistant not found. Please contact IT support." -ButtonRightText 'OK' -Icon Error
    }
    
    $mainExitCode = 1603
}
#endregion

#region Additional Helper Function
# Add this function before the Installation section

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
        RunningAsSystem = $false
    }
    
    # Check for process
    $process = Get-Process -Name "Windows11InstallationAssistant" -ErrorAction SilentlyContinue
    if ($process) {
        $status.IsRunning = $true
        $status.ProcessId = $process.Id
        
        # Check process owner
        try {
            $wmiProcess = Get-WmiObject Win32_Process -Filter "ProcessId = $($process.Id)"
            if ($wmiProcess) {
                $owner = $wmiProcess.GetOwner()
                $status.RunningAsSystem = ($owner.User -eq 'SYSTEM')
            }
        }
        catch {}
    }
    
    # Check for upgrade folder
    $upgradeFolder = "C:\`$WINDOWS.~BT"
    if (Test-Path $upgradeFolder) {
        $status.UpgradeFolderExists = $true
        try {
            $files = Get-ChildItem $upgradeFolder -Recurse -Force -ErrorAction SilentlyContinue
            $sizeBytes = ($files | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
            $status.UpgradeFolderSizeGB = [math]::Round($sizeBytes / 1GB, 2)
            
            # Estimate progress based on folder size (typical upgrade downloads 3-5GB)
            $status.EstimatedProgress = [math]::Min(100, [math]::Round(($status.UpgradeFolderSizeGB / 4) * 100, 0))
        }
        catch {
            Write-Log -Message "Error calculating upgrade folder size: $_" -Severity 2 -Source $deployAppScriptFriendlyName
        }
    }
    
    return $status
}
#endregion