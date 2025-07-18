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
    [switch]$ScheduledMode = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$DeveloperMode = $false
)
#endregion

# Initialize main exit code
[int32]$script:mainExitCode = 0

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
    
    # Import custom countdown module
    Import-Module "$PSScriptRoot\PSADTCustomCountdown.psm1" -Force
    
    # Import custom modules
    if (Test-Path "$dirModules\00-OSCompatibilityCheck.psm1") {
        Import-Module "$dirModules\00-OSCompatibilityCheck.psm1" -Force
    }
    
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
    
    #region Helper Functions
    ##*===============================================
    ##* FUNCTION: Show-ScheduledPrompt
    ##*===============================================
    Function Show-ScheduledPrompt {
        <#
        .SYNOPSIS
            Shows installation prompt with proper handling for SYSTEM context
        .DESCRIPTION
            Wraps Show-InstallationPrompt to ensure it displays properly when running as SYSTEM in scheduled mode
        #>
        [CmdletBinding()]
        Param (
            [Parameter(Mandatory=$true)]
            [string]$Message,
            
            [Parameter(Mandatory=$false)]
            [string]$ButtonRightText = 'OK',
            
            [Parameter(Mandatory=$false)]
            [ValidateSet('Application','Asterisk','Error','Exclamation','Hand','Information','None','Question','Shield','Warning','WinLogo')]
            [string]$Icon = 'Information',
            
            [Parameter(Mandatory=$false)]
            [int32]$Timeout = 0
        )
        
        # Check if running as SYSTEM
        $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
        $isSystem = ($currentUser -eq 'NT AUTHORITY\SYSTEM')
        
        If ($isSystem -and $ScheduledMode) {
            Write-Log -Message "Running as SYSTEM in scheduled mode, using Execute-ProcessAsUser for UI display" -Source $deployAppScriptFriendlyName
            
            # Create a temporary script to show the prompt
            $tempScript = Join-Path -Path $env:TEMP -ChildPath "ScheduledPrompt_$(Get-Date -Format 'yyyyMMddHHmmss').ps1"
            
            $scriptContent = @"
# Load PSADT toolkit
`$scriptPath = '$PSScriptRoot'
. "`$scriptPath\AppDeployToolkit\AppDeployToolkitMain.ps1"

# Show the prompt
Show-InstallationPrompt -Message '$($Message -replace "'", "''")'` -ButtonRightText '$ButtonRightText' -Icon '$Icon' -Timeout $Timeout
"@
            
            $scriptContent | Set-Content -Path $tempScript -Force
            
            Try {
                # Execute the prompt in user context
                $result = Execute-ProcessAsUser -Path "$PSHOME\powershell.exe" `
                    -Parameters "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$tempScript`"" `
                    -Wait `
                    -PassThru
                
                Write-Log -Message "Execute-ProcessAsUser completed with exit code: $($result.ExitCode)" -Source $deployAppScriptFriendlyName
            }
            Catch {
                Write-Log -Message "Failed to show prompt via Execute-ProcessAsUser: $_" -Severity 2 -Source $deployAppScriptFriendlyName
                # Fall back to regular prompt
                Show-InstallationPrompt -Message $Message -ButtonRightText $ButtonRightText -Icon $Icon -Timeout $Timeout
            }
            Finally {
                Start-Sleep -Seconds 1
                Remove-Item -Path $tempScript -Force -ErrorAction SilentlyContinue
            }
        }
        Else {
            # Not running as SYSTEM or not in scheduled mode, use regular prompt
            Show-InstallationPrompt -Message $Message -ButtonRightText $ButtonRightText -Icon $Icon -Timeout $Timeout
        }
    }
    #endregion
    
    #region Pre-Installation
    If ($deploymentType -ieq 'Install') {
        Write-Log -Message "Starting $installTitle deployment" -Source $deployAppScriptFriendlyName
        
        # Perform early OS compatibility check
        Write-Log -Message "Performing OS compatibility check (Developer Mode: $DeveloperMode)" -Source $deployAppScriptFriendlyName
        
        # Create scriptblock reference to Show-InstallationPrompt
        $showPromptScriptBlock = {
            param($Message, $ButtonRightText, $ButtonLeftText, $Icon, [switch]$NoWait)
            Show-InstallationPrompt -Message $Message -ButtonRightText $ButtonRightText -ButtonLeftText $ButtonLeftText -Icon $Icon -NoWait:$NoWait
        }
        
        $osCheckResult = Invoke-EarlyOSCheck -DeveloperMode:$DeveloperMode -ShowInstallationPrompt $showPromptScriptBlock
        
        if (-not $osCheckResult) {
            Write-Log -Message "OS compatibility check failed - exiting deployment" -Source $deployAppScriptFriendlyName -Severity 2
            # Disable balloon notifications for OS check failures
            $configShowBalloonNotifications = $false
            $script:OSCheckFailed = $true
            Exit-Script -ExitCode 1618  # Another installation is already in progress
        }
        
        Write-Log -Message "OS compatibility check passed - continuing deployment" -Source $deployAppScriptFriendlyName
        
        # Initialize scheduling complete flag
        $script:SchedulingComplete = $false
        
        # Initialize OS check exit flag
        $script:OSCheckFailed = $false
        
        # Control PSADT balloon notifications
        $configShowBalloonNotifications = $true
        
        # Show welcome prompt (unless silent)
        If ($DeployMode -ne 'Silent') {
            # Check if running from scheduled task
            If ($ScheduledMode) {
                Write-Log -Message "Running in scheduled mode - upgrade will begin after countdown" -Source $deployAppScriptFriendlyName
                
                # Run pre-flight checks in scheduled mode
                Write-Log -Message "Running pre-flight checks for scheduled upgrade" -Source $deployAppScriptFriendlyName
                Show-InstallationProgress -StatusMessage "Checking system readiness..."
                
                $preFlightResults = Test-SystemReadiness
                
                If (-not $preFlightResults.IsReady) {
                    Close-InstallationProgress
                    
                    $issueMessage = "System is not ready for Windows 11 upgrade:`n`n"
                    ForEach ($issue in $preFlightResults.Issues) {
                        $issueMessage += "- $issue`n"
                    }
                    $issueMessage += "`nThe scheduled upgrade has been cancelled. Please resolve these issues and reschedule."
                    
                    Show-ScheduledPrompt -Message $issueMessage `
                        -ButtonRightText 'OK' `
                        -Icon Error `
                        -Timeout 300
                    
                    Write-Log -Message "Pre-flight checks failed in scheduled mode: $($preFlightResults.Issues -join '; ')" -Severity 2 -Source $deployAppScriptFriendlyName
                    
                    # Clean up the scheduled task since upgrade can't proceed
                    Try {
                        Remove-UpgradeSchedule -Force
                        Write-Log -Message "Removed scheduled task due to failed pre-flight checks" -Source $deployAppScriptFriendlyName
                    }
                    Catch {
                        Write-Log -Message "Failed to remove scheduled task: $_" -Severity 2 -Source $deployAppScriptFriendlyName
                    }
                    
                    # Disable balloon notifications for preflight check failures
                    $configShowBalloonNotifications = $false
                    $script:PreflightCheckFailed = $true
                    
                    Exit-Script -ExitCode 1618
                }
                
                Close-InstallationProgress
                
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
                            # Set flag to skip upgrade and exit gracefully
                            $script:SchedulingComplete = $true
                            $configShowBalloonNotifications = $false
                            Exit-Script -ExitCode 3010
                        }
                        'Reschedule' {
                            Write-Log -Message "User chose to reschedule" -Source $deployAppScriptFriendlyName
                            Remove-UpgradeSchedule -Force
                        }
                        'Cancel Schedule' {
                            Write-Log -Message "User cancelled schedule" -Source $deployAppScriptFriendlyName
                            Remove-UpgradeSchedule -Force
                            # Set flag to skip upgrade and exit gracefully
                            $script:SchedulingComplete = $true
                            $configShowBalloonNotifications = $false
                            Exit-Script -ExitCode 3010
                        }
                    }
                }
                
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
                            
                            # Log what we got from the calendar picker
                            Write-Log -Message "Calendar picker returned: $scheduleDate (Type: $($scheduleDate.GetType().Name))" -Source $deployAppScriptFriendlyName
                            
                            # Parse the schedule selection
                            Write-Log -Message "Parsing schedule selection: '$scheduleDate'" -Source $deployAppScriptFriendlyName
                            If ($scheduleDate -match '^(Tonight|Tomorrow) - (.+)$') {
                                Write-Log -Message "Matched Tonight/Tomorrow pattern" -Source $deployAppScriptFriendlyName
                                $when = $Matches[1]
                                $time = $Matches[2]
                                
                                # Strip parenthetical time if present (e.g., "Morning (8 AM)" -> "Morning")
                                $timeForScheduler = $time -replace '\s*\([^)]+\)\s*$', ''
                                Write-Log -Message "Time value: '$time', Cleaned for scheduler: '$timeForScheduler'" -Source $deployAppScriptFriendlyName
                                
                                Try {
                                    # Calculate the actual scheduled time
                                    $scheduledTime = Get-Date
                                    Switch ($when) {
                                        'Tonight' {
                                            # Same day evening
                                            Switch ($time) {
                                                '8 PM' { $scheduledTime = (Get-Date).Date.AddHours(20) }
                                                '10 PM' { $scheduledTime = (Get-Date).Date.AddHours(22) }
                                                '11 PM' { $scheduledTime = (Get-Date).Date.AddHours(23) }
                                            }
                                        }
                                        'Tomorrow' {
                                            # Next day
                                            $scheduledTime = (Get-Date).AddDays(1).Date
                                            Switch ($time) {
                                                'Morning (9 AM)' { $scheduledTime = $scheduledTime.AddHours(9) }
                                                'Afternoon (2 PM)' { $scheduledTime = $scheduledTime.AddHours(14) }
                                                'Evening (8 PM)' { $scheduledTime = $scheduledTime.AddHours(20) }
                                            }
                                        }
                                    }
                                    
                                    # Use the cleaned time value for scheduler (Morning/Afternoon/Evening without parentheses)
                                    New-QuickUpgradeSchedule -When $when -Time $timeForScheduler -PSADTPath $PSScriptRoot -DeployMode $DeployMode
                                    
                                    # Format the scheduled time nicely
                                    $formattedTime = $scheduledTime.ToString('dddd, MMMM d, yyyy') + ' at ' + $scheduledTime.ToString('h:mm tt')
                                    $confirmMessage = "Windows 11 upgrade has been scheduled for:`n`n$formattedTime`n`n"
                                    
                                    # Add warning if within 4 hours
                                    $hoursUntil = ($scheduledTime - (Get-Date)).TotalHours
                                    If ($hoursUntil -lt 4) {
                                        $confirmMessage += "WARNING: This is less than 4 hours from now!`n`n"
                                    }
                                    
                                    $confirmMessage += "Your computer will wake up if asleep and begin the upgrade automatically."
                                    
                                    Show-InstallationPrompt -Message $confirmMessage `
                                        -ButtonRightText 'OK' `
                                        -Icon Information
                                    
                                    Write-Log -Message "Successfully scheduled upgrade" -Source $deployAppScriptFriendlyName
                                    # Set flag to skip upgrade and exit gracefully
                                    $script:SchedulingComplete = $true
                                    # Disable balloon notifications since we're not installing
                                    $configShowBalloonNotifications = $false
                                    Exit-Script -ExitCode 3010
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
                                    
                                    # Format the scheduled time nicely
                                    $formattedTime = $scheduleDate.ToString('dddd, MMMM d, yyyy') + ' at ' + $scheduleDate.ToString('h:mm tt')
                                    $confirmMessage = "Windows 11 upgrade has been scheduled for:`n`n$formattedTime`n`n"
                                    
                                    # Add warning if within 4 hours
                                    $hoursUntil = ($scheduleDate - (Get-Date)).TotalHours
                                    If ($hoursUntil -lt 4) {
                                        $confirmMessage += "WARNING: This is less than 4 hours from now!`n`n"
                                    }
                                    
                                    $confirmMessage += "Your computer will wake up if asleep and begin the upgrade automatically."
                                    
                                    Show-InstallationPrompt -Message $confirmMessage `
                                        -ButtonRightText 'OK' `
                                        -Icon Information
                                    
                                    Write-Log -Message "Successfully scheduled upgrade for $scheduleDate" -Source $deployAppScriptFriendlyName
                                    # Set flag to skip upgrade and exit gracefully
                                    $script:SchedulingComplete = $true
                                    $configShowBalloonNotifications = $false
                                    Exit-Script -ExitCode 3010
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
                                    # Normalize time format for scheduler (remove space between number and AM/PM)
                                    $normalizedTime = $time -replace '\s+', ''
                                    New-QuickUpgradeSchedule -When $when -Time $normalizedTime -PSADTPath $PSScriptRoot -DeployMode $DeployMode
                                    
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
                                    # Set flag to skip upgrade and exit gracefully
                                    $script:SchedulingComplete = $true
                                    $configShowBalloonNotifications = $false
                                    Exit-Script -ExitCode 3010
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
                                    
                                    # Format the scheduled time nicely
                                    $formattedTime = $scheduleDate.ToString('dddd, MMMM d, yyyy') + ' at ' + $scheduleDate.ToString('h:mm tt')
                                    $confirmMessage = "Windows 11 upgrade has been scheduled for:`n`n$formattedTime`n`n"
                                    
                                    # Add warning if within 4 hours
                                    $hoursUntil = ($scheduleDate - (Get-Date)).TotalHours
                                    If ($hoursUntil -lt 4) {
                                        $confirmMessage += "WARNING: This is less than 4 hours from now!`n`n"
                                    }
                                    
                                    $confirmMessage += "Your computer will wake up if asleep and begin the upgrade automatically."
                                    
                                    Show-InstallationPrompt -Message $confirmMessage `
                                        -ButtonRightText 'OK' `
                                        -Icon Information
                                    
                                    Write-Log -Message "Successfully scheduled upgrade for $scheduleDate" -Source $deployAppScriptFriendlyName
                                    # Set flag to skip upgrade and exit gracefully
                                    $script:SchedulingComplete = $true
                                    $configShowBalloonNotifications = $false
                                    Exit-Script -ExitCode 3010
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
            
            # Check if scheduling was completed - if so, skip the upgrade
            If (-not $script:SchedulingComplete) {
                Write-Log -Message "No scheduling occurred or user chose immediate upgrade, proceeding with installation" -Source $deployAppScriptFriendlyName
            # Run pre-flight checks before immediate upgrade
            Write-Log -Message "Running pre-flight checks before upgrade" -Source $deployAppScriptFriendlyName
            Show-InstallationProgress -StatusMessage "Checking system readiness..."
            
            $preFlightResults = Test-SystemReadiness
            
            If (-not $preFlightResults.IsReady) {
                Close-InstallationProgress
                
                $issueMessage = "Your system is not ready for Windows 11 upgrade:`n`n"
                ForEach ($issue in $preFlightResults.Issues) {
                    $issueMessage += "- $issue`n"
                }
                
                # Also show warnings if any
                If ($preFlightResults.Warnings.Count -gt 0) {
                    $issueMessage += "`nWarnings:`n"
                    ForEach ($warning in $preFlightResults.Warnings) {
                        $issueMessage += "- $warning`n"
                    }
                }
                
                $issueMessage += "`nPlease resolve these issues and try again."
                
                Show-InstallationPrompt -Message $issueMessage `
                    -ButtonRightText 'OK' `
                    -Icon Error
                
                Write-Log -Message "Pre-flight checks failed: $($preFlightResults.Issues -join '; ')" -Severity 2 -Source $deployAppScriptFriendlyName
                
                # Disable balloon notifications for preflight check failures
                $configShowBalloonNotifications = $false
                $script:PreflightCheckFailed = $true
                
                Exit-Script -ExitCode 1618
            }
            
            # Check if there are only warnings
            If ($preFlightResults.Warnings.Count -gt 0) {
                Close-InstallationProgress
                
                $warningMessage = "System check completed with warnings:`n`n"
                ForEach ($warning in $preFlightResults.Warnings) {
                    $warningMessage += "- $warning`n"
                }
                $warningMessage += "`nDo you want to continue with the upgrade?"
                
                $continueResult = Show-InstallationPrompt -Message $warningMessage `
                    -ButtonLeftText 'Continue' `
                    -ButtonRightText 'Cancel' `
                    -Icon Warning
                
                If ($continueResult -eq 'Cancel') {
                    Write-Log -Message "User cancelled due to warnings" -Source $deployAppScriptFriendlyName
                    Exit-Script -ExitCode 1602
                }
                
                Write-Log -Message "User chose to continue despite warnings" -Source $deployAppScriptFriendlyName
            }
            Else {
                Close-InstallationProgress
            }
            
            # Skip installation welcome since user already chose "Upgrade Now"
            # Just check for and close conflicting applications
            Write-Log -Message "User chose 'Upgrade Now' - skipping defer prompt" -Source $deployAppScriptFriendlyName
            
            # Check for running applications that need to be closed
            $processNames = @('winword','excel','powerpnt','onenote','outlook','teams')
            $runningApps = @()
            ForEach ($process in $processNames) {
                If (Get-Process -Name $process -ErrorAction SilentlyContinue) {
                    $runningApps += $process
                }
            }
            
            If ($runningApps) {
                # Show a simple prompt to close applications
                Show-InstallationPrompt -Message "Please save your work and close the following applications to continue:`n`n$($runningApps -join ', ')`n`nThe upgrade will begin once these applications are closed." `
                    -ButtonRightText 'Close Apps & Continue' `
                    -Icon Information
                
                # Close the applications
                Show-InstallationWelcome -CloseApps 'winword,excel,powerpnt,onenote,outlook,teams' `
                    -Silent `
                    -CloseAppsCountdown 60
            }
        }
        
        # Display Pre-Installation progress
        Show-InstallationProgress -StatusMessage 'Preparing Windows 11 upgrade...'
        
        #endregion
        
        #region Helper Functions
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
        
            #region Installation
            # Safety check - should never reach here if scheduling was completed
            If ($script:SchedulingComplete) {
                Write-Log -Message "ERROR: Installation region reached despite scheduling being complete!" -Severity 3 -Source $deployAppScriptFriendlyName
                Write-Log -Message "Skipping installation as scheduling was already done" -Source $deployAppScriptFriendlyName
                # Don't run any installation code
                # Set exit code to indicate no installation occurred
                $script:mainExitCode = 3010  # Soft reboot required (but actually just scheduled)
            }
            Else {
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
                            # Handle multiple processes if found
                            $processIds = if ($assistantProcess.Count -gt 1) {
                                $assistantProcess | ForEach-Object { $_.Id }
                            } else {
                                @($assistantProcess.Id)
                            }
                            
                            Write-Log -Message "Installation Assistant is running (PID: $($processIds -join ', '))" -Source $deployAppScriptFriendlyName
                            
                            # Log initial process information for first process only
                            $firstProcessId = $processIds[0]
                            $wmiProcess = Get-WmiObject Win32_Process -Filter "ProcessId = $firstProcessId"
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
"@ -ButtonRightText 'OK' -Icon Information
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
            } # End of Else block for safety check
            #endregion
        
        #region Post-Installation
        
        # Skip post-installation if we only scheduled
        If ($script:SchedulingComplete) {
            Write-Log -Message "Skipping post-installation actions - upgrade was scheduled, not installed" -Source $deployAppScriptFriendlyName
            # Set exit code to indicate deferred installation
            $script:mainExitCode = 3010
        }
        ElseIf ($mainExitCode -eq 0 -or $mainExitCode -eq 3010) {
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
        } # End of If (-not $script:SchedulingComplete)
        Else {
            # Scheduling was completed - skip upgrade and let PSADT handle graceful exit
            Write-Log -Message "User successfully scheduled upgrade, skipping immediate installation" -Source $deployAppScriptFriendlyName
            Write-Log -Message "Script will exit gracefully through PSADT framework" -Source $deployAppScriptFriendlyName
        }
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
    # Only call Exit-Script if we haven't already exited due to OS check or preflight check failure
    if (-not $script:OSCheckFailed -and -not $script:PreflightCheckFailed) {
        # Call the Exit-Script function to perform final cleanup operations
        Exit-Script -ExitCode $mainExitCode
    }
}
