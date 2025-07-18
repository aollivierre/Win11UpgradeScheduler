# Example of how warnings are handled in the updated implementation

# In Deploy-Application.ps1, after pre-flight checks:

# Run pre-flight checks
Write-Log -Message "Running pre-flight checks" -Source $deployAppScriptFriendlyName
Show-InstallationProgress -StatusMessage "Checking system readiness..."

$preFlightResults = Test-SystemReadiness

If (-not $preFlightResults.IsReady) {
    # Critical failures - cannot proceed
    Close-InstallationProgress
    
    $issueMessage = "Your system is not ready for Windows 11 upgrade:`n`n"
    ForEach ($issue in $preFlightResults.Issues) {
        $issueMessage += "- $issue`n"
    }
    $issueMessage += "`nPlease resolve these issues and try again."
    
    Show-InstallationPrompt -Message $issueMessage `
        -ButtonRightText 'OK' `
        -Icon Error
    
    Write-Log -Message "Pre-flight checks failed: $($preFlightResults.Issues -join '; ')" -Severity 2 -Source $deployAppScriptFriendlyName
    Exit-Script -ExitCode 1618
}
ElseIf ($preFlightResults.Warnings.Count -gt 0) {
    # Warnings present but can proceed
    Close-InstallationProgress
    
    $warningMessage = "System check completed with warnings:`n`n"
    ForEach ($warning in $preFlightResults.Warnings) {
        $warningMessage += "- $warning`n"
    }
    $warningMessage += "`nYou can proceed with the upgrade, but addressing these warnings is recommended.`n`nDo you want to continue?"
    
    $result = Show-InstallationPrompt -Message $warningMessage `
        -ButtonLeftText 'Continue' `
        -ButtonRightText 'Cancel' `
        -Icon Warning
    
    If ($result -eq 'Cancel') {
        Write-Log -Message "User cancelled due to warnings" -Source $deployAppScriptFriendlyName
        Exit-Script -ExitCode 1602
    }
    
    Write-Log -Message "User acknowledged warnings and chose to continue" -Source $deployAppScriptFriendlyName
}
Else {
    # All checks passed without warnings
    Close-InstallationProgress
    Write-Log -Message "All pre-flight checks passed" -Source $deployAppScriptFriendlyName
}

# Example scenarios and what users would see:

<#
SCENARIO 1: User has 30GB free space (between 25-50GB)
User sees:
"System check completed with warnings:

- Low disk space warning. Have 30GB free, recommended 50GB for optimal upgrade experience

You can proceed with the upgrade, but addressing these warnings is recommended.

Do you want to continue?"
[Continue] [Cancel]
#>

<#
SCENARIO 2: User has 20GB free space (below 25GB) 
User sees:
"Your system is not ready for Windows 11 upgrade:

- Insufficient disk space. Need at least 25GB free, have 20GB

Please resolve these issues and try again."
[OK]
#>

<#
SCENARIO 3: User has TPM 1.2 and 45GB free space
User sees:
"System check completed with warnings:

- TPM 1.2 detected and enabled. TPM 2.0 is recommended but not required.
- Low disk space warning. Have 45GB free, recommended 50GB for optimal upgrade experience

You can proceed with the upgrade, but addressing these warnings is recommended.

Do you want to continue?"
[Continue] [Cancel]
#>

<#
SCENARIO 4: User has no TPM
User sees:
"Your system is not ready for Windows 11 upgrade:

- No TPM detected. At least TPM 1.2 is required for security.

Please resolve these issues and try again."
[OK]
#>

<#
SCENARIO 5: Everything optimal (60GB free, TPM 2.0)
User proceeds directly to upgrade options without any warning dialogs
#>