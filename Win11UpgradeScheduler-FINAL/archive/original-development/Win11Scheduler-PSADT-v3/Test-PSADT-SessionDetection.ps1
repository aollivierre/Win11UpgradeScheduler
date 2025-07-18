<#
.SYNOPSIS
    Test PSADT v3 Session Detection Capabilities
    
.DESCRIPTION
    This script tests PSADT v3's built-in session detection to verify:
    1. Does it detect logged-in users?
    2. Does it detect attended vs unattended sessions?
    3. Does it automatically go silent when no user is present?
    4. How does it behave in different contexts (SYSTEM, User, etc.)?
#>

# Get the PSADT root path
$PSADTPath = $PSScriptRoot

# Import PSADT modules
try {
    Write-Host "`n================================" -ForegroundColor Cyan
    Write-Host "PSADT v3 Session Detection Test" -ForegroundColor Cyan
    Write-Host "================================`n" -ForegroundColor Cyan
    
    # Import the toolkit
    Write-Host "Loading PSADT modules..." -ForegroundColor Yellow
    . "$PSADTPath\AppDeployToolkit\AppDeployToolkitMain.ps1" -DisableLogging
    
    Write-Host "PSADT loaded successfully`n" -ForegroundColor Green
}
catch {
    Write-Host "Failed to load PSADT: $_" -ForegroundColor Red
    exit 1
}

# Test 1: Check session detection variables
Write-Host "TEST 1: Session Detection Variables" -ForegroundColor Yellow
Write-Host "===================================" -ForegroundColor Yellow

Write-Host "`n1. Current Process Context:"
Write-Host "   Running as: $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)"
Write-Host "   Is Admin: $($IsAdmin)"
Write-Host "   Is SYSTEM: $($IsLocalSystemAccount)"
Write-Host "   Is Service Account: $($IsServiceAccount)"
Write-Host "   Session Zero: $($SessionZero)"

Write-Host "`n2. User Session Detection:"
Write-Host "   Process is User Interactive: $($IsProcessUserInteractive)"
Write-Host "   Environment User Interactive: $([Environment]::UserInteractive)"

# Test 2: Get logged on users
Write-Host "`n`nTEST 2: Logged On User Detection" -ForegroundColor Yellow
Write-Host "=================================" -ForegroundColor Yellow

try {
    $loggedOnUsers = Get-LoggedOnUser
    
    if ($loggedOnUsers) {
        Write-Host "`nLogged on users found: $($loggedOnUsers.Count)"
        
        foreach ($user in $loggedOnUsers) {
            Write-Host "`n   User: $($user.UserName)"
            Write-Host "   Domain: $($user.DomainName)"
            Write-Host "   Session ID: $($user.SessionId)"
            Write-Host "   Session Name: $($user.SessionName)"
            Write-Host "   Is Console Session: $($user.IsConsoleSession)"
            Write-Host "   Is Active Session: $($user.IsActiveUserSession)"
            Write-Host "   Is Current Session: $($user.IsCurrentSession)"
            Write-Host "   Is RDP Session: $($user.IsRdpSession)"
            Write-Host "   Logon Time: $($user.LogonTime)"
            Write-Host "   Idle Time: $($user.IdleTime)"
        }
    }
    else {
        Write-Host "`nNo logged on users detected"
    }
}
catch {
    Write-Host "Error getting logged on users: $_" -ForegroundColor Red
}

# Test 3: Check RunAsActiveUser
Write-Host "`n`nTEST 3: Active User Detection" -ForegroundColor Yellow
Write-Host "=============================" -ForegroundColor Yellow

if ($RunAsActiveUser) {
    Write-Host "`nActive user detected for RunAsActiveUser:"
    Write-Host "   UserName: $($RunAsActiveUser.UserName)"
    Write-Host "   Domain: $($RunAsActiveUser.DomainName)"
    Write-Host "   Session ID: $($RunAsActiveUser.SessionId)"
    Write-Host "   Is Console: $($RunAsActiveUser.IsConsoleSession)"
    Write-Host "   NTAccount: $($RunAsActiveUser.NTAccount)"
}
else {
    Write-Host "`nNo active user detected for RunAsActiveUser"
}

