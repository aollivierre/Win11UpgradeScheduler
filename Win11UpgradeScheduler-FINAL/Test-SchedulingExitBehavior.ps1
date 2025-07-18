#region Test Scheduling Exit Behavior
<#
.SYNOPSIS
    Test to verify script exits after scheduling without running upgrade
.DESCRIPTION
    This test helps verify the fix for the issue where the script continues
    with the upgrade after the user schedules it for later
#>

param(
    [string]$DeployScriptPath = ".\src\Deploy-Application-InstallationAssistant-Version.ps1"
)

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Testing Scheduling Exit Behavior" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

if (-not (Test-Path $DeployScriptPath)) {
    Write-Host "[ERROR] Deploy script not found at: $DeployScriptPath" -ForegroundColor Red
    exit 1
}

# Read the script content
$scriptContent = Get-Content $DeployScriptPath -Raw

# Test 1: Check if Installation region is inside the conditional
Write-Host "`n[TEST 1] Checking if Installation region is inside scheduling conditional..." -ForegroundColor Yellow

# Find the scheduling conditional
$conditionalPattern = 'If\s*\(\s*-not\s+\$script:SchedulingComplete\s*\)\s*\{'
$conditionalMatch = [regex]::Match($scriptContent, $conditionalPattern)

if ($conditionalMatch.Success) {
    $conditionalStart = $conditionalMatch.Index
    Write-Host "Found scheduling conditional at character position: $conditionalStart" -ForegroundColor Gray
    
    # Find the Installation region
    $installationPattern = '#region\s+Installation'
    $installationMatch = [regex]::Match($scriptContent, $installationPattern)
    
    if ($installationMatch.Success) {
        $installationStart = $installationMatch.Index
        Write-Host "Found Installation region at character position: $installationStart" -ForegroundColor Gray
        
        # Check if Installation region is after the conditional start
        if ($installationStart > $conditionalStart) {
            # Now we need to check if it's INSIDE the conditional block
            # This is complex without proper parsing, so we'll do a simple check
            
            # Count braces between conditional and installation
            $betweenText = $scriptContent.Substring($conditionalStart, $installationStart - $conditionalStart)
            $openBraces = ([regex]::Matches($betweenText, '\{')).Count
            $closeBraces = ([regex]::Matches($betweenText, '\}')).Count
            $braceBalance = $openBraces - $closeBraces
            
            Write-Host "Brace balance between conditional and Installation: $braceBalance" -ForegroundColor Gray
            
            if ($braceBalance -gt 0) {
                Write-Host "[PASS] Installation region appears to be inside the conditional block" -ForegroundColor Green
            } else {
                Write-Host "[FAIL] Installation region is OUTSIDE the conditional block!" -ForegroundColor Red
                Write-Host "  The conditional block closes before the Installation region begins." -ForegroundColor Red
                Write-Host "  This causes the upgrade to run even when scheduling is complete!" -ForegroundColor Red
            }
        } else {
            Write-Host "[CONFIGURATION] Installation region appears before this specific conditional" -ForegroundColor Yellow
            Write-Host "  This might mean there are multiple conditionals or the structure is complex" -ForegroundColor Yellow
        }
    } else {
        Write-Host "[ERROR] Could not find Installation region!" -ForegroundColor Red
    }
} else {
    Write-Host "[ERROR] Could not find scheduling conditional!" -ForegroundColor Red
}

# Test 2: Check for the Else clause
Write-Host "`n[TEST 2] Checking for Else clause after scheduling conditional..." -ForegroundColor Yellow

# Look for the else clause that should handle when scheduling is complete
$elsePattern = 'Else\s*\{[^}]*scheduled upgrade, skipping immediate installation'
if ($scriptContent -match $elsePattern) {
    Write-Host "[PASS] Found Else clause for handling scheduled case" -ForegroundColor Green
} else {
    Write-Host "[WARNING] No Else clause found for scheduled case" -ForegroundColor Yellow
}

# Test 3: Check critical log messages
Write-Host "`n[TEST 3] Checking for critical log messages..." -ForegroundColor Yellow

$criticalMessages = @(
    @{
        Name = "Starting upgrade message"
        Pattern = 'Write-Log[^"]*"Starting Windows 11 upgrade process"'
        ShouldBeInsideConditional = $true
    },
    @{
        Name = "Scheduling complete message"
        Pattern = 'Write-Log[^"]*"Successfully scheduled upgrade"'
        ShouldBeInsideConditional = $false
    }
)

foreach ($msg in $criticalMessages) {
    Write-Host "  Checking: $($msg.Name)" -ForegroundColor Gray
    if ($scriptContent -match $msg.Pattern) {
        Write-Host "  [FOUND] $($msg.Name)" -ForegroundColor Green
    } else {
        Write-Host "  [MISSING] $($msg.Name)" -ForegroundColor Yellow
    }
}

# Summary
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "SUMMARY" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host @"
The script should have this structure:

If (-not `$script:SchedulingComplete) {
    # ALL upgrade logic here, including:
    # - Pre-flight checks
    # - Installation region
    # - Post-Installation region
}
Else {
    # Log that scheduling was done
    # Let PSADT exit naturally
}

If the Installation region is OUTSIDE the conditional,
the upgrade will run regardless of the scheduling flag!
"@ -ForegroundColor White

Write-Host "`nTo test the actual behavior:" -ForegroundColor Yellow
Write-Host "1. Run the deployment script" -ForegroundColor White
Write-Host "2. Choose 'Schedule'" -ForegroundColor White
Write-Host "3. Select any future time" -ForegroundColor White
Write-Host "4. Watch the logs - you should NOT see:" -ForegroundColor White
Write-Host "   - 'Starting Windows 11 upgrade process'" -ForegroundColor Red
Write-Host "   - 'Installation started' balloon" -ForegroundColor Red
Write-Host "   - Any upgrade activity" -ForegroundColor Red
Write-Host "`nYou SHOULD only see:" -ForegroundColor White
Write-Host "   - 'Successfully scheduled upgrade'" -ForegroundColor Green
Write-Host "   - Confirmation dialog with scheduled time" -ForegroundColor Green
Write-Host "   - Clean exit" -ForegroundColor Green

#endregion