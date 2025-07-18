<#
.SYNOPSIS
    Test PSADT v3 Deployment Mode Behavior
#>

$PSADTPath = $PSScriptRoot

Write-Host "`nTesting PSADT Deployment Modes...`n"

# Test 1: Interactive Mode (default)
Write-Host "TEST 1: Interactive Mode"
Write-Host "========================"

try {
    # Set deployment mode
    $global:deployMode = 'Interactive'
    
    # Import toolkit
    . "$PSADTPath\AppDeployToolkit\AppDeployToolkitMain.ps1" -DisableLogging
    
    Write-Host "Mode: $deployMode"
    Write-Host "Silent: $deployModeSilent"
    Write-Host "NonInteractive: $deployModeNonInteractive"
    Write-Host "Would show UI: $(if(-not $deployModeSilent){'YES'}else{'NO'})"
}
catch {
    Write-Host "Error: $_"
}

# Test 2: Silent Mode
Write-Host "`n`nTEST 2: Silent Mode"
Write-Host "==================="

try {
    # Clear variables
    Remove-Variable -Name deployMode* -Force -ErrorAction SilentlyContinue
    
    # Set deployment mode
    $global:deployMode = 'Silent'
    
    # Import toolkit
    . "$PSADTPath\AppDeployToolkit\AppDeployToolkitMain.ps1" -DisableLogging
    
    Write-Host "Mode: $deployMode"
    Write-Host "Silent: $deployModeSilent"
    Write-Host "NonInteractive: $deployModeNonInteractive"
    Write-Host "Would show UI: $(if(-not $deployModeSilent){'YES'}else{'NO'})"
}
catch {
    Write-Host "Error: $_"
}

# Test 3: Show how PSADT handles UI in different contexts
Write-Host "`n`nTEST 3: UI Decision Logic"
Write-Host "========================="

Write-Host "`nScenario 1: User logged in + Interactive mode"
Write-Host "Result: Shows UI (calendar picker)"

Write-Host "`nScenario 2: User logged in + Silent mode"
Write-Host "Result: No UI (proceeds silently)"

Write-Host "`nScenario 3: No user (SYSTEM) + Interactive mode"
Write-Host "Result: Depends on PSADT detection - usually silent"

Write-Host "`nScenario 4: No user (SYSTEM) + Silent mode"
Write-Host "Result: No UI (proceeds silently)"

Write-Host "`n`nCONCLUSION:"
Write-Host "==========="
Write-Host "PSADT can be controlled by setting `$deployMode to:"
Write-Host "- 'Interactive' = Show UI when user present"
Write-Host "- 'Silent' = Never show UI"
Write-Host "- 'NonInteractive' = Similar to Silent"