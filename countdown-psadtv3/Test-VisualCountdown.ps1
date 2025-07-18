#region Initialize
# Set script location and import PSADT
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$psadtPath = Join-Path $scriptPath "PSAppDeployToolkit\Toolkit\AppDeployToolkit"

# Import the toolkit
. "$psadtPath\AppDeployToolkitMain.ps1"
#endregion

#region Main Script
try {
    # Initialize the toolkit
    $appName = "Visual Countdown Test"
    $appVersion = "1.0"
    $appVendor = "Test"
    
    # Show welcome prompt with visual countdown to close notepad (if running)
    # This shows a REAL countdown timer that counts down visually
    Show-InstallationWelcome -CloseApps 'notepad' -ForceCloseAppsCountdown 60 -BlockExecution
    
    Write-Log "Visual countdown completed successfully - no restart!" -Source "Test-VisualCountdown"
}
catch {
    Write-Log "Error: $($_.Exception.Message)" -Source "Test-VisualCountdown" -Severity 3
}
#endregion