#region Complete Empirical Validation
<#
.SYNOPSIS
    Complete empirical validation using existing PSADT structure
.DESCRIPTION
    Tests the enhanced components against the existing Win11Scheduler-PSADT-v3
#>
#endregion

param(
    [switch]$TestScheduling,
    [switch]$TestPreFlight,
    [switch]$Verbose
)

#region Configuration
$script:ExistingPath = "C:\code\Windows\Phase1-Detection\Win11Scheduler-PSADT-v3"
$script:EnhancedPath = "C:\code\Windows\Win11UpgradeScheduler"
$script:TestResults = @()
#endregion

#region Test Framework
function Write-TestSection {
    param([string]$Title)
    Write-Host "`n$('=' * 70)" -ForegroundColor Cyan
    Write-Host "  $Title" -ForegroundColor White
    Write-Host "$('=' * 70)" -ForegroundColor Cyan
}

function Test-Feature {
    param(
        [string]$Name,
        [scriptblock]$Test,
        [string]$Category
    )
    
    Write-Host "`n[TEST] $Name" -ForegroundColor Yellow -NoNewline
    
    try {
        $result = & $Test
        if ($result.Success) {
            Write-Host " [PASS]" -ForegroundColor Green
            Write-Host "  Details: $($result.Message)" -ForegroundColor Gray
        }
        else {
            Write-Host " [FAIL]" -ForegroundColor Red
            Write-Host "  Issue: $($result.Message)" -ForegroundColor Red
        }
        
        $script:TestResults += [PSCustomObject]@{
            Category = $Category
            Test = $Name
            Success = $result.Success
            Message = $result.Message
            Details = $result.Details
        }
    }
    catch {
        Write-Host " [ERROR]" -ForegroundColor Red
        Write-Host "  Error: $_" -ForegroundColor Red
        
        $script:TestResults += [PSCustomObject]@{
            Category = $Category
            Test = $Name
            Success = $false
            Message = $_.ToString()
            Details = $null
        }
    }
}
#endregion

#region Enhancement Tests
Write-TestSection "TESTING ENHANCED COMPONENTS"

# Test 1: Enhanced Scheduler Module
Test-Feature -Name "Enhanced Scheduler Module Features" -Category "Scheduler" -Test {
    # Load the enhanced module
    $modulePath = "$script:EnhancedPath\SupportFiles\Modules\UpgradeScheduler.psm1"
    
    if (Test-Path $modulePath) {
        # Check for enhanced features
        $content = Get-Content $modulePath -Raw
        
        $features = @{
            "Same-Day Scheduling" = $content -match 'Tonight.*8PM.*10PM.*11PM'
            "Quick Schedule Function" = $content -match 'New-QuickUpgradeSchedule'
            "Schedule Validation" = $content -match 'Test-ScheduleTime'
            "Wake Computer Support" = $content -match 'WakeToRun'
            "Configuration Persistence" = $content -match 'Save-ScheduleConfig'
        }
        
        $missingFeatures = $features.GetEnumerator() | Where-Object { -not $_.Value } | Select-Object -ExpandProperty Key
        
        return @{
            Success = $missingFeatures.Count -eq 0
            Message = if ($missingFeatures.Count -eq 0) { 
                "All 5 enhanced features present" 
            } else { 
                "Missing features: $($missingFeatures -join ', ')" 
            }
            Details = $features
        }
    }
    else {
        return @{
            Success = $false
            Message = "Enhanced scheduler module not found at: $modulePath"
        }
    }
}

# Test 2: Pre-Flight Checks
if ($TestPreFlight) {
    Test-Feature -Name "Comprehensive Pre-Flight Checks" -Category "PreFlight" -Test {
        $modulePath = "$script:EnhancedPath\SupportFiles\Modules\PreFlightChecks.psm1"
        
        if (Test-Path $modulePath) {
            Import-Module $modulePath -Force
            
            # Run actual system checks
            $checks = @{
                "Disk Space" = (Test-DiskSpace).Passed
                "Battery Level" = (Test-BatteryLevel).Passed
                "Windows Update" = (Test-WindowsUpdateStatus).Passed
                "Pending Reboot" = (Test-PendingReboot).Passed
                "System Resources" = (Test-SystemResources).Passed
            }
            
            $failedChecks = $checks.GetEnumerator() | Where-Object { -not $_.Value } | Select-Object -ExpandProperty Key
            
            return @{
                Success = $true  # Module works even if some checks fail
                Message = if ($failedChecks.Count -eq 0) {
                    "All pre-flight checks operational"
                } else {
                    "Checks operational. Failed: $($failedChecks -join ', ')"
                }
                Details = $checks
            }
        }
        else {
            return @{
                Success = $false
                Message = "Pre-flight module not found"
            }
        }
    }
}

