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
    $appName = "Simple Countdown Test"
    $appVersion = "1.0"
    $appVendor = "Test"
    
    # Show a simple 30-second countdown message that auto-closes
    Show-InstallationPrompt -Message "This countdown dialog will automatically close in 30 seconds!" -ButtonRightText "OK" -Timeout 30
    
    Write-Log "Countdown completed successfully - no restart!" -Source "Test-SimpleCountdown"
}
catch {
    Write-Log "Error: $($_.Exception.Message)" -Source "Test-SimpleCountdown" -Severity 3
}
#endregion