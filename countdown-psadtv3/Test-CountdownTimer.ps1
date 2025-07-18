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
    $appName = "Countdown Timer Test"
    $appVersion = "1.0"
    $appVendor = "Test"
    
    Write-Log "Starting countdown timer test..." -Source "Test-CountdownTimer"
    
    # Test 1: Simple 1-minute countdown with restart prompt
    Write-Log "Showing 1-minute countdown restart prompt..." -Source "Test-CountdownTimer"
    Show-InstallationRestartPrompt -CountdownSeconds 60 -CountdownNoHideSeconds 10
    
    Write-Log "Countdown timer test completed successfully." -Source "Test-CountdownTimer"
}
catch {
    Write-Log "Error occurred: $($_.Exception.Message)" -Source "Test-CountdownTimer" -Severity 3
    Show-InstallationPrompt -Message "An error occurred during the countdown timer test: $($_.Exception.Message)" -ButtonRightText "OK"
}
#endregion