# Test 4: Test deployment mode behavior
Write-Host "`n`nTEST 4: Deployment Mode Behavior" -ForegroundColor Yellow
Write-Host "================================" -ForegroundColor Yellow

Write-Host "`nCurrent deployment mode: $deployMode"
Write-Host "Is Silent: $deployModeSilent"
Write-Host "Is NonInteractive: $deployModeNonInteractive"

# Test 5: Test UI function behavior
Write-Host "`n`nTEST 5: UI Function Behavior Test" -ForegroundColor Yellow
Write-Host "==================================" -ForegroundColor Yellow

# Test if Show-InstallationPrompt would show UI or go silent
Write-Host "`nTesting Show-InstallationPrompt behavior..."

# Create a test to see if UI would be shown
$testScriptBlock = {
    param($deployMode, $SessionZero, $RunAsActiveUser)
    
    # Simulate conditions
    if ($deployMode -eq 'Silent' -or $deployMode -eq 'NonInteractive') {
        return "SILENT: Deployment mode is $deployMode"
    }
    elseif ($SessionZero -and -not $RunAsActiveUser) {
        return "SILENT: Session Zero with no active user"
    }
    elseif (-not [Environment]::UserInteractive) {
        return "SILENT: Process not user interactive"
    }
    else {
        return "UI: Would show user interface"
    }
}

$result = & $testScriptBlock -deployMode $deployMode -SessionZero $SessionZero -RunAsActiveUser $RunAsActiveUser
Write-Host "   Result: $result"

# Test 6: Test attended vs unattended decision logic
Write-Host "`n`nTEST 6: Attended vs Unattended Logic" -ForegroundColor Yellow
Write-Host "====================================" -ForegroundColor Yellow

# Determine session type based on PSADT variables
$sessionType = "UNKNOWN"
$recommendation = ""

if ($RunAsActiveUser -and $RunAsActiveUser.IsActiveUserSession) {
    $sessionType = "ATTENDED"
    $recommendation = "Show calendar picker UI"
}
elseif ($SessionZero -and -not $RunAsActiveUser) {
    $sessionType = "UNATTENDED"
    $recommendation = "Proceed with silent upgrade"
}
elseif (-not [Environment]::UserInteractive) {
    $sessionType = "UNATTENDED"
    $recommendation = "Non-interactive process - go silent"
}
else {
    $sessionType = "UNKNOWN"
    $recommendation = "Uncertain - default to showing UI"
}

Write-Host "`nSession Type: $sessionType" -ForegroundColor Cyan
Write-Host "Recommendation: $recommendation" -ForegroundColor Green

# Test 7: Multi-session OS detection
Write-Host "`n`nTEST 7: Multi-Session OS Detection" -ForegroundColor Yellow
Write-Host "===================================" -ForegroundColor Yellow

Write-Host "Is Multi-Session OS: $($IsMultiSessionOS)"
Write-Host "OS Name: $($envOSName)"
Write-Host "OS Version: $($envOSVersion)"

# Summary
Write-Host "`n`n================================" -ForegroundColor Cyan
Write-Host "SUMMARY" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan

Write-Host "`nPSADT v3 Session Detection Capabilities:"
Write-Host "✓ Can detect logged-on users: $(if($loggedOnUsers){'YES'}else{'NO'})"
Write-Host "✓ Can detect active user session: $(if($RunAsActiveUser){'YES'}else{'NO'})"
Write-Host "✓ Can detect Session Zero: $SessionZero"
Write-Host "✓ Can detect interactive process: $IsProcessUserInteractive"
Write-Host "✓ Deployment mode: $deployMode"

Write-Host "`nConclusion:" -ForegroundColor Green
if ($sessionType -eq "ATTENDED") {
    Write-Host "PSADT detects an ATTENDED session - would show UI/calendar picker"
}
elseif ($sessionType -eq "UNATTENDED") {
    Write-Host "PSADT detects an UNATTENDED session - would proceed silently"
}
else {
    Write-Host "PSADT session detection is UNCERTAIN - needs further testing"
}

Write-Host "`n================================`n" -ForegroundColor Cyan