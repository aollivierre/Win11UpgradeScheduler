# Testing Script for Silent Windows 11 Installation Assistant

<#
.SYNOPSIS
    Test script to verify silent Installation Assistant execution
.DESCRIPTION
    This script demonstrates and tests the silent Windows 11 upgrade approach
    using Installation Assistant run as SYSTEM via scheduled task
#>

#region Test Functions

function Test-SilentInstallationAssistant {
    param(
        [string]$InstallAssistantPath = "C:\Code\Windows\Win11UpgradeScheduler-FINAL\src\Files\Windows11InstallationAssistant.exe"
    )
    
    Write-Host "Testing Silent Windows 11 Installation Assistant" -ForegroundColor Cyan
    Write-Host ("=" * 50) -ForegroundColor Cyan
    
    # 1. Verify Installation Assistant exists
    if (!(Test-Path $InstallAssistantPath)) {
        Write-Host "ERROR: Installation Assistant not found at: $InstallAssistantPath" -ForegroundColor Red
        return
    }
    Write-Host "[OK] Installation Assistant found" -ForegroundColor Green
    
    # 2. Check current Windows version
    $os = Get-WmiObject Win32_OperatingSystem
    Write-Host "`nCurrent OS: $($os.Caption) Build $($os.BuildNumber)" -ForegroundColor Yellow
    
    if ($os.Caption -like "*Windows 11*") {
        Write-Host "WARNING: Already running Windows 11. Test may not show full upgrade process." -ForegroundColor Yellow
    }
    
    # 3. Set registry bypass keys
    Write-Host "`nSetting registry bypass keys..." -ForegroundColor Yellow
    
    $labConfigPath = "HKLM:\SYSTEM\Setup\LabConfig"
    if (!(Test-Path $labConfigPath)) {
        New-Item -Path "HKLM:\SYSTEM\Setup" -Name "LabConfig" -Force | Out-Null
    }
    
    $bypassKeys = @{
        "BypassCPUCheck" = 1
        "BypassRAMCheck" = 1
        "BypassSecureBootCheck" = 1
        "BypassStorageCheck" = 1
        # NOT setting BypassTPMCheck
    }
    
    foreach ($key in $bypassKeys.Keys) {
        Set-ItemProperty -Path $labConfigPath -Name $key -Value $bypassKeys[$key] -Type DWord -Force
        Write-Host "  Set $key = 1" -ForegroundColor Gray
    }
    Write-Host "[OK] Registry bypass keys configured" -ForegroundColor Green
    
    # 4. Create scheduled task
    $taskName = "Win11SilentTest_$(Get-Date -Format 'HHmmss')"
    Write-Host "`nCreating scheduled task: $taskName" -ForegroundColor Yellow
    
    $action = New-ScheduledTaskAction -Execute $InstallAssistantPath -Argument "/QuietInstall /SkipEULA"
    $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
    
    try {
        $task = Register-ScheduledTask -TaskName $taskName -Action $action -Principal $principal -Settings $settings -Force
        Write-Host "[OK] Scheduled task created" -ForegroundColor Green
    }
    catch {
        Write-Host "ERROR: Failed to create scheduled task: $_" -ForegroundColor Red
        return
    }
    
    # 5. Start the task
    Write-Host "`nStarting Installation Assistant via scheduled task..." -ForegroundColor Yellow
    try {
        Start-ScheduledTask -TaskName $taskName
        Write-Host "[OK] Task started" -ForegroundColor Green
    }
    catch {
        Write-Host "ERROR: Failed to start task: $_" -ForegroundColor Red
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
        return
    }
    
    # 6. Monitor for 2 minutes
    Write-Host "`nMonitoring for 2 minutes..." -ForegroundColor Yellow
    $endTime = (Get-Date).AddMinutes(2)
    $processFound = $false
    $upgradeFolderFound = $false
    
    while ((Get-Date) -lt $endTime) {
        # Check for process
        $process = Get-Process -Name "Windows11InstallationAssistant" -ErrorAction SilentlyContinue
        if ($process -and -not $processFound) {
            $processFound = $true
            Write-Host "[OK] Installation Assistant process running (PID: $($process.Id))" -ForegroundColor Green
            
            # Check process owner
            $wmi = Get-WmiObject Win32_Process -Filter "ProcessId = $($process.Id)"
            if ($wmi) {
                $owner = $wmi.GetOwner()
                Write-Host "     Running as: $($owner.Domain)\$($owner.User)" -ForegroundColor Gray
                Write-Host "     Command: $($wmi.CommandLine)" -ForegroundColor Gray
            }
        }
        
        # Check for upgrade folder
        if ((Test-Path "C:\`$WINDOWS.~BT") -and -not $upgradeFolderFound) {
            $upgradeFolderFound = $true
            Write-Host "[OK] Windows upgrade folder created" -ForegroundColor Green
        }
        
        # Check task status
        $taskInfo = Get-ScheduledTaskInfo -TaskName $taskName -ErrorAction SilentlyContinue
        if ($taskInfo -and $taskInfo.LastTaskResult -ne $null -and $taskInfo.LastTaskResult -ne 267009) {
            Write-Host "Task completed with exit code: $($taskInfo.LastTaskResult)" -ForegroundColor Yellow
            break
        }
        
        Start-Sleep -Seconds 10
        Write-Host "." -NoNewline
    }
    
    Write-Host ""
    
    # 7. Final status
    Write-Host "`nFinal Status:" -ForegroundColor Cyan
    Write-Host "Process Found: $(if ($processFound) { 'YES' } else { 'NO' })" -ForegroundColor $(if ($processFound) { 'Green' } else { 'Red' })
    Write-Host "Upgrade Folder: $(if ($upgradeFolderFound) { 'YES' } else { 'NO' })" -ForegroundColor $(if ($upgradeFolderFound) { 'Green' } else { 'Red' })
    
    if ($processFound -or $upgradeFolderFound) {
        Write-Host "`nSUCCESS: Silent Installation Assistant is working!" -ForegroundColor Green -BackgroundColor Black
        Write-Host "The upgrade will continue in the background." -ForegroundColor Green
    }
    else {
        Write-Host "`nWARNING: Could not confirm silent execution." -ForegroundColor Yellow
        Write-Host "Check if already on Windows 11 or if other issues exist." -ForegroundColor Yellow
    }
    
    # Cleanup option
    Write-Host "`nCleanup task? (This won't stop the upgrade if it's running)" -ForegroundColor Yellow
    $cleanup = Read-Host "Type 'yes' to remove scheduled task"
    if ($cleanup -eq 'yes') {
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
        Write-Host "Task removed" -ForegroundColor Gray
    }
}