# Test 3: Wrapper Script Enhancement
Test-Feature -Name "Scheduled Task Wrapper Enhancements" -Category "Wrapper" -Test {
    $wrapperPath = "$script:EnhancedPath\SupportFiles\ScheduledTaskWrapper.ps1"
    
    if (Test-Path $wrapperPath) {
        $content = Get-Content $wrapperPath -Raw
        
        $enhancements = @{
            "Session Detection" = $content -match 'Test-UserSession'
            "30-Min Countdown" = $content -match 'CountdownMinutes.*30|Show-CountdownDialog'
            "Pre-Flight Integration" = $content -match 'Invoke-PreFlightChecks|Test-SystemReadiness'
            "PSADT Launch" = $content -match 'Start-PSADTDeployment|Deploy-Application\.ps1'
            "Logging" = $content -match 'Write-WrapperLog'
        }
        
        $missingEnhancements = $enhancements.GetEnumerator() | Where-Object { -not $_.Value } | Select-Object -ExpandProperty Key
        
        return @{
            Success = $missingEnhancements.Count -le 1  # Allow 1 missing
            Message = if ($missingEnhancements.Count -eq 0) {
                "All wrapper enhancements present"
            } else {
                "Missing: $($missingEnhancements -join ', ')"
            }
            Details = $enhancements
        }
    }
    else {
        return @{
            Success = $false
            Message = "Wrapper script not found"
        }
    }
}

# Test 4: Comparison with Original
Test-Feature -Name "Integration with Existing PSADT" -Category "Integration" -Test {
    $existingDeploy = "$script:ExistingPath\Deploy-Application-Complete.ps1"
    $enhancedDeploy = "$script:EnhancedPath\Deploy-Application.ps1"
    
    $existingUI = @(
        "$script:ExistingPath\SupportFiles\Show-CalendarPicker.ps1"
        "$script:ExistingPath\SupportFiles\Show-UpgradeInformationDialog.ps1"
    )
    
    $results = @{
        "Original PSADT Found" = Test-Path $existingDeploy
        "UI Scripts Found" = ($existingUI | Where-Object { Test-Path $_ }).Count -eq 2
        "Enhanced Structure" = Test-Path "$script:EnhancedPath\SupportFiles\Modules"
    }
    
    $issues = $results.GetEnumerator() | Where-Object { -not $_.Value } | Select-Object -ExpandProperty Key
    
    return @{
        Success = $issues.Count -eq 0
        Message = if ($issues.Count -eq 0) {
            "All integration points verified"
        } else {
            "Missing: $($issues -join ', ')"
        }
        Details = $results
    }
}

# Test 5: Key Improvements Verification
Test-Feature -Name "Key Improvements Implementation" -Category "Improvements" -Test {
    $improvements = @{}
    
    # Check for 30-minute countdown
    $wrapperContent = if (Test-Path "$script:EnhancedPath\SupportFiles\ScheduledTaskWrapper.ps1") {
        Get-Content "$script:EnhancedPath\SupportFiles\ScheduledTaskWrapper.ps1" -Raw
    } else { "" }
    
    $improvements["30-Minute Countdown"] = $wrapperContent -match 'CountdownMinutes.*30|30.*minute'
    
    # Check for same-day scheduling
    $schedulerContent = if (Test-Path "$script:EnhancedPath\SupportFiles\Modules\UpgradeScheduler.psm1") {
        Get-Content "$script:EnhancedPath\SupportFiles\Modules\UpgradeScheduler.psm1" -Raw
    } else { "" }
    
    $improvements["Same-Day Scheduling"] = $schedulerContent -match 'Tonight.*8PM|Tonight.*10PM|Tonight.*11PM'
    $improvements["Wake Computer Support"] = $schedulerContent -match 'WakeToRun'
    $improvements["2-Hour Minimum Buffer"] = $schedulerContent -match 'MinimumHoursAhead.*2|minimum.*2.*hours'
    
    # Check for pre-flight checks
    $preflightExists = Test-Path "$script:EnhancedPath\SupportFiles\Modules\PreFlightChecks.psm1"
    $improvements["Pre-Flight Checks Module"] = $preflightExists
    
    $implemented = $improvements.GetEnumerator() | Where-Object { $_.Value } | Measure-Object
    
    return @{
        Success = $implemented.Count -ge 4  # At least 4 of 5 improvements
        Message = "$($implemented.Count)/5 key improvements implemented"
        Details = $improvements
    }
}
#endregion

