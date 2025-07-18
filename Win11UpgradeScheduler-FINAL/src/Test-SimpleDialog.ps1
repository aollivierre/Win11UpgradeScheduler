#region Simple Dialog Test
<#
.SYNOPSIS
    Simple test to verify PSADT dialog display
.DESCRIPTION
    Tests basic PSADT dialog functionality
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$PSADTPath = 'C:\code\Windows\Win11UpgradeScheduler-FINAL\src'
)

# Load PSADT toolkit
$toolkitMain = Join-Path -Path $PSADTPath -ChildPath 'AppDeployToolkit\AppDeployToolkitMain.ps1'

if (Test-Path -Path $toolkitMain) {
    Write-Host "Testing simple PSADT dialog..." -ForegroundColor Yellow
    
    # Create a simple dialog test
    $testScript = @"
# Load PSADT toolkit
. '$toolkitMain'

Write-Host "Showing simple dialog..."

# Test 1: Basic Installation Prompt
Show-InstallationPrompt ``
    -Message "TEST DIALOG`n`nThis is a test of PSADT dialog display.`n`nDid you see this dialog?" ``
    -ButtonRightText 'Yes' ``
    -ButtonLeftText 'No' ``
    -Icon Information ``
    -Timeout 15 ``
    -ExitOnTimeout `$true

Write-Host "Dialog test completed"
"@
    
    $tempScript = Join-Path -Path $env:TEMP -ChildPath "SimpleDialog_$(Get-Date -Format 'yyyyMMddHHmmss').ps1"
    $testScript | Set-Content -Path $tempScript -Force
    
    Write-Host "Created test script: $tempScript" -ForegroundColor Yellow
    
    # Show the dialog with visible window
    Write-Host "Showing test dialog..." -ForegroundColor Yellow
    Write-Host "Look for a PSADT dialog window!" -ForegroundColor Green
    
    Start-Process -FilePath 'powershell.exe' `
        -ArgumentList "-ExecutionPolicy Bypass -File `"$tempScript`"" `
        -WorkingDirectory $PSADTPath `
        -Wait `
        -WindowStyle Normal
    
    Remove-Item -Path $tempScript -Force -ErrorAction SilentlyContinue
    Write-Host "Test completed!" -ForegroundColor Green
    
    # Also test Windows message box as backup
    Write-Host "Testing Windows MessageBox as comparison..." -ForegroundColor Yellow
    Add-Type -AssemblyName System.Windows.Forms
    $result = [System.Windows.Forms.MessageBox]::Show("Did you see the PSADT dialog above?", "Dialog Test", "YesNo", "Question")
    Write-Host "Windows MessageBox result: $result" -ForegroundColor Cyan
}
else {
    Write-Host "PSADT toolkit not found at: $toolkitMain" -ForegroundColor Red
}
#endregion