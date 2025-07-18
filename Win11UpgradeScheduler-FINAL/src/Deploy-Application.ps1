#region Script Header
<#
.SYNOPSIS
    Windows 11 In-Place Upgrade Scheduler with Enhanced Features
    
.DESCRIPTION
    Enhanced PSADT deployment script for Windows 11 upgrades featuring:
    - Improved pre-flight checks (disk, battery, updates, pending reboots)
    - Same-day scheduling support (tonight at 8PM, 10PM, 11PM)
    - 30-minute countdown for attended sessions
    - Scheduled task wrapper for proper session handling
    - Wake computer support for overnight upgrades
    - PowerShell 5.1 compatibility
    
.PARAMETER DeploymentType
    The type of deployment to perform. Default is "Install".
    
.PARAMETER DeployMode
    Specifies whether the installation should be run in Interactive, Silent, or NonInteractive mode.
    
.PARAMETER ScheduledMode
    Indicates if running from scheduled task (shows countdown)
    
.EXAMPLE
    Deploy-Application.ps1
    Deploy-Application.ps1 -DeployMode "Interactive"
    Deploy-Application.ps1 -ScheduledMode
    
.NOTES
    Enhanced PSADT v3.10.2 implementation with comprehensive scheduling
    PowerShell 5.1 compatible
    Tested on Windows 10 1507-22H2
#>
#endregion

#region Parameters
[CmdletBinding()]
Param (
    [Parameter(Mandatory=$false)]
    [ValidateSet('Install','Uninstall','Repair')]
    [String]$DeploymentType = 'Install',
    
    [Parameter(Mandatory=$false)]
    [ValidateSet('Interactive','Silent','NonInteractive')]
    [String]$DeployMode = 'Interactive',
    
    [Parameter(Mandatory=$false)]
    [switch]$AllowRebootPassThru = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$TerminalServerMode = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$DisableLogging = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$ScheduledMode = $false
)
#endregion

# Initialize main exit code
[int32]$mainExitCode = 0

