<#
.SYNOPSIS
    Enhanced Windows 11 In-Place Upgrade Scheduler with Complete Integration
.DESCRIPTION
    Full PSADT v3.10.2 implementation with enhanced scheduling features
#>

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
    [switch]$DisableLogging = $false
)

Try {
    # Set the script execution policy for this process
    Try { Set-ExecutionPolicy -ExecutionPolicy 'ByPass' -Scope 'Process' -Force -ErrorAction 'Stop' } 
    Catch { Write-Error "Failed to set execution policy: $($_.Exception.Message)" }

    #region Variable Declaration
    # Variables: Application
    [String]$appVendor = 'Microsoft'
    [String]$appName = 'Windows 11 Upgrade Scheduler (Enhanced)'
    [String]$appVersion = '23H2'
    [String]$appArch = ''
    [String]$appLang = 'EN'
    [String]$appRevision = '02'
    [String]$appScriptVersion = '2.0.0'
    [String]$appScriptDate = '01/15/2025'
    [String]$appScriptAuthor = 'IT Department'
    
    # Variables: Install Titles
    [String]$installName = 'Windows 11 Upgrade Scheduler'
    [String]$installTitle = 'Windows 11 Upgrade Scheduler v2.0.0 (Enhanced)'
    
    # Variables: Script Directories
    [String]$dirFiles = Join-Path -Path $PSScriptRoot -ChildPath 'Files'
    [String]$dirSupportFiles = Join-Path -Path $PSScriptRoot -ChildPath 'SupportFiles'
    [String]$dirModules = Join-Path -Path $dirSupportFiles -ChildPath 'Modules'
    
    # Variables: Organization
    [String]$organizationName = 'ABC Corporation'
    [Int]$deadlineDays = 14
    
    # Import the PSADT v3.10.2 module
    . "$PSScriptRoot\AppDeployToolkit\AppDeployToolkitMain.ps1"
    
    # Import enhanced modules
    if (Test-Path "$dirModules\UpgradeScheduler.psm1") {
        Write-Log -Message "Loading enhanced scheduler module" -Source $deployAppScriptFriendlyName
        Import-Module "$dirModules\UpgradeScheduler.psm1" -Force
    }
    
    if (Test-Path "$dirModules\PreFlightChecks.psm1") {
        Write-Log -Message "Loading pre-flight checks module" -Source $deployAppScriptFriendlyName
        Import-Module "$dirModules\PreFlightChecks.psm1" -Force
    }
    
    # Import UI functions
    if (Test-Path "$dirSupportFiles\Show-UpgradeInformationDialog.ps1") {
        . "$dirSupportFiles\Show-UpgradeInformationDialog.ps1"
    }
    
    # Use enhanced calendar picker if available
    if (Test-Path "$dirSupportFiles\Show-EnhancedCalendarPicker.ps1") {
        Write-Log -Message "Loading enhanced calendar picker" -Source $deployAppScriptFriendlyName
        . "$dirSupportFiles\Show-EnhancedCalendarPicker.ps1"
        # Override the original function
        function Show-CalendarPicker { Show-EnhancedCalendarPicker }
    } elseif (Test-Path "$dirSupportFiles\Show-CalendarPicker.ps1") {
        . "$dirSupportFiles\Show-CalendarPicker.ps1"
    }
    
    # Import task creation function
    if (Test-Path "$dirSupportFiles\New-Win11UpgradeTask.ps1") {
        . "$dirSupportFiles\New-Win11UpgradeTask.ps1"
    }
    #endregion
    
    #region Pre-Installation
    If ($deploymentType -ieq 'Install') {
        Write-Log -Message "Starting $installTitle deployment" -Source $deployAppScriptFriendlyName
        
        # Show welcome prompt
        If ($DeployMode -ne 'Silent') {
            # Run pre-flight checks first
            Write-Log -Message "Running enhanced pre-flight checks" -Source $deployAppScriptFriendlyName
            Show-InstallationProgress -StatusMessage 'Checking system readiness for Windows 11 upgrade...'
            
            if (Get-Command Test-SystemReadiness -ErrorAction SilentlyContinue) {
                $preFlightResults = Test-SystemReadiness -Verbose
                
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
                
                Write-Log -Message "Pre-flight checks passed" -Source $deployAppScriptFriendlyName
            }
            
            Close-InstallationProgress
            
            # Show installation welcome
            Show-InstallationWelcome -CloseApps 'iexplore,firefox,chrome,msedge,outlook,excel,winword,powerpnt' `
                -CheckDiskSpace `
                -PersistPrompt `
                -BlockExecution `
                -AllowDefer `
                -DeferTimes 5 `
                -DeferDays $deadlineDays `
                -CloseAppsCountdown 300
            
            # Show upgrade information dialog
            Write-Log -Message "Displaying upgrade information dialog" -Source $deployAppScriptFriendlyName
            $infoResult = Show-UpgradeInformationDialog -OrganizationName $organizationName -DeadlineDays $deadlineDays
            
            If ($infoResult -eq 'Cancel') {
                Write-Log -Message "User cancelled at information dialog" -Source $deployAppScriptFriendlyName
                Exit-Script -ExitCode 1602
            }
            ElseIf ($infoResult -eq 'Schedule') {
                Write-Log -Message "User chose to schedule upgrade" -Source $deployAppScriptFriendlyName
                
                # Show enhanced calendar picker
                $scheduleDate = Show-CalendarPicker
                
                If ($null -eq $scheduleDate) {
                    Write-Log -Message "User cancelled calendar picker" -Source $deployAppScriptFriendlyName
                    Show-InstallationPrompt -Message 'Windows 11 upgrade scheduling was cancelled.' `
                        -ButtonRightText 'OK' `
                        -Icon Information
                    Exit-Script -ExitCode 1602
                }
                
                Write-Log -Message "User selected schedule: $scheduleDate" -Source $deployAppScriptFriendlyName
                
                # Handle the schedule based on selection type
                If ($scheduleDate -is [string]) {
                    # Quick pick option (Tonight/Tomorrow)
                    If ($scheduleDate -match '^(Tonight|Tomorrow) - (.+)$') {
                        $when = $Matches[1]
                        $time = $Matches[2]
                        
                        Try {
                            # Use enhanced scheduler if available
                            if (Get-Command New-QuickUpgradeSchedule -ErrorAction SilentlyContinue) {
                                Write-Log -Message "Creating quick schedule: $when $time" -Source $deployAppScriptFriendlyName
                                New-QuickUpgradeSchedule -When $when -Time $time -PSADTPath $PSScriptRoot
                                
                                $confirmMsg = "Windows 11 upgrade has been scheduled for $when at $time.`n`n"
                                $confirmMsg += "Your computer will wake up if asleep and begin the upgrade automatically."
                                
                                Show-InstallationPrompt -Message $confirmMsg `
                                    -ButtonRightText 'OK' `
                                    -Icon Information
                            }
                            else {
                                # Fallback to original method
                                New-Win11UpgradeTask -ScheduledDate $scheduleDate -SetupPath "$dirFiles\setup.exe"
                            }
                            
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
                }
                ElseIf ($scheduleDate -is [datetime]) {
                    # Custom date/time selected
                    Try {
                        if (Get-Command New-UpgradeSchedule -ErrorAction SilentlyContinue) {
                            Write-Log -Message "Creating custom schedule for: $scheduleDate" -Source $deployAppScriptFriendlyName
                            New-UpgradeSchedule -ScheduleTime $scheduleDate -PSADTPath $PSScriptRoot
                        }
                        else {
                            New-Win11UpgradeTask -ScheduledDate $scheduleDate -SetupPath "$dirFiles\setup.exe"
                        }
                        
                        $confirmMsg = "Windows 11 upgrade has been scheduled for:`n$scheduleDate`n`n"
                        $confirmMsg += "Your computer will wake up if asleep and begin the upgrade automatically."
                        
                        Show-InstallationPrompt -Message $confirmMsg `
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
        
        # Display Pre-Installation progress
        Show-InstallationProgress -StatusMessage 'Preparing Windows 11 upgrade installation...'
        
        # Add any pre-installation tasks here
        Start-Sleep -Seconds 2
        
        #endregion
        
        #region Installation
        
        Write-Log -Message "Starting Windows 11 upgrade process" -Source $deployAppScriptFriendlyName
        
        # Update progress
        Show-InstallationProgress -StatusMessage 'Installing Windows 11 upgrade (this may take 1-2 hours)...'
        
        # For demo purposes, we'll simulate the installation
        Write-Log -Message "DEMO MODE: Simulating Windows 11 upgrade" -Source $deployAppScriptFriendlyName
        Start-Sleep -Seconds 5
        
        $mainExitCode = 0
        
        #endregion
        
        #region Post-Installation
        
        Write-Log -Message "Windows 11 upgrade simulation completed" -Source $deployAppScriptFriendlyName
        
        #endregion
    }
    ElseIf ($deploymentType -ieq 'Uninstall') {
        #region Pre-Uninstallation
        
        Write-Log -Message "Uninstall mode not supported for Windows 11 upgrade" -Source $deployAppScriptFriendlyName
        
        #endregion
    }
    
    #region Display Messages
    
    Close-InstallationProgress
    
    If ($DeployMode -ne 'Silent') {
        Show-InstallationPrompt -Message "$installTitle demo completed successfully." `
            -ButtonRightText 'OK' `
            -Icon Information
    }
    
    #endregion
}
Catch {
    Write-Log -Message "Error in installation script: $($_.Exception.Message)" -Severity 3 -Source $deployAppScriptFriendlyName
    Exit-Script -ExitCode 60001
}
Finally {
    Exit-Script -ExitCode $mainExitCode
}
