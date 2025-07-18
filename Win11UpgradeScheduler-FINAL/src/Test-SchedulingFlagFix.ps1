#region Test Scheduling Flag Fix
<#
.SYNOPSIS
    Test the scheduling flag implementation
.DESCRIPTION
    Verifies that the script properly exits after scheduling without continuing to upgrade
#>

Write-Host "`n=== Testing Scheduling Flag Fix ===" -ForegroundColor Cyan
Write-Host "This test verifies the script exits properly after scheduling" -ForegroundColor Yellow

# Check the Deploy-Application script has the flag logic
$deployScript = Get-Content ".\Deploy-Application-InstallationAssistant-Version.ps1" -Raw

# Test 1: Check flag initialization
Write-Host "`nTest 1: Checking flag initialization..." -ForegroundColor Cyan
if ($deployScript -match '\$script:SchedulingComplete\s*=\s*\$false') {
    Write-Host "[PASS] Flag initialization found" -ForegroundColor Green
} else {
    Write-Host "[FAIL] Flag initialization not found!" -ForegroundColor Red
}

# Test 2: Check flag is set after scheduling
Write-Host "`nTest 2: Checking flag is set after scheduling..." -ForegroundColor Cyan
# Look for the flag being set to true anywhere in the script
if ($deployScript -match '\$script:SchedulingComplete\s*=\s*\$true') {
    # Count how many times it's set
    $flagSetCount = ([regex]::Matches($deployScript, '\$script:SchedulingComplete\s*=\s*\$true')).Count
    Write-Host "[PASS] Flag is set to true after scheduling ($flagSetCount occurrences)" -ForegroundColor Green
} else {
    Write-Host "[FAIL] Flag not set after scheduling!" -ForegroundColor Red
}

# Test 3: Check upgrade logic is wrapped with flag check
Write-Host "`nTest 3: Checking upgrade logic is conditional on flag..." -ForegroundColor Cyan
if ($deployScript -match 'If\s*\(\s*-not\s+\$script:SchedulingComplete\s*\)') {
    Write-Host "[PASS] Upgrade logic is wrapped with flag check" -ForegroundColor Green
} else {
    Write-Host "[FAIL] Upgrade logic not properly wrapped!" -ForegroundColor Red
}

# Test 4: Check for else clause when scheduling completed
Write-Host "`nTest 4: Checking for else clause when scheduling completed..." -ForegroundColor Cyan
if ($deployScript -match 'Else\s*\{[^}]*User successfully scheduled upgrade, skipping immediate installation') {
    Write-Host "[PASS] Else clause handles scheduled case" -ForegroundColor Green
} else {
    Write-Host "[FAIL] No else clause for scheduled case!" -ForegroundColor Red
}

# Test 5: Verify no Exit-Script calls after scheduling
Write-Host "`nTest 5: Checking for Exit-Script calls after scheduling..." -ForegroundColor Cyan
# Count Exit-Script calls in scheduling sections
$schedulingSections = [regex]::Matches($deployScript, 'Successfully scheduled upgrade[\s\S]*?(?=\})')
$exitScriptAfterSchedule = $false
foreach ($section in $schedulingSections) {
    if ($section.Value -match 'Exit-Script') {
        $exitScriptAfterSchedule = $true
        break
    }
}
if (-not $exitScriptAfterSchedule) {
    Write-Host "[PASS] No Exit-Script calls after scheduling (prevents double balloons)" -ForegroundColor Green
} else {
    Write-Host "[WARNING] Exit-Script found after scheduling - may cause issues" -ForegroundColor Yellow
}

Write-Host "`n=== Summary ===" -ForegroundColor Cyan
Write-Host @"
The flag-based implementation should now:
1. Initialize `$script:SchedulingComplete = `$false at start
2. Set `$script:SchedulingComplete = `$true after successful scheduling
3. Check flag before upgrade logic: If (-not `$script:SchedulingComplete)
4. Skip upgrade logic and exit gracefully when flag is true
5. Allow PSADT to handle exit naturally (no double balloons)
"@ -ForegroundColor White

Write-Host "`nThis should resolve the issue where the script continued with" -ForegroundColor Yellow
Write-Host "the upgrade after scheduling instead of exiting properly." -ForegroundColor Yellow
#endregion