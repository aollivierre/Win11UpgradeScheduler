# PSADT Custom Countdown Module - Integration Guide

## Quick Start

### 1. Copy the Module
Copy `PSADTCustomCountdown.psm1` to your PSADT project folder:
```
YourProject\
├── Deploy-Application.ps1
├── PSADTCustomCountdown.psm1  <-- Copy here
└── AppDeployToolkit\
    └── ...
```

### 2. Import in Your Deploy-Application.ps1
Add this line after importing PSADT:
```powershell
# Import PSADT
. "$scriptDirectory\AppDeployToolkit\AppDeployToolkitMain.ps1"

# Import custom countdown module
Import-Module "$scriptDirectory\PSADTCustomCountdown.psm1" -Force
```

### 3. Use Instead of PSADT Built-in Timers

## Usage Examples

### Replace Restart Countdown (No Restart)
```powershell
# Instead of this (WILL RESTART):
# Show-InstallationRestartPrompt -CountdownSeconds 300

# Use this (NO RESTART):
Show-CustomCountdownDialog -CountdownSeconds 300 -Message "System maintenance in progress..."
```

### Replace App Close Countdown (No App Closing)
```powershell
# Instead of this (WILL CLOSE APPS):
# Show-InstallationWelcome -CloseApps 'chrome' -ForceCloseAppsCountdown 120

# Use this (NO ACTION):
Show-CustomCountdownDialog -CountdownSeconds 120 -Message "Please save your work in Chrome"
# Then handle app closing your own way if needed
```

### Add Visual Feedback Without Actions
```powershell
# Show countdown before starting installation
Show-CustomCountdownDialog -CountdownSeconds 60 -Message "Installation will begin shortly..."

# Show countdown during long operations
Start-Job -ScriptBlock { 
    # Long running task
}
Show-CustomCountdownDialog -CountdownSeconds 180 -Message "Configuring system settings..." -NoAutoClose
```

## Complete Example Deploy-Application.ps1

```powershell
<#
.SYNOPSIS
    Deploy Application with Custom Countdown
#>
[CmdletBinding()]
Param ()

#region Initialization
[string]$appVendor = 'MyCompany'
[string]$appName = 'MyApplication'
[string]$appVersion = '1.0.0'
[string]$appScriptVersion = '1.0.0'

# Variables: Script
[string]$scriptDirectory = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent

# Import PSADT
. "$scriptDirectory\AppDeployToolkit\AppDeployToolkitMain.ps1"

# Import custom countdown module
Import-Module "$scriptDirectory\PSADTCustomCountdown.psm1" -Force
#endregion

#region Pre-Installation
[string]$installPhase = 'Pre-Installation'

# Show visual countdown without closing apps
Write-Log "Displaying preparation countdown..."
Show-CustomCountdownDialog -CountdownSeconds 60 -Message "Preparing to install $appName. Please save your work."

# Now handle app closing your own way if needed
$runningApps = Get-Process 'notepad','chrome' -ErrorAction SilentlyContinue
if ($runningApps) {
    $response = Show-InstallationPrompt -Message "Please close the following applications to continue: Notepad, Chrome" -ButtonRightText 'Continue' -ButtonLeftText 'Cancel'
    if ($response -eq 'Cancel') { Exit-Script -ExitCode 1223 }
}
#endregion

#region Installation
[string]$installPhase = 'Installation'

Show-InstallationProgress -StatusMessage "Installing $appName..."

# Your installation code here
Execute-MSI -Action 'Install' -Path "$dirFiles\YourApp.msi"

Close-InstallationProgress
#endregion

#region Post-Installation
[string]$installPhase = 'Post-Installation'

# Show countdown before configuration
Show-CustomCountdownDialog -CountdownSeconds 30 -Message "Finalizing installation..." -Title "$appName Setup"

# Complete
Show-InstallationPrompt -Message "$appName has been installed successfully." -ButtonRightText 'OK'
#endregion
```

## Function Reference

### Show-CustomCountdownDialog
Main function with full parameter set:
- `-CountdownSeconds`: Duration in seconds (1-86400)
- `-Message`: Custom message to display
- `-Title`: Window title (defaults to $appName)
- `-NoAutoClose`: Keep window open after countdown

### Show-InstallationCountdown
PSADT-style alias for consistency:
```powershell
Show-InstallationCountdown -CountdownSeconds 60 -Message "Please wait..."
```

## Benefits Over PSADT Built-in

1. **No Forced Actions**: Pure visual feedback without closing apps or restarting
2. **Full Control**: You decide what happens after countdown
3. **Same Visual Style**: Looks like PSADT native dialogs
4. **PSADT Integration**: Uses PSADT logging when available
5. **Drop-in Replacement**: Easy to swap with existing countdown calls

## Module Features

- Integrates with PSADT logging (`Write-Log`)
- Uses PSADT application icon when available
- Follows PSADT naming conventions
- Returns standard dialog results
- Supports all PSADT deployment phases

## Troubleshooting

### Module won't load
```powershell
# Use -Force to reload
Import-Module "$scriptDirectory\PSADTCustomCountdown.psm1" -Force
```

### Icon not showing
The module automatically finds the PSADT icon. Ensure `AppDeployToolkitLogo.ico` exists in the standard location.

### Logging not working
The module detects and uses PSADT logging automatically. Ensure you import the module AFTER importing PSADT.

## License
This module is designed to extend PSADT v3 and follows the same licensing terms.