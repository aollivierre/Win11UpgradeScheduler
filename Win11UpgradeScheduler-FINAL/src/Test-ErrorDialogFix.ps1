#region Test Script for Error Dialog Fix
<#
.SYNOPSIS
    Test script to verify error dialog display fix
.DESCRIPTION
    Tests the error dialog display functionality to ensure messages appear correctly
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$PSADTPath = (Split-Path -Parent $MyInvocation.MyCommand.Definition)
)

# Load the wrapper functions
$wrapperScript = Join-Path -Path $PSADTPath -ChildPath 'SupportFiles\ScheduledTaskWrapper.ps1'
. $wrapperScript

# Test message similar to pre-flight check failure
$testMessage = "System is not ready for Windows 11 upgrade:`n`n- System has pending reboot: Pending File Rename Operations"

Write-Host "Testing error dialog display..." -ForegroundColor Yellow
Write-Host "Message to display: $testMessage" -ForegroundColor Cyan

# Test the error display logic
if (Test-RunningAsSystem) {
    Write-Host "Running as SYSTEM - using Execute-ProcessAsUser" -ForegroundColor Green
    
    # Load PSADT toolkit
    $toolkitMain = Join-Path -Path $PSADTPath -ChildPath 'AppDeployToolkit\AppDeployToolkitMain.ps1'
    . $toolkitMain
    
    # Use PSADT to show error - escape message properly
    $escapedMessage = $testMessage -replace '"', '`"' -replace '\\$', '`$'
    $errorScript = ". '$toolkitMain'
Show-InstallationPrompt -Message `"$escapedMessage`" -ButtonRightText 'OK' -Icon Error"
    
    $tempErrorScript = Join-Path -Path $env:TEMP -ChildPath "TestPreFlightError_$(Get-Date -Format 'yyyyMMddHHmmss').ps1"
    $errorScript | Set-Content -Path $tempErrorScript -Force
    
    Write-Host "Created test script: $tempErrorScript" -ForegroundColor Yellow
    Write-Host "Script content:" -ForegroundColor Yellow
    Get-Content -Path $tempErrorScript | Write-Host -ForegroundColor Gray
    
    Execute-ProcessAsUser -Path "$PSHOME\powershell.exe" `
        -Parameters "-ExecutionPolicy Bypass -File `"$tempErrorScript`"" `
        -Wait
    
    Remove-Item -Path $tempErrorScript -Force -ErrorAction SilentlyContinue
}
else {
    Write-Host "Not running as SYSTEM - using standard approach" -ForegroundColor Green
    
    $escapedMessage = $testMessage -replace '"', '`"' -replace '\\$', '`$'
    $errorScript = "`$scriptPath = Split-Path -Parent `$MyInvocation.MyCommand.Definition
. `"`$scriptPath\AppDeployToolkit\AppDeployToolkitMain.ps1`"
Show-InstallationPrompt -Message `"$escapedMessage`" -ButtonRightText 'OK' -Icon Error"
    
    $tempErrorScript = Join-Path -Path $env:TEMP -ChildPath "TestPreFlightError_$(Get-Date -Format 'yyyyMMddHHmmss').ps1"
    $errorScript | Set-Content -Path $tempErrorScript -Force
    
    Write-Host "Created test script: $tempErrorScript" -ForegroundColor Yellow
    Write-Host "Script content:" -ForegroundColor Yellow
    Get-Content -Path $tempErrorScript | Write-Host -ForegroundColor Gray
    
    Start-Process -FilePath 'powershell.exe' `
        -ArgumentList "-ExecutionPolicy Bypass -File `"$tempErrorScript`"" `
        -WorkingDirectory $PSADTPath `
        -Wait `
        -WindowStyle Normal
    
    Remove-Item -Path $tempErrorScript -Force -ErrorAction SilentlyContinue
}

Write-Host "Test completed!" -ForegroundColor Green
#endregion