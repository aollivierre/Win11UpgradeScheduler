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
    $appName = "Safe Countdown Timer Test"
    $appVersion = "1.0"
    $appVendor = "Test"
    
    Write-Log "Starting safe countdown timer test..." -Source "Test-SafeCountdown"
    
    # Test 1: Welcome prompt with countdown (NO RESTART)
    Write-Log "Showing welcome prompt with 60-second countdown..." -Source "Test-SafeCountdown"
    Show-InstallationWelcome -CloseApps 'notepad' -ForceCloseAppsCountdown 60
    
    Write-Log "Safe countdown timer test completed successfully." -Source "Test-SafeCountdown"
    
    # Test 2: Simple installation prompt with countdown
    Write-Log "Showing installation prompt with message..." -Source "Test-SafeCountdown"
    Show-InstallationPrompt -Message "This is a test countdown message that will auto-close in 30 seconds." -ButtonRightText "OK" -Timeout 30
    
    Write-Log "All tests completed successfully." -Source "Test-SafeCountdown"
}
catch {
    Write-Log "Error occurred: $($_.Exception.Message)" -Source "Test-SafeCountdown" -Severity 3
    Show-InstallationPrompt -Message "An error occurred during the safe countdown timer test: $($_.Exception.Message)" -ButtonRightText "OK"
}
#endregion