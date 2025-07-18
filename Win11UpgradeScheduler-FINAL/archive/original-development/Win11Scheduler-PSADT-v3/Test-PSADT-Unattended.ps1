<#
.SYNOPSIS
    Test PSADT v3 Unattended Behavior
#>

# Simulate running as SYSTEM to test unattended behavior
Write-Host "Testing PSADT behavior in unattended scenario...`n"

# Create a scheduled task to run as SYSTEM
$taskName = "PSADTUnattendedTest_$(Get-Date -Format 'yyyyMMddHHmmss')"
$scriptPath = Join-Path $PSScriptRoot "Test-PSADT-SessionDetection-Simple.ps1"

# Create task action
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$scriptPath`" > `"$PSScriptRoot\UnattendedTest.log`" 2>&1"

# Create task trigger (run immediately)
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddSeconds(5)

# Create task principal (SYSTEM)
$principal = New-ScheduledTaskPrincipal -UserId "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount -RunLevel Highest

# Register the task
Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Force | Out-Null

Write-Host "Created scheduled task: $taskName"
Write-Host "Waiting for task to run..."

# Wait for task to complete
Start-Sleep -Seconds 10

# Check if log was created
$logPath = Join-Path $PSScriptRoot "UnattendedTest.log"
if (Test-Path $logPath) {
    Write-Host "`nTask completed. Output:"
    Write-Host "================================"
    Get-Content $logPath | Select-Object -Last 50
    
    # Clean up
    Remove-Item $logPath -Force
} else {
    Write-Host "Log file not created - task may have failed"
}

# Clean up task
Unregister-ScheduledTask -TaskName $taskName -Confirm:$false

Write-Host "`nTest completed."