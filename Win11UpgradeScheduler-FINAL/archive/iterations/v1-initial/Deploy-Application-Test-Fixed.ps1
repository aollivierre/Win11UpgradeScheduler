<#
.SYNOPSIS
    Windows 11 In-Place Upgrade Scheduler - Test Version with Bypassed Compatibility
    
.DESCRIPTION
    Test version that bypasses compatibility checks to demonstrate the full flow
#>

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
    Try { Set-ExecutionPolicy -ExecutionPolicy 'ByPass' -Scope 'Process' -Force -ErrorAction 'Stop' } 
    Catch { Write-Error "Failed to set execution policy: $($_.Exception.Message)" }

    #region Variable Declaration
    [String]$appVendor = 'Microsoft'
    [String]$appName = 'Windows 11 Upgrade Scheduler'
    [String]$appVersion = '22H2'
    [String]$appScriptVersion = '1.0.0'
    [String]$appScriptDate = '07/12/2025'
    [String]$appScriptAuthor = 'IT Department'
    [String]$installName = 'Windows 11 Upgrade Scheduler'
    [String]$installTitle = 'Windows 11 Upgrade Scheduler v1.0.0'
    [String]$dirFiles = Join-Path -Path $PSScriptRoot -ChildPath 'Files'
    [String]$dirSupportFiles = Join-Path -Path $PSScriptRoot -ChildPath 'SupportFiles'
    [String]$organizationName = 'ABC Corporation'
    [Int]$deadlineDays = 14
    #endregion
    
    # Import the PSADT v3.10.2 module
    . "$PSScriptRoot\AppDeployToolkit\AppDeployToolkitMain.ps1"
    
    # Import custom dialog functions
    . "$dirSupportFiles\Show-UpgradeInformationDialog.ps1"
    . "$dirSupportFiles\Show-CalendarPicker.ps1"
    . "$dirSupportFiles\New-Win11UpgradeTask.ps1"
    
    #region Main Installation Logic
    Write-Log -Message "Starting Windows 11 Upgrade Scheduler TEST deployment..." -Source $deployAppScriptFriendlyName
    Write-Log -Message "*** COMPATIBILITY CHECK BYPASSED FOR TESTING ***" -Source $deployAppScriptFriendlyName
    
    if ($deploymentType -ieq 'Install') {
        
        # Show PSADT welcome dialog
        Write-Log -Message "Displaying PSADT welcome dialog..." -Source $deployAppScriptFriendlyName
        $welcomeResult = Show-InstallationWelcome -CloseApps 'notepad,calc' -AllowDefer -DeferTimes 3
        
        if ($welcomeResult -eq 'Defer') {
            Write-Log -Message "User chose to defer" -Source $deployAppScriptFriendlyName
            Exit-Script -ExitCode 1618
        }
        elseif ($welcomeResult -eq 'Close') {
            Write-Log -Message "User cancelled" -Source $deployAppScriptFriendlyName
            Exit-Script -ExitCode 1602
        }
        
        # Show upgrade information dialog
        Write-Log -Message "Displaying upgrade information dialog..." -Source $deployAppScriptFriendlyName
        $userChoice = Show-UpgradeInformationDialog -OrganizationName $organizationName -DeadlineDays $deadlineDays
        
        if ($userChoice -eq 'UpgradeNow') {
            Show-InstallationPrompt -Message "Immediate upgrade would start here. For testing, please use Schedule option." -ButtonRightText 'OK' -Icon 'Information'
            Exit-Script -ExitCode 0
        }
        elseif ($userChoice -eq 'RemindLater') {
            Write-Log -Message "User chose to be reminded later" -Source $deployAppScriptFriendlyName
            Exit-Script -ExitCode 1618
        }
        elseif ($userChoice -ne 'Schedule') {
            Exit-Script -ExitCode 1602
        }
        
        # Show calendar picker
        Write-Log -Message "Launching calendar picker..." -Source $deployAppScriptFriendlyName
        $selectedDate = Show-CalendarPicker -MinDate (Get-Date).AddDays(1) -MaxDate (Get-Date).AddDays($deadlineDays)
        
        if ($selectedDate) {
            Write-Log -Message "User selected date: $($selectedDate.ToString('yyyy-MM-dd HH:mm:ss'))" -Source $deployAppScriptFriendlyName
            
            # Create scheduled task
            Write-Log -Message "Creating scheduled task..." -Source $deployAppScriptFriendlyName
            $taskName = "Win11Upgrade_Clean_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
            $taskCreated = New-Win11UpgradeTask -ScheduledDate $selectedDate -TaskName $taskName
            
            if ($taskCreated) {
                $successMessage = "SUCCESS! Windows 11 upgrade scheduled!`n`n"
                $successMessage += "Date: $($selectedDate.ToString('MMMM dd, yyyy'))`n"
                $successMessage += "Time: $($selectedDate.ToString('h:mm tt'))`n`n"
                $successMessage += "Task Name: $taskName`n`n"
                $successMessage += "Check Task Scheduler to verify the task was created."
                
                Show-InstallationPrompt -Message $successMessage -ButtonRightText 'OK' -Icon 'Information'
                Write-Log -Message "Windows 11 upgrade successfully scheduled" -Source $deployAppScriptFriendlyName
                Exit-Script -ExitCode 0
            } else {
                Show-InstallationPrompt -Message "ERROR: Failed to create scheduled task!" -ButtonRightText 'OK' -Icon 'Error'
                Exit-Script -ExitCode 69002
            }
        } else {
            Show-InstallationPrompt -Message "Upgrade scheduling cancelled." -ButtonRightText 'OK' -Icon 'Information'
            Exit-Script -ExitCode 1602
        }
    }
    #endregion
    
} Catch {
    [Int32]$mainExitCode = 60001
    [String]$mainErrorMessage = $_.Exception.Message
    Write-Host "Error: $mainErrorMessage" -ForegroundColor Red
    if (Get-Command Write-Log -ErrorAction SilentlyContinue) {
        Write-Log -Message $mainErrorMessage -Severity 3 -Source 'Deploy-Application-Test'
    }
    if (Get-Command Exit-Script -ErrorAction SilentlyContinue) {
        Exit-Script -ExitCode $mainExitCode
    } else {
        Exit $mainExitCode
    }
}