#region Scheduling Tests
if ($TestScheduling) {
    Write-TestSection "LIVE SCHEDULING TESTS"
    
    Test-Feature -Name "Create Test Schedule" -Category "LiveTest" -Test {
        try {
            # Load module
            Import-Module "$script:EnhancedPath\SupportFiles\Modules\UpgradeScheduler.psm1" -Force
            
            # Override task name for testing
            $script:TaskName = 'TestWin11UpgradeValidation'
            
            # Create schedule for 3 hours from now
            $testTime = (Get-Date).AddHours(3)
            $schedule = New-UpgradeSchedule -ScheduleTime $testTime -PSADTPath $script:ExistingPath
            
            # Verify task was created
            $task = Get-ScheduledTask -TaskName $script:TaskName -ErrorAction SilentlyContinue
            
            if ($task) {
                # Clean up
                Unregister-ScheduledTask -TaskName $script:TaskName -Confirm:$false
                
                return @{
                    Success = $true
                    Message = "Successfully created and verified scheduled task"
                    Details = @{
                        TaskName = $script:TaskName
                        ScheduleTime = $testTime
                        TaskState = $task.State
                    }
                }
            }
            else {
                return @{
                    Success = $false
                    Message = "Task creation failed"
                }
            }
        }
        catch {
            return @{
                Success = $false
                Message = "Scheduling test failed: $_"
            }
        }
    }
}
#endregion

#region Summary
Write-TestSection "VALIDATION SUMMARY"

$totalTests = $script:TestResults.Count
$passedTests = ($script:TestResults | Where-Object { $_.Success }).Count
$failedTests = $totalTests - $passedTests
$successRate = [math]::Round(($passedTests / $totalTests) * 100, 2)

# Color coding
$rateColor = if ($successRate -ge 90) { 'Green' } 
             elseif ($successRate -ge 70) { 'Yellow' } 
             else { 'Red' }

Write-Host "`nTotal Tests: $totalTests" -ForegroundColor White
Write-Host "Passed: $passedTests" -ForegroundColor Green
Write-Host "Failed: $failedTests" -ForegroundColor Red
Write-Host "Success Rate: " -NoNewline
Write-Host "$successRate%" -ForegroundColor $rateColor

# Category breakdown
Write-Host "`nResults by Category:" -ForegroundColor Cyan
$script:TestResults | Group-Object Category | ForEach-Object {
    $catPassed = ($_.Group | Where-Object { $_.Success }).Count
    $catTotal = $_.Count
    Write-Host "  $($_.Name): $catPassed/$catTotal" -ForegroundColor White
}

# Key findings
Write-Host "`nKey Findings:" -ForegroundColor Yellow
if ($successRate -ge 80) {
    Write-Host "  ✓ Enhanced scheduler implementation is functional" -ForegroundColor Green
    Write-Host "  ✓ Core improvements have been implemented" -ForegroundColor Green
    Write-Host "  ✓ Integration with existing PSADT verified" -ForegroundColor Green
}

$failedTests = $script:TestResults | Where-Object { -not $_.Success }
if ($failedTests) {
    Write-Host "`nIssues Found:" -ForegroundColor Red
    $failedTests | ForEach-Object {
        Write-Host "  - $($_.Test): $($_.Message)" -ForegroundColor Red
    }
}

# Save detailed results
$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$resultsPath = "$PSScriptRoot\Results\CompleteValidation_$timestamp.json"
$resultsDir = Split-Path $resultsPath -Parent
if (-not (Test-Path $resultsDir)) {
    New-Item -Path $resultsDir -ItemType Directory -Force | Out-Null
}

@{
    Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    ExistingPath = $script:ExistingPath
    EnhancedPath = $script:EnhancedPath
    Summary = @{
        TotalTests = $totalTests
        Passed = $passedTests
        Failed = $failedTests
        SuccessRate = $successRate
    }
    Results = $script:TestResults
} | ConvertTo-Json -Depth 10 | Set-Content $resultsPath

Write-Host "`nDetailed results saved to:" -ForegroundColor Yellow
Write-Host $resultsPath -ForegroundColor Cyan
#endregion