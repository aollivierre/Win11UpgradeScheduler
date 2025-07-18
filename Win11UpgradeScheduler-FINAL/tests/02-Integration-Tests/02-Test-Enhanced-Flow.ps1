# Test Enhanced PSADT v3 Flow with Information Dialog and Calendar Picker
# This script demonstrates the complete enterprise-grade workflow

[CmdletBinding()]
Param (
    [Parameter(Mandatory=$false)]
    [ValidateSet('Install','Uninstall','Repair')]
    [String]$DeploymentType = 'Install',
    
    [Parameter(Mandatory=$false)]
    [ValidateSet('Interactive','Silent','NonInteractive')]
    [String]$DeployMode = 'Interactive',
    
    [Parameter(Mandatory=$false)]
    [String]$OrganizationName = "ABC Corporation",
    
    [Parameter(Mandatory=$false)]
    [Int]$DeadlineDays = 14
)

Try {
    # Set the script execution policy for this process
    Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
    
    # Variables: Application
    [String]$appVendor = 'Microsoft Corporation'
    [String]$appName = 'Windows 11 In-Place Upgrade'
    [String]$appVersion = '23H2'
    [String]$appArch = 'x64'
    [String]$appLang = 'EN'
    [String]$appRevision = '01'
    [String]$appScriptVersion = '1.0.0'
    [String]$appScriptDate = '2025-01-11'
    [String]$appScriptAuthor = 'Windows 11 Upgrade Scheduler'
    
    # Variables: Install Titles
    [String]$installName = ''
    [String]$installTitle = 'Windows 11 In-Place Upgrade Scheduler'
    
    # Variables: Script
    [String]$deployAppScriptFriendlyName = 'Windows 11 Upgrade Scheduler'
    [Version]$deployAppScriptVersion = [Version]'3.10.2'
    [String]$deployAppScriptParameters = $PsBoundParameters | Out-String
    
    # Variables: Environment
    If (Test-Path -LiteralPath 'variable:HostInvocation') { $InvocationInfo = $HostInvocation } Else { $InvocationInfo = $MyInvocation }
    [String]$scriptDirectory = Split-Path -Path $InvocationInfo.MyCommand.Definition -Parent
    
    # Dot source the required App Deploy Toolkit Functions
    Try {
        [String]$moduleAppDeployToolkitMain = "$scriptDirectory\AppDeployToolkit\AppDeployToolkitMain.ps1"
        If (-not (Test-Path -LiteralPath $moduleAppDeployToolkitMain -PathType 'Leaf')) { 
            Throw "Module does not exist at the specified location [$moduleAppDeployToolkitMain]." 
        }
        If ($DisableLogging) { 
            . $moduleAppDeployToolkitMain -DisableLogging 
        } Else { 
            . $moduleAppDeployToolkitMain 
        }
    }
    Catch {
        If ($mainExitCode -eq 0) { 
            [Int32]$mainExitCode = 60008 
        }
        Write-Error -Message "Module [$moduleAppDeployToolkitMain] failed to load: `n$($_.Exception.Message)`n `n$($_.InvocationInfo.PositionMessage)" -ErrorAction 'Continue'
        Exit $mainExitCode
    }
    
    # Load the enhanced dialog functions
    Try {
        [String]$informationDialogPath = "$scriptDirectory\src\SupportFiles\Show-UpgradeInformationDialog.ps1"
        [String]$calendarPickerPath = "$scriptDirectory\src\SupportFiles\Show-CalendarPicker.ps1"
        
        If (Test-Path -LiteralPath $informationDialogPath -PathType 'Leaf') {
            . $informationDialogPath
            Write-Log -Message "Successfully loaded upgrade information dialog function" -Source $deployAppScriptFriendlyName
        } Else {
            Write-Log -Message "Information dialog function not found at [$informationDialogPath]" -Severity 2 -Source $deployAppScriptFriendlyName
        }
        
        If (Test-Path -LiteralPath $calendarPickerPath -PathType 'Leaf') {
            . $calendarPickerPath
            Write-Log -Message "Successfully loaded calendar picker function" -Source $deployAppScriptFriendlyName
        } Else {
            Write-Log -Message "Calendar picker function not found at [$calendarPickerPath]" -Severity 2 -Source $deployAppScriptFriendlyName
        }
    }
    Catch {
        Write-Log -Message "Failed to load dialog functions: $($_.Exception.Message)" -Severity 3 -Source $deployAppScriptFriendlyName
    }
    
    ##*===============================================
    ##* PRE-INSTALLATION
    ##*===============================================
    [String]$installPhase = 'Pre-Installation'
    
    # Show Welcome Message with application detection and deferral options
    Write-Log -Message "Starting Enhanced Windows 11 Upgrade Scheduler - PSADT v3.10.2 Flow" -Source $deployAppScriptFriendlyName
    
    # PSADT v3 Welcome Dialog with application detection
    Show-InstallationWelcome -CloseApps 'chrome,firefox,outlook,teams' -DeferTimes 3 -DeferDeadline 7 -CheckDiskSpace -PersistPrompt
    
    # Show Installation Progress
    Show-InstallationProgress -StatusMessage "Loading Windows 11 upgrade information..."
    Start-Sleep -Seconds 2
    
    ##*===============================================
    ##* INSTALLATION
    ##*===============================================
    [String]$installPhase = 'Installation'
    
    If ($deploymentType -ieq 'Install') {
        Write-Log -Message "Starting installation phase" -Source $deployAppScriptFriendlyName
        
        # Close progress dialog before showing information dialog
        Close-InstallationProgress
        
        # Show comprehensive information dialog
        Write-Log -Message "Displaying upgrade information and requirements" -Source $deployAppScriptFriendlyName
        
        if (Get-Command -Name 'Show-UpgradeInformationDialog' -ErrorAction SilentlyContinue) {
            $userChoice = Show-UpgradeInformationDialog -OrganizationName $OrganizationName -DeadlineDays $DeadlineDays
            
            switch ($userChoice) {
                'UpgradeNow' {
                    Write-Log -Message "User chose to upgrade immediately" -Source $deployAppScriptFriendlyName
                    Show-InstallationPrompt -Message "The Windows 11 upgrade will begin immediately.`n`nYour device will restart multiple times during the process.`n`nPlease save all work now." -ButtonRightText 'OK' -Icon 'Information'
                    
                    # Simulate immediate upgrade
                    Show-InstallationProgress -StatusMessage "Starting Windows 11 upgrade immediately..."
                    Start-Sleep -Seconds 3
                    Write-Log -Message "Immediate upgrade initiated" -Source $deployAppScriptFriendlyName
                    Exit-Script -ExitCode 0
                }
                
                'Schedule' {
                    Write-Log -Message "User chose to schedule the upgrade" -Source $deployAppScriptFriendlyName
                    
                    # Show progress for scheduling preparation
                    Show-InstallationProgress -StatusMessage "Preparing upgrade scheduling options..."
                    Start-Sleep -Seconds 2
                    Close-InstallationProgress
                    
                    # Show enhanced calendar picker
                    if (Get-Command -Name 'Show-CalendarPicker' -ErrorAction SilentlyContinue) {
                        $selectedDate = Show-CalendarPicker -MinDate (Get-Date).AddDays(1) -MaxDate (Get-Date).AddDays($DeadlineDays)
                        
                        if ($selectedDate) {
                            Write-Log -Message "User scheduled upgrade for: $($selectedDate.ToString('yyyy-MM-dd HH:mm:ss'))" -Source $deployAppScriptFriendlyName
                            
                            # Success message with comprehensive details
                            $successMessage = "✅ Windows 11 upgrade successfully scheduled!"
                            $successMessage += "`n`n📅 Date: $($selectedDate.ToString('MMMM dd, yyyy'))"
                            $successMessage += "`n🕒 Time: $($selectedDate.ToString('h:mm tt'))"
                            $successMessage += "`n`n⏱️ Duration: Approximately 2 hours"
                            $successMessage += "`n🔄 Process: Multiple automatic restarts"
                            $successMessage += "`n`n⚠️ Important reminders:"
                            $successMessage += "`n• Save all work before the scheduled time"
                            $successMessage += "`n• Keep device connected to power"
                            $successMessage += "`n• Ensure stable internet connection"
                            $successMessage += "`n• The upgrade will run automatically"
                            
                            Show-InstallationPrompt -Message $successMessage -ButtonRightText 'OK' -Icon 'Information'
                            
                            # Simulate task creation
                            Show-InstallationProgress -StatusMessage "Creating scheduled task for Windows 11 upgrade..."
                            Start-Sleep -Seconds 3
                            
                            Write-Log -Message "Windows 11 upgrade task successfully created for $($selectedDate.ToString('yyyy-MM-dd HH:mm:ss'))" -Source $deployAppScriptFriendlyName
                            Exit-Script -ExitCode 0
                        } else {
                            Write-Log -Message "User cancelled upgrade scheduling" -Severity 2 -Source $deployAppScriptFriendlyName
                            Show-InstallationPrompt -Message "Windows 11 upgrade scheduling was cancelled.`n`nYou can run this tool again later to schedule the upgrade." -ButtonRightText 'OK' -Icon 'Information'
                            Exit-Script -ExitCode 0
                        }
                    } else {
                        Write-Log -Message "Calendar picker function not available" -Severity 3 -Source $deployAppScriptFriendlyName
                        Show-InstallationPrompt -Message "Error: Calendar picker function not available.`n`nPlease contact your IT administrator." -ButtonRightText 'OK' -Icon 'Error'
                        Exit-Script -ExitCode 69001
                    }
                }
                
                'RemindLater' {
                    Write-Log -Message "User chose to be reminded later" -Source $deployAppScriptFriendlyName
                    Show-InstallationPrompt -Message "You will be reminded about the Windows 11 upgrade later.`n`nRemember: The upgrade must be completed within $DeadlineDays days." -ButtonRightText 'OK' -Icon 'Information'
                    Exit-Script -ExitCode 0
                }
                
                default {
                    Write-Log -Message "User cancelled or closed information dialog" -Severity 2 -Source $deployAppScriptFriendlyName
                    Show-InstallationPrompt -Message "Windows 11 upgrade information was cancelled.`n`nThe upgrade is still required within $DeadlineDays days." -ButtonRightText 'OK' -Icon 'Information'
                    Exit-Script -ExitCode 0
                }
            }
        } else {
            Write-Log -Message "Information dialog function not available" -Severity 3 -Source $deployAppScriptFriendlyName
            Show-InstallationPrompt -Message "Error: Information dialog function not available.`n`nPlease contact your IT administrator." -ButtonRightText 'OK' -Icon 'Error'
            Exit-Script -ExitCode 69001
        }
    }
    
    ##*===============================================
    ##* POST-INSTALLATION
    ##*===============================================
    [String]$installPhase = 'Post-Installation'
    
    Write-Log -Message "Completed Enhanced Windows 11 Upgrade Scheduler" -Source $deployAppScriptFriendlyName
    
} Catch {
    [Int32]$mainExitCode = 60001
    [String]$mainErrorMessage = "$(Resolve-Error)"
    Write-Log -Message $mainErrorMessage -Severity 3 -Source $deployAppScriptFriendlyName
    Show-DialogBox -Text $mainErrorMessage -Icon 'Stop'
    Exit-Script -ExitCode $mainExitCode
}