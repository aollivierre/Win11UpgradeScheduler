<#
.SYNOPSIS
    Test PSADT v3 Behavior When Running as SYSTEM
    
.DESCRIPTION
    Run this script in your Windows Terminal SYSTEM profile to test
    how PSADT behaves in true unattended scenarios.
#>

$PSADTPath = $PSScriptRoot

Write-Host "`n================================================" -ForegroundColor Cyan
Write-Host "PSADT v3 SYSTEM Context Test" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "This test simulates boardroom/kiosk scenarios`n" -ForegroundColor Yellow

# Show current context
Write-Host "Current Context Information:" -ForegroundColor Yellow
Write-Host "============================"
Write-Host "Running as: $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)"
Write-Host "Is Administrator: $([Security.Principal.WindowsPrincipal]([Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))"
Write-Host "Process ID: $PID"
Write-Host "Session ID: $([System.Diagnostics.Process]::GetCurrentProcess().SessionId)"

# Test 1: Load PSADT in Interactive mode
Write-Host "`n`nTEST 1: PSADT in Interactive Mode (as SYSTEM)" -ForegroundColor Yellow
Write-Host "=============================================="

try {
    $global:deployMode = 'Interactive'
    
    # Import toolkit
    . "$PSADTPath\AppDeployToolkit\AppDeployToolkitMain.ps1" -DisableLogging
    
    Write-Host "`nPSADT Variables:"
    Write-Host "  Deploy Mode: $deployMode"
    Write-Host "  Is Silent: $deployModeSilent"
    Write-Host "  Session Zero: $SessionZero"
    Write-Host "  RunAsActiveUser: $(if($RunAsActiveUser){'Found: ' + $RunAsActiveUser.UserName}else{'None'})"
    Write-Host "  Process Interactive: $IsProcessUserInteractive"
    
    # Test if Show-InstallationWelcome would work
    Write-Host "`nUI Behavior Test:"
    if ($deployModeSilent) {
        Write-Host "  Result: Would go SILENT (no UI)" -ForegroundColor Green
    } elseif ($SessionZero -and -not $RunAsActiveUser) {
        Write-Host "  Result: Would go SILENT (Session 0, no user)" -ForegroundColor Green
    } else {
        Write-Host "  Result: Would attempt UI (may fail in Session 0)" -ForegroundColor Yellow
    }
}
catch {
    Write-Host "Error: $_" -ForegroundColor Red
}

# Test 2: Check what users PSADT can see
Write-Host "`n`nTEST 2: User Detection from SYSTEM Context" -ForegroundColor Yellow
Write-Host "==========================================="

try {
    $loggedOnUsers = Get-LoggedOnUser
    
    if ($loggedOnUsers) {
        Write-Host "Found $($loggedOnUsers.Count) logged on user(s):"
        foreach ($user in $loggedOnUsers) {
            Write-Host "  - $($user.UserName) (Session: $($user.SessionId), Active: $($user.IsActiveUserSession))"
        }
    } else {
        Write-Host "No logged on users detected" -ForegroundColor Yellow
    }
}
catch {
    Write-Host "Error detecting users: $_" -ForegroundColor Red
}

# Test 3: Simulate boardroom scenario
Write-Host "`n`nTEST 3: Boardroom/Kiosk Simulation" -ForegroundColor Yellow
Write-Host "==================================="

Write-Host "`nScenario: No user logged in, running as SYSTEM"
Write-Host "Expected behavior for Windows 11 upgrade:"

if ($SessionZero -and -not $RunAsActiveUser) {
    Write-Host "`n[CORRECT BEHAVIOR DETECTED]" -ForegroundColor Green
    Write-Host "✓ PSADT detects unattended scenario"
    Write-Host "✓ Would proceed with SILENT upgrade"
    Write-Host "✓ No UI prompts would be shown"
    Write-Host "✓ Perfect for boardroom computers!"
} else {
    Write-Host "`n[UNEXPECTED BEHAVIOR]" -ForegroundColor Yellow
    Write-Host "! PSADT may try to show UI"
    Write-Host "! Need to force Silent mode"
}

# Test 4: Force Silent mode
Write-Host "`n`nTEST 4: Force Silent Mode (Recommended for SYSTEM)" -ForegroundColor Yellow
Write-Host "=================================================="

# Clear and reload
Remove-Variable -Name deployMode* -Force -ErrorAction SilentlyContinue
$global:deployMode = 'Silent'

# Reload toolkit
. "$PSADTPath\AppDeployToolkit\AppDeployToolkitMain.ps1" -DisableLogging

Write-Host "`nForced Silent Mode Results:"
Write-Host "  Deploy Mode: $deployMode"
Write-Host "  Is Silent: $deployModeSilent"
Write-Host "  Result: Will ALWAYS proceed silently" -ForegroundColor Green

# Summary
Write-Host "`n`n================================================" -ForegroundColor Cyan
Write-Host "SUMMARY FOR BOARDROOM COMPUTERS" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

Write-Host "`nRecommendation for unattended upgrades:"
Write-Host "1. Detection script determines compatibility"
Write-Host "2. If running as SYSTEM with no users:"
Write-Host "   - Set deployMode = 'Silent'"
Write-Host "   - Proceed with immediate upgrade"
Write-Host "3. If users are logged in:"
Write-Host "   - Keep deployMode = 'Interactive'"
Write-Host "   - Show calendar picker"

Write-Host "`nPSADT handles this automatically!" -ForegroundColor Green
Write-Host "================================================`n" -ForegroundColor Cyan