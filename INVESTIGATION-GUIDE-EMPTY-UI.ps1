# Investigation Guide for Empty UI Dialog Issue
# Run these commands to diagnose the problem

#region Step 1: Check Current State
Write-Host "=== STEP 1: Checking current implementation ===" -ForegroundColor Cyan

# Check the error handling in wrapper
$wrapperPath = "C:\code\Win11UpgradeScheduler\Win11UpgradeScheduler-FINAL\src\SupportFiles\ScheduledTaskWrapper.ps1"
Write-Host "Checking wrapper at: $wrapperPath"
Select-String -Path $wrapperPath -Pattern "PreFlightError|Execute-ProcessAsUser|Show-InstallationPrompt" -Context 2,2

# Check if debug logging exists
$debugLog = "$env:TEMP\PreFlightError_Debug.log"
if (Test-Path $debugLog) {
    Write-Host "`nDebug log found at: $debugLog" -ForegroundColor Green
    Get-Content $debugLog -Tail 20
} else {
    Write-Host "`nNo debug log found at: $debugLog" -ForegroundColor Yellow
}
#endregion

#region Step 2: Test Toolkit Loading
Write-Host "`n=== STEP 2: Testing PSADT Toolkit Loading ===" -ForegroundColor Cyan

$toolkitPath = "C:\code\Win11UpgradeScheduler\Win11UpgradeScheduler-FINAL\src\AppDeployToolkit\AppDeployToolkitMain.ps1"
try {
    . $toolkitPath
    Write-Host "Toolkit loaded successfully" -ForegroundColor Green
    Write-Host "Show-InstallationPrompt function exists: $($null -ne (Get-Command Show-InstallationPrompt -ErrorAction SilentlyContinue))"
} catch {
    Write-Host "Failed to load toolkit: $_" -ForegroundColor Red
}
#endregion

#region Step 3: Capture Temporary Scripts
Write-Host "`n=== STEP 3: Looking for temporary scripts ===" -ForegroundColor Cyan

$tempScripts = Get-ChildItem -Path $env:TEMP -Filter "PreFlightError_*.ps1" -ErrorAction SilentlyContinue | 
    Sort-Object LastWriteTime -Descending | 
    Select-Object -First 5

if ($tempScripts) {
    Write-Host "Found temporary scripts:" -ForegroundColor Green
    foreach ($script in $tempScripts) {
        Write-Host "`nScript: $($script.FullName)"
        Write-Host "Created: $($script.LastWriteTime)"
        Write-Host "Content:" -ForegroundColor Yellow
        Get-Content $script.FullName
        Write-Host ("-" * 80)
    }
} else {
    Write-Host "No temporary scripts found" -ForegroundColor Yellow
}
#endregion

#region Step 4: Test Message Display Directly
Write-Host "`n=== STEP 4: Testing direct message display ===" -ForegroundColor Cyan

$testMessage = @"
Your system is not ready for Windows 11 upgrade:

- System has pending reboot: Test Reason
- Low disk space

Please resolve these issues and try again.
"@

# Test 1: Direct Show-InstallationPrompt
try {
    Write-Host "Test 1: Direct call to Show-InstallationPrompt"
    Show-InstallationPrompt -Message $testMessage -ButtonRightText 'OK' -Icon Error
    Write-Host "Success!" -ForegroundColor Green
} catch {
    Write-Host "Failed: $_" -ForegroundColor Red
}
#endregion

#region Step 5: Create Diagnostic Scheduled Task
Write-Host "`n=== STEP 5: Creating diagnostic scheduled task ===" -ForegroundColor Cyan

$diagnosticScript = @'
# Diagnostic script to test UI display from SYSTEM context
$logFile = "C:\Windows\Temp\DiagnosticUI_$(Get-Date -Format 'yyyyMMddHHmmss').log"

function Write-Log {
    param($Message)
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    "$timestamp - $Message" | Add-Content -Path $logFile
}

Write-Log "Starting diagnostic script"
Write-Log "Current user: $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)"
Write-Log "PS Version: $($PSVersionTable.PSVersion)"

# Try to load toolkit
$toolkitPath = "C:\code\Win11UpgradeScheduler\Win11UpgradeScheduler-FINAL\src\AppDeployToolkit\AppDeployToolkitMain.ps1"
Write-Log "Loading toolkit from: $toolkitPath"

try {
    . $toolkitPath
    Write-Log "Toolkit loaded successfully"
    
    # Check if function exists
    if (Get-Command Show-InstallationPrompt -ErrorAction SilentlyContinue) {
        Write-Log "Show-InstallationPrompt function found"
        
        # Try to get Execute-ProcessAsUser
        if (Get-Command Execute-ProcessAsUser -ErrorAction SilentlyContinue) {
            Write-Log "Execute-ProcessAsUser function found"
            
            # Create a test script
            $testScript = @"
. '$toolkitPath'
Show-InstallationPrompt -Message 'This is a test message from SYSTEM context' -ButtonRightText 'OK' -Icon Information
"@
            $tempPath = "$env:TEMP\TestUI_$(Get-Date -Format 'yyyyMMddHHmmss').ps1"
            $testScript | Set-Content -Path $tempPath
            Write-Log "Created test script at: $tempPath"
            
            # Try Execute-ProcessAsUser
            $result = Execute-ProcessAsUser -Path "$PSHOME\powershell.exe" -Parameters "-ExecutionPolicy Bypass -File `"$tempPath`"" -Wait -PassThru
            Write-Log "Execute-ProcessAsUser result: $($result.ExitCode)"
        } else {
            Write-Log "Execute-ProcessAsUser function NOT found"
        }
    } else {
        Write-Log "Show-InstallationPrompt function NOT found"
    }
} catch {
    Write-Log "Error: $_"
    Write-Log "Stack trace: $($_.ScriptStackTrace)"
}

Write-Log "Diagnostic complete"
Write-Host "Log saved to: $logFile"
'@

$diagPath = "$env:TEMP\DiagnosticUI.ps1"
$diagnosticScript | Set-Content -Path $diagPath

# Create scheduled task
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File `"$diagPath`""
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -RunLevel Highest
$settings = New-ScheduledTaskSettings -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries

Unregister-ScheduledTask -TaskName "DiagnosticUI" -Confirm:$false -ErrorAction SilentlyContinue
Register-ScheduledTask -TaskName "DiagnosticUI" -Action $action -Principal $principal -Settings $settings -Force

Write-Host "Diagnostic task created. Run with: Start-ScheduledTask -TaskName 'DiagnosticUI'" -ForegroundColor Green
Write-Host "Check log at: C:\Windows\Temp\DiagnosticUI_*.log" -ForegroundColor Yellow
#endregion

#region Step 6: Manual Test Commands
Write-Host "`n=== STEP 6: Manual test commands ===" -ForegroundColor Cyan
Write-Host @"
# To create the main test task:
& 'C:\code\Win11UpgradeScheduler\Create-TestScheduledTask.ps1'

# To run the test task:
Start-ScheduledTask -TaskName 'TestWin11UpgradeUI'

# To check task status:
Get-ScheduledTask -TaskName 'TestWin11UpgradeUI' | Select-Object TaskName, State, LastRunTime, LastTaskResult

# To run diagnostic task:
Start-ScheduledTask -TaskName 'DiagnosticUI'

# To check diagnostic log:
Get-Content 'C:\Windows\Temp\DiagnosticUI_*.log' -Tail 50
"@ -ForegroundColor Yellow
#endregion