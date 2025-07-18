#region Test Script Header
<#
.SYNOPSIS
    Comprehensive test suite for Windows 11 Upgrade Scheduler
.DESCRIPTION
    Tests all components of the upgrade scheduler including:
    - Pre-flight checks
    - Scheduling functionality
    - UI dialogs
    - Scheduled task creation
    - Error handling
.NOTES
    Version:        1.0.0
    Author:         System Administrator
    Creation Date:  2025-01-15
#>
#endregion

#region Test Configuration
param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('All','PreFlight','Scheduler','UI','Integration')]
    [string]$TestType = 'All',
    
    [Parameter(Mandatory=$false)]
    [switch]$Verbose
)

# Set up test environment
$script:TestRoot = Split-Path -Parent $PSScriptRoot
$script:ModulePath = Join-Path -Path $TestRoot -ChildPath 'SupportFiles\Modules'
$script:ResultsPath = Join-Path -Path $PSScriptRoot -ChildPath "Results_$(Get-Date -Format 'yyyyMMdd_HHmmss')"

# Create results directory
New-Item -Path $script:ResultsPath -ItemType Directory -Force | Out-Null

# Import modules
Import-Module "$script:ModulePath\PreFlightChecks.psm1" -Force
Import-Module "$script:ModulePath\UpgradeScheduler.psm1" -Force
#endregion

#region Test Functions
function Write-TestResult {
    param(
        [string]$TestName,
        [bool]$Passed,
        [string]$Message,
        [object]$Details = $null
    )
    
    $result = [PSCustomObject]@{
        Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        TestName = $TestName
        Passed = $Passed
        Message = $Message
        Details = $Details
    }
    
    # Console output
    $color = if ($Passed) { 'Green' } else { 'Red' }
    $status = if ($Passed) { 'PASS' } else { 'FAIL' }
    Write-Host "[$status] $TestName - $Message" -ForegroundColor $color
    
    # Log to file
    $logFile = Join-Path -Path $script:ResultsPath -ChildPath 'TestResults.json'
    $result | ConvertTo-Json -Depth 10 | Add-Content -Path $logFile
    
    return $result
}

