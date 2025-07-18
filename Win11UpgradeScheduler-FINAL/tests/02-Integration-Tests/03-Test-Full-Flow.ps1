# Test Full PSADT v3 Flow with Windows 11 Upgrade Scheduler
# This script demonstrates the complete PSADT v3.10.2 workflow with calendar integration

[CmdletBinding()]
Param (
    [Parameter(Mandatory=$false)]
    [ValidateSet('Install','Uninstall','Repair')]
    [String]$DeploymentType = 'Install',
    
    [Parameter(Mandatory=$false)]
    [ValidateSet('Interactive','Silent','NonInteractive')]
    [String]$DeployMode = 'Interactive'
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
    
    # Load the calendar picker function
    Try {
        [String]$calendarPickerPath = "$scriptDirectory\src\SupportFiles\Show-CalendarPicker.ps1"
        If (Test-Path -LiteralPath $calendarPickerPath -PathType 'Leaf') {
            . $calendarPickerPath
            Write-Log -Message "Successfully loaded calendar picker function" -Source $deployAppScriptFriendlyName
        } Else {
            Write-Log -Message "Calendar picker function not found at [$calendarPickerPath]" -Severity 2 -Source $deployAppScriptFriendlyName
        }
    }
    Catch {
        Write-Log -Message "Failed to load calendar picker function: $($_.Exception.Message)" -Severity 3 -Source $deployAppScriptFriendlyName
    }
    
    ##*===============================================
    ##* PRE-INSTALLATION
    ##*===============================================
    [String]$installPhase = 'Pre-Installation'
    
    # Show Welcome Message with application detection and deferral options
    Write-Log -Message "Starting Windows 11 Upgrade Scheduler - PSADT v3.10.2 Full Flow Test" -Source $deployAppScriptFriendlyName
    
    # PSADT v3 Welcome Dialog with application detection
    Show-InstallationWelcome -CloseApps 'chrome,firefox,outlook,teams' -DeferTimes 3 -DeferDeadline 7 -CheckDiskSpace -PersistPrompt
    
    # Show Installation Progress
    Show-InstallationProgress -StatusMessage "Initializing Windows 11 Upgrade Scheduler..."
    
    ##*===============================================
    ##* INSTALLATION
    ##*===============================================
    [String]$installPhase = 'Installation'
    
    If ($deploymentType -ieq 'Install') {
        Write-Log -Message "Starting installation phase" -Source $deployAppScriptFriendlyName
        
        # Update progress
        Show-InstallationProgress -StatusMessage "Preparing Windows 11 upgrade scheduling..."
        
        # Show calendar picker for scheduling
        Write-Log -Message "Launching calendar picker for upgrade scheduling" -Source $deployAppScriptFriendlyName
        
        # Test if calendar picker function is available
        if (Get-Command -Name 'Show-CalendarPicker' -ErrorAction SilentlyContinue) {
            $selectedDate = Show-CalendarPicker -MinDate (Get-Date).AddDays(1) -MaxDate (Get-Date).AddDays(30)
            
            if ($selectedDate) {
                Write-Log -Message "User selected upgrade date/time: $($selectedDate.ToString('yyyy-MM-dd HH:mm:ss'))" -Source $deployAppScriptFriendlyName
                
                # Success message
                $successMessage = "Windows 11 upgrade has been successfully scheduled!"
                $successMessage += "`n`nDate: $($selectedDate.ToString('MMMM dd, yyyy'))"
                $successMessage += "`nTime: $($selectedDate.ToString('h:mm tt'))"
                $successMessage += "`n`nPlease ensure your work is saved before the scheduled time."
                $successMessage += "`nThe upgrade will begin automatically at the scheduled time."
                
                Show-InstallationPrompt -Message $successMessage -ButtonRightText 'OK' -Icon 'Information'
                Write-Log -Message "Windows 11 upgrade successfully scheduled for $($selectedDate.ToString('yyyy-MM-dd HH:mm:ss'))" -Source $deployAppScriptFriendlyName
                
                # Simulate task creation
                Write-Log -Message "Creating scheduled task for Windows 11 upgrade" -Source $deployAppScriptFriendlyName
                Show-InstallationProgress -StatusMessage "Creating scheduled task..."
                Start-Sleep -Seconds 2
                
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
    
    ##*===============================================
    ##* POST-INSTALLATION
    ##*===============================================
    [String]$installPhase = 'Post-Installation'
    
    Write-Log -Message "Completed Windows 11 Upgrade Scheduler" -Source $deployAppScriptFriendlyName
    
} Catch {
    [Int32]$mainExitCode = 60001
    [String]$mainErrorMessage = "$(Resolve-Error)"
    Write-Log -Message $mainErrorMessage -Severity 3 -Source $deployAppScriptFriendlyName
    Show-DialogBox -Text $mainErrorMessage -Icon 'Stop'
    Exit-Script -ExitCode $mainExitCode
}