function Get-UpgradeStatus {
    Write-Host "`nChecking Windows 11 Upgrade Status" -ForegroundColor Cyan
    Write-Host ("=" * 50) -ForegroundColor Cyan
    
    # Check for Installation Assistant process
    $process = Get-Process -Name "Windows11InstallationAssistant" -ErrorAction SilentlyContinue
    if ($process) {
        Write-Host "Installation Assistant: RUNNING (PID: $($process.Id))" -ForegroundColor Green
        $wmi = Get-WmiObject Win32_Process -Filter "ProcessId = $($process.Id)"
        if ($wmi) {
            Write-Host "Command Line: $($wmi.CommandLine)" -ForegroundColor Gray
        }
    }
    else {
        Write-Host "Installation Assistant: NOT RUNNING" -ForegroundColor Yellow
    }
    
    # Check upgrade folder
    if (Test-Path "C:\`$WINDOWS.~BT") {
        Write-Host "`nUpgrade Folder: EXISTS" -ForegroundColor Green
        try {
            $files = Get-ChildItem "C:\`$WINDOWS.~BT" -Recurse -Force -ErrorAction SilentlyContinue
            $sizeGB = [math]::Round(($files | Measure-Object -Property Length -Sum).Sum / 1GB, 2)
            Write-Host "Folder Size: $sizeGB GB" -ForegroundColor Yellow
            Write-Host "File Count: $($files.Count)" -ForegroundColor Yellow
        }
        catch {
            Write-Host "Unable to calculate folder size" -ForegroundColor Gray
        }
    }
    else {
        Write-Host "`nUpgrade Folder: NOT FOUND" -ForegroundColor Yellow
    }
    
    # Check scheduled tasks
    Write-Host "`nWindows 11 Scheduled Tasks:" -ForegroundColor Cyan
    $tasks = Get-ScheduledTask | Where-Object { $_.TaskName -like "*Win11*" }
    if ($tasks) {
        foreach ($task in $tasks) {
            $info = $task | Get-ScheduledTaskInfo
            Write-Host "Task: $($task.TaskName)" -ForegroundColor Yellow
            Write-Host "  State: $($task.State)" -ForegroundColor Gray
            Write-Host "  Last Run: $($info.LastRunTime)" -ForegroundColor Gray
            Write-Host "  Last Result: 0x$($info.LastTaskResult.ToString('X'))" -ForegroundColor Gray
        }
    }
    else {
        Write-Host "No Windows 11 scheduled tasks found" -ForegroundColor Gray
    }
}

#endregion

# Display menu
Write-Host @"

Windows 11 Silent Installation Assistant Test Script
====================================================

This script tests the silent Installation Assistant approach.
Requires Administrator privileges.

Options:
1. Run full test (creates and starts scheduled task)
2. Check current upgrade status
3. Exit

"@ -ForegroundColor Cyan

$choice = Read-Host "Enter choice (1-3)"

switch ($choice) {
    '1' {
        # Check if running as admin
        $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
        if (-not $isAdmin) {
            Write-Host "ERROR: This test requires Administrator privileges" -ForegroundColor Red
            exit 1
        }
        Test-SilentInstallationAssistant
    }
    '2' {
        Get-UpgradeStatus
    }
    '3' {
        Write-Host "Exiting..." -ForegroundColor Gray
        exit 0
    }
    default {
        Write-Host "Invalid choice" -ForegroundColor Red
    }
}