Try {
    #region Initialize Environment
    # Set the script execution policy for this process
    Try { Set-ExecutionPolicy -ExecutionPolicy 'ByPass' -Scope 'Process' -Force -ErrorAction 'Stop' } 
    Catch { Write-Error "Failed to set execution policy: $($_.Exception.Message)" }

    # Variables: Application
    [String]$appVendor = 'Microsoft'
    [String]$appName = 'Windows 11'
    [String]$appVersion = '23H2'
    [String]$appArch = ''
    [String]$appLang = 'EN'
    [String]$appRevision = '01'
    [String]$appScriptVersion = '2.0.0'
    [String]$appScriptDate = '01/15/2025'
    [String]$appScriptAuthor = 'IT Department'
    
    # Variables: Install Titles
    [String]$installName = 'Windows 11 Upgrade'
    [String]$installTitle = 'Windows 11 Upgrade v2.0.0'
    
    # Variables: Script Directories
    [String]$dirFiles = Join-Path -Path $PSScriptRoot -ChildPath 'Files'
    [String]$dirSupportFiles = Join-Path -Path $PSScriptRoot -ChildPath 'SupportFiles'
    [String]$dirModules = Join-Path -Path $dirSupportFiles -ChildPath 'Modules'
    
    # Variables: Organization
    [String]$organizationName = 'Your Organization'
    [Int]$deadlineDays = 14
    
    # Import the PSADT v3.10.2 module
    . "$PSScriptRoot\AppDeployToolkit\AppDeployToolkitMain.ps1"
    
    # Import custom modules
    if (Test-Path "$dirModules\01-UpgradeScheduler.psm1") {
        Import-Module "$dirModules\01-UpgradeScheduler.psm1" -Force
    }
    
    if (Test-Path "$dirModules\02-PreFlightChecks.psm1") {
        Import-Module "$dirModules\02-PreFlightChecks.psm1" -Force
    }
    
    # Import UI scripts
    if (Test-Path "$dirSupportFiles\UI\02-Show-UpgradeInformationDialog.ps1") {
        . "$dirSupportFiles\UI\02-Show-UpgradeInformationDialog.ps1"
    }
    
    if (Test-Path "$dirSupportFiles\UI\01-Show-EnhancedCalendarPicker.ps1") {
        Write-Log -Message "Loading enhanced calendar picker from: $dirSupportFiles\UI\01-Show-EnhancedCalendarPicker.ps1" -Source $deployAppScriptFriendlyName
        . "$dirSupportFiles\UI\01-Show-EnhancedCalendarPicker.ps1"
        # Override the Show-CalendarPicker function with enhanced version
        function Show-CalendarPicker { 
            Write-Log -Message "Show-CalendarPicker wrapper called, invoking Show-EnhancedCalendarPicker" -Source $deployAppScriptFriendlyName
            Show-EnhancedCalendarPicker 
        }
        Write-Log -Message "Calendar picker override configured" -Source $deployAppScriptFriendlyName
    }
    #endregion
    
    #region Pre-Installation
    If ($deploymentType -ieq 'Install') {
        Write-Log -Message "Starting $installTitle deployment" -Source $deployAppScriptFriendlyName
        
        # Show welcome prompt (unless silent)
        If ($DeployMode -ne 'Silent') {
            # Check if running from scheduled task
            If ($ScheduledMode) {
                Write-Log -Message "Running in scheduled mode - upgrade will begin after countdown" -Source $deployAppScriptFriendlyName
                
                # The countdown is handled by the wrapper script
                # Just show a brief notification
                Show-InstallationPrompt -Message "Windows 11 upgrade is starting as scheduled.`n`nPlease save your work." `
                    -ButtonRightText 'OK' `
                    -Icon Information `
                    -Timeout 10
            }
            Else {
                # Interactive mode - check for existing schedule
                $existingSchedule = Get-UpgradeSchedule
                
                If ($existingSchedule) {
                    Write-Log -Message "Found existing schedule for $($existingSchedule.NextRunTime)" -Source $deployAppScriptFriendlyName
                    
                    $message = "Windows 11 upgrade is already scheduled for:`n`n$($existingSchedule.NextRunTime)`n`nWould you like to:"
                    $result = Show-InstallationPrompt -Message $message `
                        -ButtonLeftText 'Keep Schedule' `
                        -ButtonMiddleText 'Reschedule' `
                        -ButtonRightText 'Cancel Schedule' `
                        -Icon Information
                    
                    Switch ($result) {
                        'Keep Schedule' {
                            Write-Log -Message "User kept existing schedule" -Source $deployAppScriptFriendlyName
                            Exit-Script -ExitCode 0
                        }
                        'Reschedule' {
                            Write-Log -Message "User chose to reschedule" -Source $deployAppScriptFriendlyName
                            Remove-UpgradeSchedule -Force
                        }
                        'Cancel Schedule' {
                            Write-Log -Message "User cancelled schedule" -Source $deployAppScriptFriendlyName
                            Remove-UpgradeSchedule -Force
                            Exit-Script -ExitCode 0
                        }
                    }
                }
                
                # Run pre-flight checks
                Write-Log -Message "Running pre-flight checks" -Source $deployAppScriptFriendlyName
                Show-InstallationProgress -StatusMessage "Checking system readiness..."
                
                $preFlightResults = Test-SystemReadiness
                
                If (-not $preFlightResults.IsReady) {
                    Close-InstallationProgress
                    
                    $issueMessage = "Your system is not ready for Windows 11 upgrade:`n`n"
                    ForEach ($issue in $preFlightResults.Issues) {
                        $issueMessage += "- $issue`n"
                    }
                    $issueMessage += "`nPlease resolve these issues and try again."
                    
                    Show-InstallationPrompt -Message $issueMessage `
                        -ButtonRightText 'OK' `
                        -Icon Error
                    
                    Write-Log -Message "Pre-flight checks failed: $($preFlightResults.Issues -join '; ')" -Severity 2 -Source $deployAppScriptFriendlyName
                    Exit-Script -ExitCode 1618
                }
                
                Close-InstallationProgress
                
                # Show upgrade information dialog
                If (Get-Command Show-UpgradeInformationDialog -ErrorAction SilentlyContinue) {
                    $infoResult = Show-UpgradeInformationDialog -OrganizationName $organizationName -DeadlineDays $deadlineDays
                    
                    If ($infoResult -eq 'Cancel') {
                        Write-Log -Message "User cancelled at information dialog" -Source $deployAppScriptFriendlyName
                        Exit-Script -ExitCode 1602
                    }
                    ElseIf ($infoResult -eq 'Upgrade Now') {
                        Write-Log -Message "User chose to upgrade now from info dialog" -Source $deployAppScriptFriendlyName
                        # Continue with immediate installation below
                    }
                    ElseIf ($infoResult -eq 'Schedule') {
                        Write-Log -Message "User chose to schedule upgrade from info dialog" -Source $deployAppScriptFriendlyName
                        
                        # Go directly to calendar picker - no redundant prompt
                        If (Get-Command Show-CalendarPicker -ErrorAction SilentlyContinue) {
                            $scheduleDate = Show-CalendarPicker
                            
                            If ($null -eq $scheduleDate) {
                                Write-Log -Message "User cancelled calendar picker" -Source $deployAppScriptFriendlyName
                                Exit-Script -ExitCode 1602
                            }
                            
                            # Parse the schedule selection
                            If ($scheduleDate -match '^(Tonight|Tomorrow) - (.+)$') {
                                $when = $Matches[1]
                                $time = $Matches[2]
                                
                                Try {
                                    New-QuickUpgradeSchedule -When $when -Time $time -PSADTPath $PSScriptRoot -DeployMode $DeployMode
                                    
                                    $schedule = Get-UpgradeSchedule
                                    If ($schedule -and $schedule.NextRunTime) {
                                        $confirmMessage = "Windows 11 upgrade has been scheduled for:`n`n$($schedule.NextRunTime)`n`n"
                                        
                                        # Add warning if within 4 hours
                                        Try {
                                            $scheduleDateTime = if ($schedule.NextRunTime -is [datetime]) { 
                                                $schedule.NextRunTime 
                                            } else { 
                                                [datetime]::Parse($schedule.NextRunTime)
                                            }
                                            $hoursUntil = ($scheduleDateTime - (Get-Date)).TotalHours
                                            If ($hoursUntil -lt 4) {
                                                $confirmMessage += "WARNING: This is less than 4 hours from now!`n`n"
                                            }
                                        }
                                        Catch {
                                            Write-Log -Message "Could not calculate hours until schedule: $_" -Severity 2 -Source $deployAppScriptFriendlyName
                                        }
                                    }
                                    Else {
                                        # Fallback if we can't get schedule details
                                        $confirmMessage = "Windows 11 upgrade has been scheduled successfully.`n`n"
                                    }
                                    
                                    $confirmMessage += "Your computer will wake up if asleep and begin the upgrade automatically."
                                    
                                    Show-InstallationPrompt -Message $confirmMessage `
                                        -ButtonRightText 'OK' `
                                        -Icon Information
                                    
                                    Write-Log -Message "Successfully scheduled upgrade" -Source $deployAppScriptFriendlyName
                                    Exit-Script -ExitCode 0
                                }
                                Catch {
                                    Write-Log -Message "Failed to create schedule: $_" -Severity 3 -Source $deployAppScriptFriendlyName
                                    Show-InstallationPrompt -Message "Failed to schedule upgrade: $_" `
                                        -ButtonRightText 'OK' `
                                        -Icon Error
                                    Exit-Script -ExitCode 1603
                                }
                            }
                            ElseIf ($scheduleDate -is [datetime]) {
                                # Custom date/time selected
                                Try {
                                    New-UpgradeSchedule -ScheduleTime $scheduleDate -PSADTPath $PSScriptRoot `
                                        -DeploymentType $DeploymentType -DeployMode $DeployMode
                                    
                                    $confirmMessage = "Windows 11 upgrade has been scheduled for:`n`n$scheduleDate`n`n"
                                    $confirmMessage += "Your computer will wake up if asleep and begin the upgrade automatically."
                                    
                                    Show-InstallationPrompt -Message $confirmMessage `
                                        -ButtonRightText 'OK' `
                                        -Icon Information
                                    
                                    Write-Log -Message "Successfully scheduled upgrade for $scheduleDate" -Source $deployAppScriptFriendlyName
                                    Exit-Script -ExitCode 0
                                }
                                Catch {
                                    Write-Log -Message "Failed to create schedule: $_" -Severity 3 -Source $deployAppScriptFriendlyName
                                    Show-InstallationPrompt -Message "Failed to schedule upgrade: $_" `
                                        -ButtonRightText 'OK' `
                                        -Icon Error
                                    Exit-Script -ExitCode 1603
                                }
                            }
                        }
                        Else {
                            Write-Log -Message "Calendar picker function not found!" -Severity 3 -Source $deployAppScriptFriendlyName
                            Exit-Script -ExitCode 1603
                        }
                    }
                }
                Else {
                    # Fallback if info dialog not available - show old scheduling options
                $scheduleMessage = @"
When would you like to schedule the Windows 11 upgrade?

The upgrade will take 1-2 hours and your computer will restart several times.

Quick scheduling options:
- Tonight (8PM, 10PM, or 11PM)
- Tomorrow (Morning, Afternoon, or Evening)
- Custom date and time
- Upgrade now
"@
                
                $scheduleResult = Show-InstallationPrompt -Message $scheduleMessage `
                    -ButtonLeftText 'Schedule' `
                    -ButtonMiddleText 'Upgrade Now' `
                    -ButtonRightText 'Cancel' `
                    -Icon Information
                
                Switch ($scheduleResult) {
                    'Cancel' {
                        Write-Log -Message "User cancelled scheduling" -Source $deployAppScriptFriendlyName
                        Exit-Script -ExitCode 1602
                    }
                    
                    'Upgrade Now' {
                        Write-Log -Message "User chose to upgrade now" -Source $deployAppScriptFriendlyName
                        # Continue with immediate installation
                    }
                    
                    'Schedule' {
                        Write-Log -Message "User chose to schedule upgrade" -Source $deployAppScriptFriendlyName
                        
                        # Show calendar picker
                        If (Get-Command Show-CalendarPicker -ErrorAction SilentlyContinue) {
                            $scheduleDate = Show-CalendarPicker
                            
                            If ($null -eq $scheduleDate) {
                                Write-Log -Message "User cancelled calendar picker" -Source $deployAppScriptFriendlyName
                                Exit-Script -ExitCode 1602
                            }
                            
                            # Parse the schedule selection
                            $scheduleTime = $null
                            
                            If ($scheduleDate -match '^(Tonight|Tomorrow) - (.+)$') {
                                $when = $Matches[1]
                                $time = $Matches[2]
                                
                                Try {
                                    New-QuickUpgradeSchedule -When $when -Time $time -PSADTPath $PSScriptRoot -DeployMode $DeployMode
                                    
                                    $schedule = Get-UpgradeSchedule
                                    $confirmMessage = "Windows 11 upgrade has been scheduled for:`n`n$($schedule.NextRunTime)`n`n"
                                    
                                    # Add warning if within 4 hours
                                    $hoursUntil = (([datetime]$schedule.NextRunTime) - (Get-Date)).TotalHours
                                    If ($hoursUntil -lt 4) {
                                        $confirmMessage += "WARNING: This is less than 4 hours from now!`n`n"
                                    }
                                    
                                    $confirmMessage += "Your computer will wake up if asleep and begin the upgrade automatically."
                                    
                                    Show-InstallationPrompt -Message $confirmMessage `
                                        -ButtonRightText 'OK' `
                                        -Icon Information
                                    
                                    Write-Log -Message "Successfully scheduled upgrade for $($schedule.NextRunTime)" -Source $deployAppScriptFriendlyName
                                    Exit-Script -ExitCode 0
                                }
                                Catch {
                                    Write-Log -Message "Failed to create schedule: $_" -Severity 3 -Source $deployAppScriptFriendlyName
                                    Show-InstallationPrompt -Message "Failed to schedule upgrade: $_" `
                                        -ButtonRightText 'OK' `
                                        -Icon Error
                                    Exit-Script -ExitCode 1603
                                }
                            }
                            ElseIf ($scheduleDate -is [datetime]) {
                                # Custom date/time selected
                                Try {
                                    New-UpgradeSchedule -ScheduleTime $scheduleDate -PSADTPath $PSScriptRoot `
                                        -DeploymentType $DeploymentType -DeployMode $DeployMode
                                    
                                    $confirmMessage = "Windows 11 upgrade has been scheduled for:`n`n$scheduleDate`n`n"
                                    $confirmMessage += "Your computer will wake up if asleep and begin the upgrade automatically."
                                    
                                    Show-InstallationPrompt -Message $confirmMessage `
                                        -ButtonRightText 'OK' `
                                        -Icon Information
                                    
                                    Write-Log -Message "Successfully scheduled upgrade for $scheduleDate" -Source $deployAppScriptFriendlyName
                                    Exit-Script -ExitCode 0
                                }
                                Catch {
                                    Write-Log -Message "Failed to create schedule: $_" -Severity 3 -Source $deployAppScriptFriendlyName
                                    Show-InstallationPrompt -Message "Failed to schedule upgrade: $_" `
                                        -ButtonRightText 'OK' `
                                        -Icon Error
                                    Exit-Script -ExitCode 1603
                                }
                            }
                        }
                    }
                }
            }
            }
            
            # Show installation welcome for immediate upgrade
            Show-InstallationWelcome -CloseApps 'winword,excel,powerpnt,onenote,outlook,teams' `
                -CheckDiskSpace `
                -PersistPrompt `
                -BlockExecution `
                -AllowDefer `
                -DeferTimes 3 `
                -DeferDays 7 `
                -CloseAppsCountdown 600
        }
        
        # Display Pre-Installation progress
        Show-InstallationProgress -StatusMessage 'Preparing Windows 11 upgrade...'
        
        #endregion
        
        #region Installation
        
        Write-Log -Message "Starting Windows 11 upgrade process" -Source $deployAppScriptFriendlyName
        
        # Update progress
        Show-InstallationProgress -StatusMessage 'Starting Windows 11 upgrade process...'
        
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
            Write-Log -Message "Windows 11 setup files not found. Please either:" -Severity 3 -Source $deployAppScriptFriendlyName
            Write-Log -Message "  1. Extract Windows 11 ISO contents to: $dirFiles\ISO\" -Severity 3 -Source $deployAppScriptFriendlyName
            Write-Log -Message "  2. Place Windows11InstallationAssistant.exe in: $dirFiles" -Severity 3 -Source $deployAppScriptFriendlyName
            $mainExitCode = 1603
        }
        
        #endregion
        
        #region Post-Installation
        
        If ($mainExitCode -eq 0 -or $mainExitCode -eq 3010) {
            # Success - clean up any scheduled tasks
            Try {
                Remove-UpgradeSchedule -Force
                Write-Log -Message "Cleaned up scheduled task after successful upgrade" -Source $deployAppScriptFriendlyName
            }
            Catch {
                Write-Log -Message "Failed to clean up scheduled task: $_" -Severity 2 -Source $deployAppScriptFriendlyName
            }
            
            # Display restart prompt if not silent
            If ($DeployMode -ne 'Silent' -and $mainExitCode -eq 3010) {
                Show-InstallationRestartPrompt -CountdownNoHideSeconds 600 -Countdownseconds 1800
            }
        }
        
        #endregion
    }
    ElseIf ($deploymentType -ieq 'Uninstall') {
        #region Pre-Uninstallation
        
        Write-Log -Message "Windows 11 downgrade not supported through this tool" -Source $deployAppScriptFriendlyName
        
        If ($DeployMode -ne 'Silent') {
            Show-InstallationPrompt -Message "Windows 11 downgrade must be performed through Windows Settings > Recovery options." `
                -ButtonRightText 'OK' `
                -Icon Information
        }
        
        #endregion
    }
    ElseIf ($deploymentType -ieq 'Repair') {
        #region Pre-Repair
        
        Write-Log -Message "Windows 11 repair mode not implemented" -Source $deployAppScriptFriendlyName
        
        #endregion
    }
    
    #region Display Messages
    
    Close-InstallationProgress
    
    # Inform the user that the installation has completed
    If ($DeployMode -ne 'Silent' -and $mainExitCode -ne 3010) {
        If ($mainExitCode -eq 0) {
            Show-InstallationPrompt -Message "$installTitle has completed successfully." `
                -ButtonRightText 'OK' `
                -Icon Information
        }
        Else {
            Show-InstallationPrompt -Message "$installTitle has failed with error code: $mainExitCode" `
                -ButtonRightText 'OK' `
                -Icon Error
        }
    }
    
    #endregion
}
Catch {
    Write-Log -Message "Error in installation script: $($_.Exception.Message)" -Severity 3 -Source $deployAppScriptFriendlyName
    
    If ($DeployMode -ne 'Silent') {
        Show-InstallationPrompt -Message "An error occurred during the installation:`n`n$($_.Exception.Message)" `
            -ButtonRightText 'OK' `
            -Icon Error
    }
    
    Exit-Script -ExitCode 60001
}
Finally {
    # Call the Exit-Script function to perform final cleanup operations
    Exit-Script -ExitCode $mainExitCode
}