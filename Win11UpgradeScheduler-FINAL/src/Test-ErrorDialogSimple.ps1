#region Simple Error Dialog Test
<#
.SYNOPSIS
    Simple test to verify error dialog shows message content
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$PSADTPath = 'C:\code\Windows\Win11UpgradeScheduler-FINAL\src'
)

# Test message similar to pre-flight check failure
$testMessage = "System is not ready for Windows 11 upgrade:`n`n- System has pending reboot: Pending File Rename Operations"

Write-Host "Testing error dialog display..." -ForegroundColor Yellow
Write-Host "Message to display: $testMessage" -ForegroundColor Cyan

# Load PSADT toolkit
$toolkitMain = Join-Path -Path $PSADTPath -ChildPath 'AppDeployToolkit\AppDeployToolkitMain.ps1'

if (Test-Path -Path $toolkitMain) {
    # Create the error script with proper escaping
    $escapedMessage = $testMessage -replace '"', '`"' -replace '\\$', '`$'
    $errorScript = ". '$toolkitMain'
Show-InstallationPrompt -Message `"$escapedMessage`" -ButtonRightText 'OK' -Icon Error"
    
    $tempErrorScript = Join-Path -Path $env:TEMP -ChildPath "TestPreFlightError_$(Get-Date -Format 'yyyyMMddHHmmss').ps1"
    $errorScript | Set-Content -Path $tempErrorScript -Force
    
    Write-Host "Created test script: $tempErrorScript" -ForegroundColor Yellow
    Write-Host "Script content:" -ForegroundColor Yellow
    Get-Content -Path $tempErrorScript | Write-Host -ForegroundColor Gray
    
    # Show the dialog
    Write-Host "Showing error dialog..." -ForegroundColor Yellow
    Start-Process -FilePath 'powershell.exe' `
        -ArgumentList "-ExecutionPolicy Bypass -File `"$tempErrorScript`"" `
        -WorkingDirectory $PSADTPath `
        -Wait `
        -WindowStyle Normal
    
    Remove-Item -Path $tempErrorScript -Force -ErrorAction SilentlyContinue
    Write-Host "Test completed!" -ForegroundColor Green
}
else {
    Write-Host "PSADT toolkit not found at: $toolkitMain" -ForegroundColor Red
}
#endregion