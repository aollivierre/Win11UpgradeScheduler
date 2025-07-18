<#
.SYNOPSIS
    Example PSADT v3 deployment script with custom countdown timer
.DESCRIPTION
    Shows how to integrate the custom countdown dialog into a PSADT deployment
#>

#region Initialization
# Variables: Application
[string]$appVendor = 'MyCompany'
[string]$appName = 'MyApplication'
[string]$appVersion = '1.0'
[string]$appArch = 'x64'
[string]$appLang = 'EN'
[string]$appRevision = '01'
[string]$appScriptVersion = '1.0.0'
[string]$appScriptDate = '2024-01-18'
[string]$appScriptAuthor = 'Administrator'

# Variables: Install Titles (Only set here to override defaults set by the toolkit)
[string]$installName = ''
[string]$installTitle = ''

# Import PSADT
[string]$scriptDirectory = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
. "$scriptDirectory\PSAppDeployToolkit\Toolkit\AppDeployToolkit\AppDeployToolkitMain.ps1"

# Import custom countdown function
. "$scriptDirectory\Show-CustomCountdownDialog.ps1"
#endregion

#region Pre-Installation
[string]$installPhase = 'Pre-Installation'

# Example 1: Show custom countdown before starting installation
Write-Log "Displaying 60-second countdown before installation begins..."
Show-CustomCountdownDialog -CountdownSeconds 60 -Message "Installation will begin automatically after the countdown. Please save your work."

# Example 2: Traditional PSADT countdown (closes apps)
Show-InstallationWelcome -CloseApps 'notepad,chrome' -ForceCloseAppsCountdown 120 -BlockExecution

# Display installation progress
Show-InstallationProgress -StatusMessage "Installing $appName $appVersion..."
#endregion

#region Installation
[string]$installPhase = 'Installation'

# Your installation code here
Write-Log "Performing installation tasks..."

# Example: Install MSI
# Execute-MSI -Action 'Install' -Path "$dirFiles\YourApp.msi"

# Simulate installation work
Start-Sleep -Seconds 5
#endregion

#region Post-Installation
[string]$installPhase = 'Post-Installation'

# Example 3: Show countdown before configuration
Write-Log "Displaying countdown before applying configurations..."
Show-CustomCountdownDialog -CountdownSeconds 30 -Message "Applying configurations in..." -NoAutoClose

# Apply configurations
Write-Log "Applying post-installation configurations..."
Start-Sleep -Seconds 2

# Close installation progress
Close-InstallationProgress

# Display completion message
Show-InstallationPrompt -Message "$appName has been successfully installed." -ButtonRightText 'OK'
#endregion