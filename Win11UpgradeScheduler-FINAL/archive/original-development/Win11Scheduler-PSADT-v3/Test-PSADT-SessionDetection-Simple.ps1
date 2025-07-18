<#
.SYNOPSIS
    Test PSADT v3 Session Detection Capabilities - Simplified
#>

# Get the PSADT root path
$PSADTPath = $PSScriptRoot

# Import PSADT modules
try {
    Write-Host "`n================================"
    Write-Host "PSADT v3 Session Detection Test"
    Write-Host "================================`n"
    
    # Import the toolkit
    Write-Host "Loading PSADT modules..."
    . "$PSADTPath\AppDeployToolkit\AppDeployToolkitMain.ps1" -DisableLogging
    
    Write-Host "PSADT loaded successfully`n"
}
catch {
    Write-Host "Failed to load PSADT: $_"
    exit 1
}

# Test 1: Check session detection variables
Write-Host "TEST 1: Session Detection Variables"
Write-Host "==================================="

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
Write-Host "`n`nTEST 2: Logged On User Detection"
Write-Host "================================="

try {
    $loggedOnUsers = Get-LoggedOnUser
    
    if ($loggedOnUsers) {
        Write-Host "`nLogged on users found: $($loggedOnUsers.Count)"
        
        foreach ($user in $loggedOnUsers) {
            Write-Host "`n   User: $($user.UserName)"
            Write-Host "   Is Active Session: $($user.IsActiveUserSession)"
            Write-Host "   Is Console Session: $($user.IsConsoleSession)"
        }
    }
    else {
        Write-Host "`nNo logged on users detected"
    }
}
catch {
    Write-Host "Error getting logged on users: $_"
}

# Test 3: Check RunAsActiveUser
Write-Host "`n`nTEST 3: Active User Detection"
Write-Host "============================="

if ($RunAsActiveUser) {
    Write-Host "`nActive user detected:"
    Write-Host "   UserName: $($RunAsActiveUser.UserName)"
    Write-Host "   Is Console: $($RunAsActiveUser.IsConsoleSession)"
}
else {
    Write-Host "`nNo active user detected"
}

# Test 4: Deployment mode
Write-Host "`n`nTEST 4: Deployment Mode"
Write-Host "======================="

Write-Host "Current deployment mode: $deployMode"
Write-Host "Is Silent: $deployModeSilent"

# Summary
Write-Host "`n`n================================"
Write-Host "SUMMARY"
Write-Host "================================"

# Determine session type
$sessionType = "UNKNOWN"

if ($RunAsActiveUser -and $RunAsActiveUser.IsActiveUserSession) {
    $sessionType = "ATTENDED"
}
elseif ($SessionZero -and -not $RunAsActiveUser) {
    $sessionType = "UNATTENDED"
}

Write-Host "`nDetected Session Type: $sessionType"
Write-Host "`nPSADT Capabilities:"
Write-Host "- Can detect users: $(if($loggedOnUsers){'YES'}else{'NO'})"
Write-Host "- Active user found: $(if($RunAsActiveUser){'YES'}else{'NO'})"
Write-Host "- Session Zero: $SessionZero"
Write-Host "- Interactive: $IsProcessUserInteractive"

Write-Host "`nBehavior:"
if ($sessionType -eq "ATTENDED") {
    Write-Host "PSADT would show UI (calendar picker)"
}
elseif ($sessionType -eq "UNATTENDED") {
    Write-Host "PSADT would go SILENT (no UI)"
}
else {
    Write-Host "UNCERTAIN - needs more testing"
}