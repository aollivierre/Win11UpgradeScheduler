# Test PSADT UI functionality
param(
    [string]$PSADTPath = "C:\code\Windows\Win11UpgradeScheduler-FINAL\src"
)

# Check if we're in an interactive session
$isInteractive = [Environment]::UserInteractive
Write-Host "User Interactive Session: $isInteractive"

# Check for active user sessions
$explorerProcesses = Get-CimInstance -ClassName Win32_Process -Filter "Name = 'explorer.exe'" |
    Where-Object { $_.SessionId -ne 0 }
Write-Host "Active Explorer Processes: $($explorerProcesses.Count)"

# Try to load PSADT and show a test dialog
$toolkitPath = Join-Path -Path $PSADTPath -ChildPath "AppDeployToolkit\AppDeployToolkitMain.ps1"

if (Test-Path $toolkitPath) {
    Write-Host "Loading PSADT toolkit..."
    . $toolkitPath
    
    Write-Host "Showing test dialog..."
    Show-InstallationPrompt -Message "This is a test dialog to verify PSADT UI is working.`n`nIf you can see this, the UI components are functioning correctly." `
        -ButtonRightText 'OK' `
        -Icon Information `
        -Timeout 30
    
    Write-Host "Dialog result: $($global:psButtonClicked)"
} else {
    Write-Host "ERROR: PSADT toolkit not found at: $toolkitPath" -ForegroundColor Red
}