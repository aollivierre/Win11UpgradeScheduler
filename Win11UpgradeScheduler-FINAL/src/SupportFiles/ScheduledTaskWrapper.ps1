#region Script Header
<#
.SYNOPSIS
    Scheduled Task Wrapper for Windows 11 Upgrade
.DESCRIPTION
    This script is called by the scheduled task and handles:
    - Session detection (attended/unattended)
    - 30-minute countdown for attended sessions
    - Pre-flight checks
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
    Version:        1.0.0
    Author:         System Administrator
    Creation Date:  2025-01-15
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
function Test-RunningAsSystem {
    <#
    .SYNOPSIS
        Checks if the current process is running as SYSTEM
    .DESCRIPTION
        Determines if script is running in SYSTEM context
    #>
    [CmdletBinding()]
    param()
    
    $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
    return ($currentUser -eq 'NT AUTHORITY\SYSTEM')
}

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
    
    # Check if running as SYSTEM and need to use ServiceUI
    if (Test-RunningAsSystem) {
        Write-WrapperLog -Message "Running as SYSTEM, using ServiceUI for UI display"
        
        # Load PSADT toolkit to use Execute-ProcessAsUser
        $toolkitMain = Join-Path -Path $PSADTPath -ChildPath 'AppDeployToolkit\AppDeployToolkitMain.ps1'
        . $toolkitMain
        
        # Create a simplified script that avoids complex module loading
        $countdownSeconds = $Minutes * 60
        $countdownScript = @"
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Enable visual styles
[Windows.Forms.Application]::EnableVisualStyles()

# Create form
`$form = New-Object System.Windows.Forms.Form
`$form.Text = "Windows 11 Upgrade Scheduled"
`$form.Size = New-Object System.Drawing.Size(450, 220)
`$form.StartPosition = "CenterScreen"
`$form.FormBorderStyle = "FixedDialog"
`$form.MaximizeBox = `$false
`$form.MinimizeBox = `$false
`$form.TopMost = `$true

# Message label
`$labelMessage = New-Object System.Windows.Forms.Label
`$labelMessage.Location = New-Object System.Drawing.Point(20, 20)
`$labelMessage.Size = New-Object System.Drawing.Size(410, 50)
`$labelMessage.Font = New-Object System.Drawing.Font("Segoe UI", 10)
`$labelMessage.TextAlign = "MiddleCenter"
`$labelMessage.Text = "Windows 11 upgrade will begin in $Minutes minutes.`n`nPlease save your work before continuing."

# Countdown label
`$labelCountdown = New-Object System.Windows.Forms.Label
`$labelCountdown.Location = New-Object System.Drawing.Point(20, 75)
`$labelCountdown.Size = New-Object System.Drawing.Size(410, 50)
`$labelCountdown.Font = New-Object System.Drawing.Font("Segoe UI", 26, [System.Drawing.FontStyle]::Bold)
`$labelCountdown.TextAlign = "MiddleCenter"
`$labelCountdown.ForeColor = [System.Drawing.Color]::DarkBlue

# Start Now button
`$buttonStartNow = New-Object System.Windows.Forms.Button
`$buttonStartNow.Location = New-Object System.Drawing.Point(175, 140)
`$buttonStartNow.Size = New-Object System.Drawing.Size(100, 28)
`$buttonStartNow.Font = New-Object System.Drawing.Font("Segoe UI", 9)
`$buttonStartNow.Text = "&Start Now"
`$buttonStartNow.DialogResult = [System.Windows.Forms.DialogResult]::Yes

# Add controls
`$form.Controls.AddRange(@(`$labelMessage, `$labelCountdown, `$buttonStartNow))

# Timer setup
`$timer = New-Object System.Windows.Forms.Timer
`$startTime = Get-Date
`$countdownTime = `$startTime.AddSeconds($countdownSeconds)

# Timer tick event
`$timer.Add_Tick({
    `$currentTime = Get-Date
    `$remainingTime = `$countdownTime.Subtract(`$currentTime)
    
    if (`$countdownTime -le `$currentTime) {
        `$timer.Stop()
        `$form.DialogResult = [System.Windows.Forms.DialogResult]::OK
        `$form.Close()
    }
    else {
        `$totalHours = `$remainingTime.Days * 24 + `$remainingTime.Hours
        `$labelCountdown.Text = "{0:d2}:{1:d2}:{2:d2}" -f `$totalHours, `$remainingTime.Minutes, `$remainingTime.Seconds
        
        if (`$remainingTime.TotalSeconds -le 10) {
            `$labelCountdown.ForeColor = [System.Drawing.Color]::Red
        }
        elseif (`$remainingTime.TotalSeconds -le 30) {
            `$labelCountdown.ForeColor = [System.Drawing.Color]::DarkOrange
        }
    }
})

# Form load event
`$form.Add_Load({
    `$timer.Interval = 100
    `$timer.Start()
})

# Show dialog
`$result = `$form.ShowDialog()

# Cleanup
`$timer.Stop()
`$timer.Dispose()
`$form.Dispose()

if (`$result -eq 'Yes') {
    exit 1
} else {
    exit 0
}
"@
        
        $tempScript = Join-Path -Path $env:TEMP -ChildPath "CountdownDialog_$(Get-Date -Format 'yyyyMMddHHmmss').ps1"
        $countdownScript | Set-Content -Path $tempScript -Force
        
        try {
            # Execute in user context - simpler approach without -Wait
            Write-WrapperLog -Message "Executing countdown in user context"
            $taskResult = Execute-ProcessAsUser -Path "$PSHOME\powershell.exe" `
                -Parameters "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$tempScript`"" `
                -Wait `
                -PassThru
            
            Write-WrapperLog -Message "Execute-ProcessAsUser completed with exit code: $($taskResult.ExitCode)"
            return ($taskResult.ExitCode -eq 1)
        }
        catch {
            Write-WrapperLog -Message "Error executing countdown: $_" -Severity Error
            return $false
        }
        finally {
            Start-Sleep -Seconds 2
            Remove-Item -Path $tempScript -Force -ErrorAction SilentlyContinue
        }
    }
    else {
        # Not running as SYSTEM, use standard approach
        Write-WrapperLog -Message "Not running as SYSTEM, using standard UI display"
        
        # Create a temporary script to show countdown message
        $countdownSeconds = $Minutes * 60
        $countdownScript = @"
# Load PSADT toolkit
`$scriptPath = Split-Path -Parent `$MyInvocation.MyCommand.Definition
. "`$scriptPath\AppDeployToolkit\AppDeployToolkitMain.ps1"

# Import custom countdown module
Import-Module '$PSADTPath\PSADTCustomCountdown.psm1' -Force

# Show custom countdown with visual progress
`$result = Show-CustomCountdownDialog ``
    -CountdownSeconds $countdownSeconds ``
    -Message "Windows 11 upgrade will begin in $Minutes minutes.`n`nPlease save your work before continuing." ``
    -Title "Windows 11 Upgrade Scheduled"

# Return 1 if Start Now was clicked, 0 if countdown completed
if (`$result -eq 'Yes') {
    exit 1
} else {
    exit 0
}
"@
        
        $tempScript = Join-Path -Path $env:TEMP -ChildPath "CountdownDialog_$(Get-Date -Format 'yyyyMMddHHmmss').ps1"
        $countdownScript | Set-Content -Path $tempScript -Force
        
        try {
            $process = Start-Process -FilePath 'powershell.exe' `
                -ArgumentList "-ExecutionPolicy Bypass -File `"$tempScript`"" `
                -WorkingDirectory $PSADTPath `
                -Wait `
                -PassThru `
                -WindowStyle Hidden
            
            return ($process.ExitCode -eq 1)
        }
        finally {
            Remove-Item -Path $tempScript -Force -ErrorAction SilentlyContinue
        }
    }
}

function Invoke-PreFlightChecks {
    <#
    .SYNOPSIS
        Runs pre-flight checks before upgrade
    .DESCRIPTION
        Validates system readiness for Windows 11 upgrade
    #>
    [CmdletBinding()]
    param()
    
    Write-WrapperLog -Message "Running pre-flight checks"
    
    if (Test-Path -Path $script:PreFlightModulePath) {
        try {
            Import-Module -Name $script:PreFlightModulePath -Force
            $result = Test-SystemReadiness -Verbose
            
            if (-not $result.IsReady) {
                Write-WrapperLog -Message "Pre-flight checks failed: $($result.Issues -join ', ')" -Severity Error
                
                # If attended, show error to user
                if (Test-UserSession) {
                    $message = "System is not ready for Windows 11 upgrade:`n`n"
                    $message += ($result.Issues | ForEach-Object { "- $_" }) -join "`n"
                    
                    if (Test-RunningAsSystem) {
                        Write-WrapperLog -Message "Running as SYSTEM, using Execute-ProcessAsUser for error display"
                        
                        # Load PSADT toolkit to use Execute-ProcessAsUser
                        $toolkitMain = Join-Path -Path $PSADTPath -ChildPath 'AppDeployToolkit\AppDeployToolkitMain.ps1'
                        . $toolkitMain
                        
                        # Use PSADT to show error - escape message properly
                        $escapedMessage = $message -replace '"', '`"' -replace '\$', '`$'
                        $errorScript = @"
# Debug logging
Add-Content -Path "`$env:TEMP\PreFlightError_Debug.log" -Value "[`$(Get-Date)] Starting PreFlightError script"
Add-Content -Path "`$env:TEMP\PreFlightError_Debug.log" -Value "[`$(Get-Date)] Toolkit path: $toolkitMain"
Add-Content -Path "`$env:TEMP\PreFlightError_Debug.log" -Value "[`$(Get-Date)] Message: $escapedMessage"

# Load PSADT toolkit
try {
    . '$toolkitMain'
    Add-Content -Path "`$env:TEMP\PreFlightError_Debug.log" -Value "[`$(Get-Date)] Toolkit loaded successfully"
} catch {
    Add-Content -Path "`$env:TEMP\PreFlightError_Debug.log" -Value "[`$(Get-Date)] Error loading toolkit: `$_"
}

# Show the prompt
try {
    Show-InstallationPrompt -Message "$escapedMessage" -ButtonRightText 'OK' -Icon Error
    Add-Content -Path "`$env:TEMP\PreFlightError_Debug.log" -Value "[`$(Get-Date)] Prompt shown successfully"
} catch {
    Add-Content -Path "`$env:TEMP\PreFlightError_Debug.log" -Value "[`$(Get-Date)] Error showing prompt: `$_"
}
"@
                        $tempErrorScript = Join-Path -Path $env:TEMP -ChildPath "PreFlightError_$(Get-Date -Format 'yyyyMMddHHmmss').ps1"
                        $errorScript | Set-Content -Path $tempErrorScript -Force
                        
                        Write-WrapperLog -Message "Created error script at: $tempErrorScript"
                        Write-WrapperLog -Message "Toolkit path: $toolkitMain"
                        
                        Execute-ProcessAsUser -Path "$PSHOME\powershell.exe" `
                            -Parameters "-ExecutionPolicy Bypass -File `"$tempErrorScript`"" `
                            -Wait
                        
                        Remove-Item -Path $tempErrorScript -Force -ErrorAction SilentlyContinue
                    }
                    else {
                        # Not running as SYSTEM, use standard approach
                        $escapedMessage = $message -replace '"', '`"' -replace '\$', '`$'
                        $errorScript = "`$scriptPath = Split-Path -Parent `$MyInvocation.MyCommand.Definition
. `"`$scriptPath\AppDeployToolkit\AppDeployToolkitMain.ps1`"
Show-InstallationPrompt -Message `"$escapedMessage`" -ButtonRightText 'OK' -Icon Error"
                        $tempErrorScript = Join-Path -Path $env:TEMP -ChildPath "PreFlightError_$(Get-Date -Format 'yyyyMMddHHmmss').ps1"
                        $errorScript | Set-Content -Path $tempErrorScript -Force
                        
                        Start-Process -FilePath 'powershell.exe' `
                            -ArgumentList "-ExecutionPolicy Bypass -File `"$tempErrorScript`"" `
                            -WorkingDirectory $PSADTPath `
                            -Wait `
                            -WindowStyle Hidden
                        
                        Remove-Item -Path $tempErrorScript -Force -ErrorAction SilentlyContinue
                    }
                }
                
                return $false
            }
            
            Write-WrapperLog -Message "Pre-flight checks passed"
            return $true
        }
        catch {
            Write-WrapperLog -Message "Error running pre-flight checks: $_" -Severity Error
            # Continue anyway if pre-flight module fails
            return $true
        }
    }
    else {
        Write-WrapperLog -Message "Pre-flight module not found, skipping checks" -Severity Warning
        return $true
    }
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
    
    # Use the correct deployment script name
    $deployAppScript = Join-Path -Path $PSADTPath -ChildPath 'Deploy-Application-InstallationAssistant-Version.ps1'
    
    if (-not (Test-Path -Path $deployAppScript)) {
        Write-WrapperLog -Message "Deploy-Application.ps1 not found at: $deployAppScript" -Severity Error
        throw "PSADT deployment script not found"
    }
    
    Write-WrapperLog -Message "Starting PSADT deployment: Type=$DeploymentType, Mode=$DeployMode"
    
    # Check if running as SYSTEM and deployment mode is Interactive
    if ((Test-RunningAsSystem) -and ($DeployMode -eq 'Interactive')) {
        Write-WrapperLog -Message "Running as SYSTEM with Interactive mode, using Execute-ProcessAsUser"
        
        # Load PSADT toolkit to use Execute-ProcessAsUser
        $toolkitMain = Join-Path -Path $PSADTPath -ChildPath 'AppDeployToolkit\AppDeployToolkitMain.ps1'
        . $toolkitMain
        
        $arguments = "-ExecutionPolicy Bypass -NoProfile -File `"$deployAppScript`" -DeploymentType $DeploymentType -DeployMode $DeployMode -ScheduledMode"
        
        try {
            $result = Execute-ProcessAsUser -Path "$PSHOME\powershell.exe" `
                -Parameters $arguments `
                -Wait
            
            Write-WrapperLog -Message "PSADT deployment completed with exit code: $($result.ExitCode)"
            return $result.ExitCode
        }
        catch {
            Write-WrapperLog -Message "Failed to start PSADT deployment via Execute-ProcessAsUser: $_" -Severity Error
            throw
        }
    }
    else {
        # Not running as SYSTEM or not Interactive mode, use standard approach
        $arguments = @(
            "-ExecutionPolicy Bypass"
            "-NoProfile"
            "-File `"$deployAppScript`""
            "-DeploymentType $DeploymentType"
            "-DeployMode $DeployMode"
            "-ScheduledMode"
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
}
#endregion

#region Main Script
try {
    Write-WrapperLog -Message ("=" * 60)
    Write-WrapperLog -Message "Windows 11 Upgrade Scheduled Task Wrapper Started"
    Write-WrapperLog -Message "PSADTPath: $PSADTPath"
    Write-WrapperLog -Message "DeploymentType: $DeploymentType"
    Write-WrapperLog -Message "DeployMode: $DeployMode"
    Write-WrapperLog -Message "ForceCountdown: $ForceCountdown"
    
    # Check if user session is active
    $isAttended = Test-UserSession
    Write-WrapperLog -Message "Session type: $(if ($isAttended) { 'Attended' } else { 'Unattended' })"
    
    # Run pre-flight checks
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
            Unregister-ScheduledTask -TaskName 'Windows11UpgradeScheduled' -TaskPath '\Microsoft\Windows\Win11Upgrade' -Confirm:$false
            Write-WrapperLog -Message "Scheduled task removed successfully"
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