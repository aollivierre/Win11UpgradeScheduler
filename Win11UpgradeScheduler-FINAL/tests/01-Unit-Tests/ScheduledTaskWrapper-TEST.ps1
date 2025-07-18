#region Script Header
<#
.SYNOPSIS
    TEST VERSION - Scheduled Task Wrapper for Windows 11 Upgrade (Pre-flight checks BYPASSED)
.DESCRIPTION
    This script is called by the scheduled task and handles:
    - Session detection (attended/unattended)
    - 30-minute countdown for attended sessions
    - Pre-flight checks (BYPASSED FOR TESTING)
    - Launching PSADT with appropriate parameters
.PARAMETER PSADTPath
    Path to the PSADT package directory
.PARAMETER DeploymentType
    Type of deployment (Install/Uninstall)
.PARAMETER DeployMode
    Deployment mode (Interactive/Silent/NonInteractive)
.PARAMETER ForceCountdown
    Force countdown even in unattended sessions
.NOTES
    Version:        1.0.0-TEST
    Author:         System Administrator
    Creation Date:  2025-01-15
    Modified:       2025-01-16 - BYPASSED PRE-FLIGHT CHECKS FOR TESTING
#>
#endregion

#region Parameters
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$PSADTPath,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet('Install','Uninstall')]
    [string]$DeploymentType = 'Install',
    
    [Parameter(Mandatory=$false)]
    [ValidateSet('Interactive','Silent','NonInteractive')]
    [string]$DeployMode = 'Interactive',
    
    [Parameter(Mandatory=$false)]
    [switch]$ForceCountdown
)
#endregion

#region Variables
$script:LogPath = "$env:ProgramData\Win11UpgradeScheduler\Logs"
$script:CountdownMinutes = 30
$script:PreFlightModulePath = Join-Path -Path $PSADTPath -ChildPath 'SupportFiles\Modules\02-PreFlightChecks.psm1'
#endregion

#region Functions
function Write-WrapperLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet('Information','Warning','Error')]
        [string]$Severity = 'Information'
    )
    
    if (-not (Test-Path -Path $script:LogPath)) {
        New-Item -Path $script:LogPath -ItemType Directory -Force | Out-Null
    }
    
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logFile = Join-Path -Path $script:LogPath -ChildPath "TaskWrapper_$(Get-Date -Format 'yyyyMMdd').log"
    $logEntry = "[$timestamp] [$Severity] $Message"
    
    Add-Content -Path $logFile -Value $logEntry -Force
    
    # Also write to console for testing
    switch ($Severity) {
        'Error' { Write-Host $logEntry -ForegroundColor Red }
        'Warning' { Write-Host $logEntry -ForegroundColor Yellow }
        default { Write-Host $logEntry -ForegroundColor White }
    }
}

function Test-UserSession {
    <#
    .SYNOPSIS
        Determines if there's an active user session
    .DESCRIPTION
        Checks for interactive user sessions to determine attended/unattended state
    #>
    [CmdletBinding()]
    param()
    
    Write-WrapperLog -Message "Checking for active user sessions"
    
    try {
        # Method 1: Check for explorer.exe processes with user context
        $explorerProcesses = Get-CimInstance -ClassName Win32_Process -Filter "Name = 'explorer.exe'" |
            Where-Object { $_.SessionId -ne 0 }
        
        if ($explorerProcesses) {
            Write-WrapperLog -Message "Found $($explorerProcesses.Count) active user session(s)"
            return $true
        }
        
        # Method 2: Check for console session
        $sessions = @(quser 2>$null) | Where-Object { $_ -match 'console|rdp' }
        if ($sessions.Count -gt 0) {
            Write-WrapperLog -Message "Found active console/RDP session"
            return $true
        }
        
        Write-WrapperLog -Message "No active user sessions detected"
        return $false
    }
    catch {
        Write-WrapperLog -Message "Error checking user sessions: $_" -Severity Warning
        # Default to attended if we can't determine
        return $true
    }
}

function Show-CountdownDialog {
    <#
    .SYNOPSIS
        Shows a 30-minute countdown dialog
    .DESCRIPTION
        Displays countdown with option to start immediately
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [int]$Minutes
    )
    
    Write-WrapperLog -Message "Showing countdown dialog for $Minutes minutes"
    
    # Use PSADT's built-in countdown functionality
    $deployAppScriptPath = Join-Path -Path $PSADTPath -ChildPath 'Deploy-Application.ps1'
    
    # Create a temporary script to show countdown
    $countdownScript = @"
# Load PSADT toolkit
`$scriptPath = Split-Path -Parent `$MyInvocation.MyCommand.Definition
. "`$scriptPath\AppDeployToolkit\AppDeployToolkitMain.ps1"

