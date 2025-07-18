# Test PSADT UI directly without subprocess
param(
    [string]$PSADTPath = "C:\code\Windows\Win11UpgradeScheduler-FINAL\src"
)

Write-Host "Testing PSADT UI directly..." -ForegroundColor Cyan

# Set required variables for PSADT
$scriptPath = $PSADTPath
$scriptRoot = $PSADTPath
$invokingScript = $MyInvocation.MyCommand.Path

# Load PSADT
Write-Host "Loading PSADT toolkit from: $PSADTPath" -ForegroundColor Yellow
$toolkitPath = Join-Path -Path $PSADTPath -ChildPath "AppDeployToolkit\AppDeployToolkitMain.ps1"

if (Test-Path $toolkitPath) {
    # Set location to PSADT directory
    Push-Location $PSADTPath
    
    try {
        # Dot-source the toolkit
        . $toolkitPath
        
        Write-Host "`nShowing PSADT dialog - this should appear on your screen:" -ForegroundColor Green
        
        # Method 1: Simple prompt
        Write-Host "`nTest 1: Simple Installation Prompt" -ForegroundColor Yellow
        $result1 = Show-InstallationPrompt `
            -Message "TEST 1: Can you see this PSADT dialog?`n`nThis is a direct test." `
            -ButtonRightText 'Yes' `
            -ButtonLeftText 'No' `
            -Icon Information
        
        Write-Host "Result 1: User clicked '$($global:psButtonClicked)'" -ForegroundColor Cyan
        
        # Method 2: Welcome prompt (different dialog type)
        Write-Host "`nTest 2: Welcome Dialog" -ForegroundColor Yellow
        $result2 = Show-InstallationWelcome `
            -CloseApps 'notepad' `
            -CheckDiskSpace `
            -RequiredDiskSpace 20 `
            -BlockExecution `
            -AllowDefer `
            -DeferTimes 3
        
        Write-Host "Result 2: Dialog closed" -ForegroundColor Cyan
        
    }
    finally {
        Pop-Location
    }
} else {
    Write-Host "ERROR: PSADT toolkit not found at: $toolkitPath" -ForegroundColor Red
}

Write-Host "`nIf you didn't see the PSADT dialogs, try running this script:" -ForegroundColor Yellow
Write-Host "1. Directly in your RDP session (not through remote execution)" -ForegroundColor White
Write-Host "2. As Administrator" -ForegroundColor White
Write-Host "3. From the PSADT directory itself" -ForegroundColor White