function Test-PreFlightChecks {
    Write-Host "`n=== Testing Pre-Flight Checks ===" -ForegroundColor Cyan
    
    $tests = @()
    
    # Test disk space check
    try {
        $diskResult = Test-DiskSpace
        $tests += Write-TestResult -TestName "DiskSpace" `
            -Passed $true `
            -Message "Disk space check completed" `
            -Details $diskResult
    }
    catch {
        $tests += Write-TestResult -TestName "DiskSpace" `
            -Passed $false `
            -Message "Disk space check failed: $_"
    }
    
    # Test battery check
    try {
        $batteryResult = Test-BatteryLevel
        $tests += Write-TestResult -TestName "BatteryLevel" `
            -Passed $true `
            -Message "Battery check completed" `
            -Details $batteryResult
    }
    catch {
        $tests += Write-TestResult -TestName "BatteryLevel" `
            -Passed $false `
            -Message "Battery check failed: $_"
    }
    
    # Test Windows Update check
    try {
        $updateResult = Test-WindowsUpdateStatus
        $tests += Write-TestResult -TestName "WindowsUpdate" `
            -Passed $true `
            -Message "Windows Update check completed" `
            -Details $updateResult
    }
    catch {
        $tests += Write-TestResult -TestName "WindowsUpdate" `
            -Passed $false `
            -Message "Windows Update check failed: $_"
    }
    
    # Test pending reboot check
    try {
        $rebootResult = Test-PendingReboot
        $tests += Write-TestResult -TestName "PendingReboot" `
            -Passed $true `
            -Message "Pending reboot check completed" `
            -Details $rebootResult
    }
    catch {
        $tests += Write-TestResult -TestName "PendingReboot" `
            -Passed $false `
            -Message "Pending reboot check failed: $_"
    }
    
    # Test full system readiness
    try {
        $readinessResult = Test-SystemReadiness -Verbose:$Verbose
        $tests += Write-TestResult -TestName "SystemReadiness" `
            -Passed $true `
            -Message "System readiness check completed" `
            -Details $readinessResult
    }
    catch {
        $tests += Write-TestResult -TestName "SystemReadiness" `
            -Passed $false `
            -Message "System readiness check failed: $_"
    }
    
    return $tests
}

function Test-SchedulerFunctions {
    Write-Host "`n=== Testing Scheduler Functions ===" -ForegroundColor Cyan
    
    $tests = @()
    $testTaskName = 'TestWin11UpgradeTask'
    
    # Test schedule creation
    try {
        # Create test schedule for 3 hours from now
        $testTime = (Get-Date).AddHours(3)
        $testPath = $script:TestRoot
        
        # Temporarily override task name for testing
        $originalTaskName = $script:TaskName
        $script:TaskName = $testTaskName
        
        $schedule = New-UpgradeSchedule -ScheduleTime $testTime -PSADTPath $testPath
        
        $tests += Write-TestResult -TestName "CreateSchedule" `
            -Passed ($null -ne $schedule) `
            -Message "Schedule creation test" `
            -Details @{ScheduleTime = $testTime; TaskState = $schedule.State}
    }
    catch {
        $tests += Write-TestResult -TestName "CreateSchedule" `
            -Passed $false `
            -Message "Schedule creation failed: $_"
    }
    
    # Test schedule retrieval
    try {
        $retrievedSchedule = Get-UpgradeSchedule
        $tests += Write-TestResult -TestName "GetSchedule" `
            -Passed ($null -ne $retrievedSchedule) `
            -Message "Schedule retrieval test" `
            -Details $retrievedSchedule
    }
    catch {
        $tests += Write-TestResult -TestName "GetSchedule" `
            -Passed $false `
            -Message "Schedule retrieval failed: $_"
    }
    
    # Test schedule update
    try {
        $newTime = (Get-Date).AddHours(5)
        Update-UpgradeSchedule -NewScheduleTime $newTime
        
        $updatedSchedule = Get-UpgradeSchedule
        $tests += Write-TestResult -TestName "UpdateSchedule" `
            -Passed ($updatedSchedule.NextRunTime -like "*$($newTime.ToString('HH:mm'))*") `
            -Message "Schedule update test" `
            -Details @{NewTime = $newTime; UpdatedSchedule = $updatedSchedule}
    }
    catch {
        $tests += Write-TestResult -TestName "UpdateSchedule" `
            -Passed $false `
            -Message "Schedule update failed: $_"
    }
    
    # Test quick scheduling
    try {
        # Test "Tomorrow Morning" scheduling
        Remove-UpgradeSchedule -Force
        New-QuickUpgradeSchedule -When Tomorrow -Time Morning -PSADTPath $testPath
        
        $quickSchedule = Get-UpgradeSchedule
        $tests += Write-TestResult -TestName "QuickSchedule" `
            -Passed ($null -ne $quickSchedule) `
            -Message "Quick schedule test (Tomorrow Morning)" `
            -Details $quickSchedule
    }
    catch {
        $tests += Write-TestResult -TestName "QuickSchedule" `
            -Passed $false `
            -Message "Quick schedule failed: $_"
    }
    
    # Test schedule removal
    try {
        Remove-UpgradeSchedule -Force
        $removedSchedule = Get-UpgradeSchedule
        
        $tests += Write-TestResult -TestName "RemoveSchedule" `
            -Passed ($null -eq $removedSchedule) `
            -Message "Schedule removal test"
    }
    catch {
        $tests += Write-TestResult -TestName "RemoveSchedule" `
            -Passed $false `
            -Message "Schedule removal failed: $_"
    }
    finally {
        # Restore original task name
        if ($originalTaskName) {
            $script:TaskName = $originalTaskName
        }
        
        # Clean up test task if it exists
        try {
            Unregister-ScheduledTask -TaskName $testTaskName -Confirm:$false -ErrorAction SilentlyContinue
        }
        catch { }
    }
    
    return $tests
}

function Test-UIDialogs {
    Write-Host "`n=== Testing UI Dialogs ===" -ForegroundColor Cyan
    Write-Host "NOTE: UI tests require manual interaction" -ForegroundColor Yellow
    
    $tests = @()
    
    # Test if UI scripts exist
    $uiScripts = @(
        'Show-UpgradeInformationDialog.ps1'
        'Show-CalendarPicker.ps1'
    )
    
    foreach ($script in $uiScripts) {
        $scriptPath = Join-Path -Path $TestRoot -ChildPath "SupportFiles\$script"
        $exists = Test-Path -Path $scriptPath
        
        $tests += Write-TestResult -TestName "UIScript_$script" `
            -Passed $exists `
            -Message "UI script existence check" `
            -Details @{Path = $scriptPath; Exists = $exists}
    }
    
    # Optional: Test UI if requested
    if ($Verbose) {
        Write-Host "`nWould you like to test the UI dialogs? (Y/N): " -NoNewline
        $response = Read-Host
        
        if ($response -eq 'Y') {
            # Load UI scripts
            . "$TestRoot\SupportFiles\Show-UpgradeInformationDialog.ps1"
            . "$TestRoot\SupportFiles\Show-CalendarPicker.ps1"
            
            # Test information dialog
            try {
                Write-Host "Testing Information Dialog..." -ForegroundColor Green
                $infoResult = Show-UpgradeInformationDialog -OrganizationName "Test Corp" -DeadlineDays 7
                
                $tests += Write-TestResult -TestName "InfoDialog" `
                    -Passed $true `
                    -Message "Information dialog test completed" `
                    -Details @{Result = $infoResult}
            }
            catch {
                $tests += Write-TestResult -TestName "InfoDialog" `
                    -Passed $false `
                    -Message "Information dialog failed: $_"
            }
            
            # Test calendar picker
            try {
                Write-Host "Testing Calendar Picker..." -ForegroundColor Green
                $calendarResult = Show-CalendarPicker
                
                $tests += Write-TestResult -TestName "CalendarPicker" `
                    -Passed $true `
                    -Message "Calendar picker test completed" `
                    -Details @{Result = $calendarResult}
            }
            catch {
                $tests += Write-TestResult -TestName "CalendarPicker" `
                    -Passed $false `
                    -Message "Calendar picker failed: $_"
            }
        }
    }
    
    return $tests
}

function Test-Integration {
    Write-Host "`n=== Testing Integration ===" -ForegroundColor Cyan
    
    $tests = @()
    
    # Test wrapper script
    $wrapperPath = Join-Path -Path $TestRoot -ChildPath 'SupportFiles\ScheduledTaskWrapper.ps1'
    if (Test-Path -Path $wrapperPath) {
        # Test wrapper script syntax
        try {
            $null = [System.Management.Automation.Language.Parser]::ParseFile($wrapperPath, [ref]$null, [ref]$null)
            $tests += Write-TestResult -TestName "WrapperScriptSyntax" `
                -Passed $true `
                -Message "Wrapper script syntax is valid"
        }
        catch {
            $tests += Write-TestResult -TestName "WrapperScriptSyntax" `
                -Passed $false `
                -Message "Wrapper script syntax error: $_"
        }
    }
    
    # Test Deploy-Application.ps1
    $deployPath = Join-Path -Path $TestRoot -ChildPath 'Deploy-Application.ps1'
    if (Test-Path -Path $deployPath) {
        # Test deploy script syntax
        try {
            $null = [System.Management.Automation.Language.Parser]::ParseFile($deployPath, [ref]$null, [ref]$null)
            $tests += Write-TestResult -TestName "DeployScriptSyntax" `
                -Passed $true `
                -Message "Deploy script syntax is valid"
        }
        catch {
            $tests += Write-TestResult -TestName "DeployScriptSyntax" `
                -Passed $false `
                -Message "Deploy script syntax error: $_"
        }
    }
    
    # Test logging functionality
    try {
        Write-SchedulerLog -Message "Integration test log entry" -Severity Information
        Write-PreFlightLog -Message "Pre-flight test log entry" -Severity Information
        
        $tests += Write-TestResult -TestName "LoggingFunctions" `
            -Passed $true `
            -Message "Logging functions working"
    }
    catch {
        $tests += Write-TestResult -TestName "LoggingFunctions" `
            -Passed $false `
            -Message "Logging functions failed: $_"
    }
    
    return $tests
}
#endregion

#region Main Test Execution
Write-Host "Windows 11 Upgrade Scheduler Test Suite" -ForegroundColor White -BackgroundColor DarkBlue
Write-Host "Test Type: $TestType" -ForegroundColor Yellow
Write-Host "Results Path: $script:ResultsPath" -ForegroundColor Yellow
Write-Host ("=" * 60) -ForegroundColor Gray

$allTests = @()

switch ($TestType) {
    'All' {
        $allTests += Test-PreFlightChecks
        $allTests += Test-SchedulerFunctions
        $allTests += Test-UIDialogs
        $allTests += Test-Integration
    }
    'PreFlight' {
        $allTests += Test-PreFlightChecks
    }
    'Scheduler' {
        $allTests += Test-SchedulerFunctions
    }
    'UI' {
        $allTests += Test-UIDialogs
    }
    'Integration' {
        $allTests += Test-Integration
    }
}

# Summary
Write-Host "`n=== Test Summary ===" -ForegroundColor Cyan
$passed = ($allTests | Where-Object { $_.Passed }).Count
$failed = ($allTests | Where-Object { -not $_.Passed }).Count
$total = $allTests.Count

Write-Host "Total Tests: $total" -ForegroundColor White
Write-Host "Passed: $passed" -ForegroundColor Green
Write-Host "Failed: $failed" -ForegroundColor Red

# Save summary
$summary = @{
    TestRun = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    TestType = $TestType
    TotalTests = $total
    Passed = $passed
    Failed = $failed
    SuccessRate = if ($total -gt 0) { [math]::Round(($passed / $total) * 100, 2) } else { 0 }
}

$summaryFile = Join-Path -Path $script:ResultsPath -ChildPath 'Summary.json'
$summary | ConvertTo-Json | Set-Content -Path $summaryFile

Write-Host "`nTest results saved to: $script:ResultsPath" -ForegroundColor Yellow
#endregion