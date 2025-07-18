# Test script to simulate scheduled task execution as SYSTEM
# This will test the Show-ScheduledPrompt function

# Set up environment
$PSScriptRoot = "C:\code\Win11UpgradeScheduler\Win11UpgradeScheduler-FINAL\src"
$deployAppScriptFriendlyName = "TestScheduledUI"
$ScheduledMode = $true

# Load the main script functions
. "$PSScriptRoot\AppDeployToolkit\AppDeployToolkitMain.ps1"

# Load the Deploy-Application script to get Show-ScheduledPrompt
$scriptContent = Get-Content "$PSScriptRoot\Deploy-Application-InstallationAssistant-Version.ps1" -Raw
$functionMatch = [regex]::Match($scriptContent, '(?ms)Function Show-ScheduledPrompt.*?^\s*\}')
if ($functionMatch.Success) {
    $functionCode = $functionMatch.Value
    Invoke-Expression $functionCode
}

# Test the function
Write-Host "Testing Show-ScheduledPrompt function..."
Write-Host "Current user: $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)"
Write-Host ""

# Test message
$testMessage = @"
Your system is not ready for Windows 11 upgrade:

- System has pending reboot: Test Reason
- Low disk space

Please resolve these issues and try again.
"@

# Call the function
Show-ScheduledPrompt -Message $testMessage -ButtonRightText 'OK' -Icon 'Error'

Write-Host "`nTest completed."