# Show countdown
Show-InstallationPrompt -Message "Windows 11 upgrade will begin in $Minutes minutes.``n``nPlease save your work. You can click 'Start Now' to begin immediately." ``
    -ButtonRightText 'Start Now' ``
    -ButtonLeftText 'OK' ``
    -Icon Information ``
    -Timeout ([timespan]::FromMinutes($Minutes).TotalSeconds) ``
    -ExitOnTimeout `$false

# Return the button clicked
if (`$global:psButtonClicked -eq 'Start Now') {
    exit 0
} else {
    exit 1
}
"@
    
    $tempCountdownScript = Join-Path -Path $env:TEMP -ChildPath "Countdown_$(Get-Date -Format 'yyyyMMddHHmmss').ps1"
    $countdownScript | Set-Content -Path $tempCountdownScript -Force
    
    try {
        $process = Start-Process -FilePath 'powershell.exe' `
            -ArgumentList "-ExecutionPolicy Bypass -File `"$tempCountdownScript`"" `
            -WorkingDirectory $PSADTPath `
            -Wait `
            -PassThru
        
        return ($process.ExitCode -eq 0)
    }
    finally {
        Remove-Item -Path $tempCountdownScript -Force -ErrorAction SilentlyContinue
    }
}

function Invoke-PreFlightChecks {
    <#
    .SYNOPSIS
        BYPASSED FOR TESTING - Always returns true
    #>
    [CmdletBinding()]
    param()
    
    Write-WrapperLog -Message "!!! PRE-FLIGHT CHECKS BYPASSED FOR TESTING !!!" -Severity Warning
    Write-WrapperLog -Message "In production, this would check disk space, battery, updates, etc." -Severity Warning
    
    # Always return true for testing
    return $true
}

function Start-PSADTDeployment {
    <#
    .SYNOPSIS
        Launches the PSADT deployment
    .DESCRIPTION
        Starts Deploy-Application.ps1 with appropriate parameters
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$DeploymentType,
        
        [Parameter(Mandatory=$true)]
        [string]$DeployMode
    )
    
    $deployAppScript = Join-Path -Path $PSADTPath -ChildPath 'Deploy-Application.ps1'
    
    if (-not (Test-Path -Path $deployAppScript)) {
        Write-WrapperLog -Message "Deploy-Application.ps1 not found at: $deployAppScript" -Severity Error
        throw "PSADT deployment script not found"
    }
    
    Write-WrapperLog -Message "Starting PSADT deployment: Type=$DeploymentType, Mode=$DeployMode"
    
    $arguments = @(
        "-ExecutionPolicy Bypass"
        "-NoProfile"
        "-File `"$deployAppScript`""
        "-DeploymentType $DeploymentType"
        "-DeployMode $DeployMode"
    )
    
    try {
        $process = Start-Process -FilePath 'powershell.exe' `
            -ArgumentList ($arguments -join ' ') `
            -WorkingDirectory $PSADTPath `
            -Wait `
            -PassThru `
            -WindowStyle Hidden
        
        Write-WrapperLog -Message "PSADT deployment completed with exit code: $($process.ExitCode)"
        return $process.ExitCode
    }
    catch {
        Write-WrapperLog -Message "Failed to start PSADT deployment: $_" -Severity Error
        throw
    }
}
#endregion

#region Main Script
try {
    Write-WrapperLog -Message ("=" * 60)
    Write-WrapperLog -Message "Windows 11 Upgrade Scheduled Task Wrapper Started (TEST VERSION)"
    Write-WrapperLog -Message "PSADTPath: $PSADTPath"
    Write-WrapperLog -Message "DeploymentType: $DeploymentType"
    Write-WrapperLog -Message "DeployMode: $DeployMode"
    Write-WrapperLog -Message "ForceCountdown: $ForceCountdown"
    
    # Check if user session is active
    $isAttended = Test-UserSession
    Write-WrapperLog -Message "Session type: $(if ($isAttended) { 'Attended' } else { 'Unattended' })"
    
    # Run pre-flight checks (BYPASSED)
    if (-not (Invoke-PreFlightChecks)) {
        Write-WrapperLog -Message "Pre-flight checks failed, aborting deployment" -Severity Error
        exit 1
    }
    
    # Handle countdown for attended sessions
    $startImmediately = $false
    if ($isAttended -and -not $ForceCountdown) {
        Write-WrapperLog -Message "Attended session detected, showing countdown dialog"
        $startImmediately = Show-CountdownDialog -Minutes $script:CountdownMinutes
        
        if ($startImmediately) {
            Write-WrapperLog -Message "User selected 'Start Now'"
        }
        else {
            Write-WrapperLog -Message "Countdown completed or user clicked OK"
        }
    }
    elseif ($isAttended -and $ForceCountdown) {
        Write-WrapperLog -Message "Attended session with forced countdown"
        Show-CountdownDialog -Minutes $script:CountdownMinutes | Out-Null
    }
    else {
        Write-WrapperLog -Message "Unattended session, proceeding immediately"
        $startImmediately = $true
    }
    
    # Start PSADT deployment
    $exitCode = Start-PSADTDeployment -DeploymentType $DeploymentType -DeployMode $DeployMode
    
    # Clean up scheduled task if successful
    if ($exitCode -eq 0 -or $exitCode -eq 3010) {
        Write-WrapperLog -Message "Deployment successful, cleaning up scheduled task"
        
        try {
            # Don't actually unregister in test mode
            Write-WrapperLog -Message "TEST MODE: Would unregister scheduled task here" -Severity Warning
        }
        catch {
            Write-WrapperLog -Message "Failed to remove scheduled task: $_" -Severity Warning
        }
    }
    
    Write-WrapperLog -Message "Wrapper script completed with exit code: $exitCode"
    exit $exitCode
}
catch {
    Write-WrapperLog -Message "Fatal error in wrapper script: $_" -Severity Error
    exit 1
}
#endregion