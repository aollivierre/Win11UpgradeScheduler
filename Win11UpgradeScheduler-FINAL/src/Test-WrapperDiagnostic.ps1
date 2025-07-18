<#
.SYNOPSIS
    Diagnostic script for ScheduledTaskWrapper issues
#>

param(
    [string]$PSADTPath = "C:\Code\Win11UpgradeScheduler\Win11UpgradeScheduler-FINAL\src"
)

Write-Host "=== Scheduled Task Wrapper Diagnostic ===" -ForegroundColor Cyan
Write-Host "PSADTPath: $PSADTPath" -ForegroundColor Yellow

# Test 1: Check running context
$currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
Write-Host "`nCurrent User: $currentUser" -ForegroundColor Green
$isSystem = ($currentUser -eq 'NT AUTHORITY\SYSTEM')
Write-Host "Running as SYSTEM: $isSystem" -ForegroundColor $(if ($isSystem) {'Red'} else {'Green'})

# Test 2: Check PSADT files
Write-Host "`nChecking PSADT files..." -ForegroundColor Yellow
$toolkitMain = Join-Path -Path $PSADTPath -ChildPath 'AppDeployToolkit\AppDeployToolkitMain.ps1'
$deployScript = Join-Path -Path $PSADTPath -ChildPath 'Deploy-Application-InstallationAssistant-Version.ps1'
$countdownModule = Join-Path -Path $PSADTPath -ChildPath 'PSADTCustomCountdown.psm1'
$wrapperScript = Join-Path -Path $PSADTPath -ChildPath 'SupportFiles\ScheduledTaskWrapper.ps1'

Write-Host "Toolkit Main: $(Test-Path $toolkitMain)" -ForegroundColor $(if (Test-Path $toolkitMain) {'Green'} else {'Red'})
Write-Host "Deploy Script: $(Test-Path $deployScript)" -ForegroundColor $(if (Test-Path $deployScript) {'Green'} else {'Red'})
Write-Host "Countdown Module: $(Test-Path $countdownModule)" -ForegroundColor $(if (Test-Path $countdownModule) {'Green'} else {'Red'})
Write-Host "Wrapper Script: $(Test-Path $wrapperScript)" -ForegroundColor $(if (Test-Path $wrapperScript) {'Green'} else {'Red'})

# Test 3: Check user sessions
Write-Host "`nChecking for active user sessions..." -ForegroundColor Yellow
try {
    $explorerProcesses = Get-CimInstance -ClassName Win32_Process -Filter "Name = 'explorer.exe'" |
        Where-Object { $_.SessionId -ne 0 }
    
    if ($explorerProcesses) {
        Write-Host "Found $($explorerProcesses.Count) active user session(s)" -ForegroundColor Green
        foreach ($proc in $explorerProcesses) {
            $owner = Invoke-CimMethod -InputObject $proc -MethodName GetOwner
            Write-Host "  - Session $($proc.SessionId): $($owner.Domain)\$($owner.User)" -ForegroundColor Gray
        }
    } else {
        Write-Host "No active user sessions found" -ForegroundColor Red
    }
} catch {
    Write-Host "Error checking sessions: $_" -ForegroundColor Red
}

# Test 4: Try loading PSADT
Write-Host "`nTesting PSADT load..." -ForegroundColor Yellow
try {
    . $toolkitMain
    Write-Host "PSADT loaded successfully" -ForegroundColor Green
    
    # Check if Execute-ProcessAsUser is available
    if (Get-Command Execute-ProcessAsUser -ErrorAction SilentlyContinue) {
        Write-Host "Execute-ProcessAsUser is available" -ForegroundColor Green
    } else {
        Write-Host "Execute-ProcessAsUser NOT available" -ForegroundColor Red
    }
} catch {
    Write-Host "Failed to load PSADT: $_" -ForegroundColor Red
}

# Test 5: Test countdown module
Write-Host "`nTesting countdown module..." -ForegroundColor Yellow
try {
    Import-Module $countdownModule -Force
    if (Get-Command Show-CustomCountdownDialog -ErrorAction SilentlyContinue) {
        Write-Host "Countdown module loaded successfully" -ForegroundColor Green
    } else {
        Write-Host "Countdown module commands NOT available" -ForegroundColor Red
    }
} catch {
    Write-Host "Failed to load countdown module: $_" -ForegroundColor Red
}

Write-Host "`n=== Diagnostic Complete ===" -ForegroundColor Cyan