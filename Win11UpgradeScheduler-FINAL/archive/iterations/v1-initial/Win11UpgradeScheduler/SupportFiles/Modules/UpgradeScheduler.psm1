#region Module Header
<#
.SYNOPSIS
    Windows 11 Upgrade Scheduler Module
.DESCRIPTION
    Core module for scheduling Windows 11 upgrades with flexible timing options
.NOTES
    Version:        1.0.0
    Author:         System Administrator
    Creation Date:  2025-01-15
#>
#endregion

#region Module Variables
$script:ModuleVersion = '1.0.0'
$script:TaskName = 'Windows11UpgradeScheduled'
$script:TaskPath = '\Microsoft\Windows\Win11Upgrade'
$script:LogPath = "$env:ProgramData\Win11UpgradeScheduler\Logs"
$script:ConfigPath = "$env:ProgramData\Win11UpgradeScheduler\Config"
#endregion

#region Helper Functions
function Write-SchedulerLog {
    <#
    .SYNOPSIS
        Writes a log entry to the scheduler log file
    .DESCRIPTION
        Creates timestamped log entries for scheduler operations
    .PARAMETER Message
        The message to log
    .PARAMETER Severity
        Log severity level (Information, Warning, Error)
    .EXAMPLE
        Write-SchedulerLog -Message "Task scheduled successfully" -Severity Information
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet('Information','Warning','Error')]
        [string]$Severity = 'Information'
    )
    
    # Ensure log directory exists
    if (-not (Test-Path -Path $script:LogPath)) {
        New-Item -Path $script:LogPath -ItemType Directory -Force | Out-Null
    }
    
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logFile = Join-Path -Path $script:LogPath -ChildPath "SchedulerModule_$(Get-Date -Format 'yyyyMMdd').log"
    $logEntry = "[$timestamp] [$Severity] $Message"
    
    try {
        Add-Content -Path $logFile -Value $logEntry -Force
    }
    catch {
        # Fallback to event log if file write fails
        Write-EventLog -LogName Application -Source 'Win11UpgradeScheduler' -EntryType $Severity -EventId 1000 -Message $Message -ErrorAction SilentlyContinue
    }
}

function Test-ScheduleTime {
    <#
    .SYNOPSIS
        Validates a proposed schedule time
    .DESCRIPTION
        Ensures schedule time meets minimum buffer requirements
    .PARAMETER ScheduleTime
        The proposed schedule time
    .PARAMETER MinimumHoursAhead
        Minimum hours ahead of current time (default: 2)
    .EXAMPLE
        Test-ScheduleTime -ScheduleTime (Get-Date).AddHours(3)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [datetime]$ScheduleTime,
        
        [Parameter(Mandatory=$false)]
        [int]$MinimumHoursAhead = 2
    )
    
    $currentTime = Get-Date
    $minimumTime = $currentTime.AddHours($MinimumHoursAhead)
    
    if ($ScheduleTime -lt $minimumTime) {
        Write-SchedulerLog -Message "Schedule time $ScheduleTime is less than minimum required time $minimumTime" -Severity Warning
        return $false
    }
    
    return $true
}
#endregion

#region Core Scheduling Functions
function New-UpgradeSchedule {
    <#
    .SYNOPSIS
        Creates a new Windows 11 upgrade schedule
    .DESCRIPTION
        Schedules a Windows 11 upgrade with the specified parameters
    .PARAMETER ScheduleTime
        The date and time to run the upgrade
    .PARAMETER PSADTPath
        Path to the PSADT package directory
    .PARAMETER DeploymentType
        Type of deployment (Install/Uninstall)
    .PARAMETER DeployMode
        Deployment mode (Interactive/Silent/NonInteractive)
    .PARAMETER ForceCountdown
        Force countdown even in unattended sessions
    .EXAMPLE
        New-UpgradeSchedule -ScheduleTime (Get-Date).AddHours(4) -PSADTPath "C:\Temp\Win11Upgrade"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [datetime]$ScheduleTime,
        
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
    
    Write-SchedulerLog -Message "Starting New-UpgradeSchedule" -Severity Information
    
    # Validate schedule time
    if (-not (Test-ScheduleTime -ScheduleTime $ScheduleTime)) {
        throw "Schedule time must be at least 2 hours in the future"
    }
    
    # Validate PSADT path
    if (-not (Test-Path -Path $PSADTPath)) {
        throw "PSADT path not found: $PSADTPath"
    }
    
    # Create wrapper script path
    $wrapperScript = Join-Path -Path $PSADTPath -ChildPath 'SupportFiles\ScheduledTaskWrapper.ps1'
    if (-not (Test-Path -Path $wrapperScript)) {
        throw "Wrapper script not found: $wrapperScript"
    }
    
    # Build task action arguments
    $arguments = @(
        "-ExecutionPolicy Bypass"
        "-NoProfile"
        "-WindowStyle Hidden"
        "-File `"$wrapperScript`""
        "-PSADTPath `"$PSADTPath`""
        "-DeploymentType $DeploymentType"
        "-DeployMode $DeployMode"
    )
    
    if ($ForceCountdown) {
        $arguments += "-ForceCountdown"
    }
    
    $taskAction = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument ($arguments -join ' ')
    
    # Create trigger
    $taskTrigger = New-ScheduledTaskTrigger -Once -At $ScheduleTime
    
    # Create principal (SYSTEM account)
    $taskPrincipal = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType ServiceAccount -RunLevel Highest
    
    # Create settings
    $taskSettings = New-ScheduledTaskSettingsSet `
        -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries `
        -WakeToRun `
        -StartWhenAvailable `
        -RestartCount 3 `
        -RestartInterval (New-TimeSpan -Minutes 10) `
        -ExecutionTimeLimit (New-TimeSpan -Hours 4)
    
    # Register the task
    try {
        $task = Register-ScheduledTask `
            -TaskName $script:TaskName `
            -TaskPath $script:TaskPath `
            -Action $taskAction `
            -Trigger $taskTrigger `
            -Principal $taskPrincipal `
            -Settings $taskSettings `
            -Description "Scheduled Windows 11 upgrade using PSADT" `
            -Force
        
        Write-SchedulerLog -Message "Successfully created scheduled task for $ScheduleTime" -Severity Information
        
        # Save schedule configuration
        Save-ScheduleConfig -ScheduleTime $ScheduleTime -PSADTPath $PSADTPath -DeploymentType $DeploymentType -DeployMode $DeployMode
        
        return $task
    }
    catch {
        Write-SchedulerLog -Message "Failed to create scheduled task: $_" -Severity Error
        throw
    }
}

function Get-UpgradeSchedule {
    <#
    .SYNOPSIS
        Gets the current upgrade schedule
    .DESCRIPTION
        Retrieves information about the scheduled Windows 11 upgrade
    .EXAMPLE
        Get-UpgradeSchedule
    #>
    [CmdletBinding()]
    param()
    
    try {
        $task = Get-ScheduledTask -TaskName $script:TaskName -TaskPath $script:TaskPath -ErrorAction Stop
        $config = Get-ScheduleConfig
        
        $result = [PSCustomObject]@{
            TaskName = $task.TaskName
            State = $task.State
            NextRunTime = ($task.Triggers | Select-Object -First 1).StartBoundary
            LastRunTime = $task.LastRunTime
            LastResult = $task.LastTaskResult
            Configuration = $config
        }
        
        return $result
    }
    catch {
        Write-SchedulerLog -Message "No scheduled upgrade found" -Severity Information
        return $null
    }
}

function Remove-UpgradeSchedule {
    <#
    .SYNOPSIS
        Removes the upgrade schedule
    .DESCRIPTION
        Cancels and removes the scheduled Windows 11 upgrade task
    .PARAMETER Force
        Force removal without confirmation
    .EXAMPLE
        Remove-UpgradeSchedule -Force
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$false)]
        [switch]$Force
    )
    
    $schedule = Get-UpgradeSchedule
    if ($null -eq $schedule) {
        Write-SchedulerLog -Message "No scheduled upgrade to remove" -Severity Information
        return
    }
    
    if ($Force -or $PSCmdlet.ShouldProcess($script:TaskName, "Remove scheduled task")) {
        try {
            Unregister-ScheduledTask -TaskName $script:TaskName -TaskPath $script:TaskPath -Confirm:$false
            Remove-ScheduleConfig
            Write-SchedulerLog -Message "Successfully removed scheduled upgrade" -Severity Information
        }
        catch {
            Write-SchedulerLog -Message "Failed to remove scheduled task: $_" -Severity Error
            throw
        }
    }
}

function Update-UpgradeSchedule {
    <#
    .SYNOPSIS
        Updates an existing upgrade schedule
    .DESCRIPTION
        Modifies the schedule time for an existing Windows 11 upgrade
    .PARAMETER NewScheduleTime
        The new date and time for the upgrade
    .EXAMPLE
        Update-UpgradeSchedule -NewScheduleTime (Get-Date).AddDays(1).Date.AddHours(20)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [datetime]$NewScheduleTime
    )
    
    Write-SchedulerLog -Message "Updating upgrade schedule to $NewScheduleTime" -Severity Information
    
    # Get current schedule
    $currentSchedule = Get-UpgradeSchedule
    if ($null -eq $currentSchedule) {
        throw "No existing schedule found to update"
    }
    
    # Validate new time
    if (-not (Test-ScheduleTime -ScheduleTime $NewScheduleTime)) {
        throw "New schedule time must be at least 2 hours in the future"
    }
    
    # Get current configuration
    $config = $currentSchedule.Configuration
    
    # Remove old schedule
    Remove-UpgradeSchedule -Force
    
    # Create new schedule with updated time
    New-UpgradeSchedule `
        -ScheduleTime $NewScheduleTime `
        -PSADTPath $config.PSADTPath `
        -DeploymentType $config.DeploymentType `
        -DeployMode $config.DeployMode `
        -ForceCountdown:$config.ForceCountdown
}
#endregion

#region Configuration Management
function Save-ScheduleConfig {
    <#
    .SYNOPSIS
        Saves schedule configuration
    .DESCRIPTION
        Persists schedule configuration for later retrieval
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [datetime]$ScheduleTime,
        
        [Parameter(Mandatory=$true)]
        [string]$PSADTPath,
        
        [Parameter(Mandatory=$true)]
        [string]$DeploymentType,
        
        [Parameter(Mandatory=$true)]
        [string]$DeployMode,
        
        [Parameter(Mandatory=$false)]
        [bool]$ForceCountdown = $false
    )
    
    # Ensure config directory exists
    if (-not (Test-Path -Path $script:ConfigPath)) {
        New-Item -Path $script:ConfigPath -ItemType Directory -Force | Out-Null
    }
    
    $config = @{
        ScheduleTime = $ScheduleTime.ToString('yyyy-MM-dd HH:mm:ss')
        PSADTPath = $PSADTPath
        DeploymentType = $DeploymentType
        DeployMode = $DeployMode
        ForceCountdown = $ForceCountdown
        CreatedBy = $env:USERNAME
        CreatedAt = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    }
    
    $configFile = Join-Path -Path $script:ConfigPath -ChildPath 'ScheduleConfig.json'
    $config | ConvertTo-Json | Set-Content -Path $configFile -Force
}

function Get-ScheduleConfig {
    <#
    .SYNOPSIS
        Gets saved schedule configuration
    .DESCRIPTION
        Retrieves persisted schedule configuration
    #>
    [CmdletBinding()]
    param()
    
    $configFile = Join-Path -Path $script:ConfigPath -ChildPath 'ScheduleConfig.json'
    if (Test-Path -Path $configFile) {
        $config = Get-Content -Path $configFile -Raw | ConvertFrom-Json
        # Convert string back to datetime
        $config.ScheduleTime = [datetime]::ParseExact($config.ScheduleTime, 'yyyy-MM-dd HH:mm:ss', $null)
        return $config
    }
    
    return $null
}

function Remove-ScheduleConfig {
    <#
    .SYNOPSIS
        Removes saved schedule configuration
    .DESCRIPTION
        Deletes persisted schedule configuration
    #>
    [CmdletBinding()]
    param()
    
    $configFile = Join-Path -Path $script:ConfigPath -ChildPath 'ScheduleConfig.json'
    if (Test-Path -Path $configFile) {
        Remove-Item -Path $configFile -Force
    }
}
#endregion

#region Quick Schedule Functions
function New-QuickUpgradeSchedule {
    <#
    .SYNOPSIS
        Creates a quick upgrade schedule for common times
    .DESCRIPTION
        Provides easy scheduling for tonight or tomorrow at preset times
    .PARAMETER When
        When to schedule (Tonight, Tomorrow)
    .PARAMETER Time
        Time slot (8PM, 10PM, 11PM for tonight; Morning, Afternoon, Evening for tomorrow)
    .PARAMETER PSADTPath
        Path to the PSADT package
    .EXAMPLE
        New-QuickUpgradeSchedule -When Tonight -Time 8PM -PSADTPath "C:\Temp\Win11Upgrade"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet('Tonight','Tomorrow')]
        [string]$When,
        
        [Parameter(Mandatory=$true)]
        [string]$Time,
        
        [Parameter(Mandatory=$true)]
        [string]$PSADTPath,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet('Interactive','Silent','NonInteractive')]
        [string]$DeployMode = 'Interactive'
    )
    
    $now = Get-Date
    $scheduleTime = $null
    
    switch ($When) {
        'Tonight' {
            $baseDate = $now.Date
            switch ($Time) {
                '8PM'  { $scheduleTime = $baseDate.AddHours(20) }
                '10PM' { $scheduleTime = $baseDate.AddHours(22) }
                '11PM' { $scheduleTime = $baseDate.AddHours(23) }
                default { throw "Invalid time for Tonight. Valid options: 8PM, 10PM, 11PM" }
            }
            
            # If selected time has passed, throw error
            if ($scheduleTime -le $now) {
                throw "Cannot schedule for tonight at $Time - that time has already passed"
            }
        }
        
        'Tomorrow' {
            $baseDate = $now.Date.AddDays(1)
            switch ($Time) {
                'Morning'   { $scheduleTime = $baseDate.AddHours(9) }
                'Afternoon' { $scheduleTime = $baseDate.AddHours(14) }
                'Evening'   { $scheduleTime = $baseDate.AddHours(20) }
                default { throw "Invalid time for Tomorrow. Valid options: Morning, Afternoon, Evening" }
            }
        }
    }
    
    # Check if scheduling within 4 hours and warn
    $hoursUntil = ($scheduleTime - $now).TotalHours
    if ($hoursUntil -lt 4) {
        Write-Warning "Scheduling upgrade in less than 4 hours ($([math]::Round($hoursUntil, 1)) hours). Users may not have adequate notice."
    }
    
    # Create the schedule
    New-UpgradeSchedule -ScheduleTime $scheduleTime -PSADTPath $PSADTPath -DeploymentType Install -DeployMode $DeployMode
}
#endregion

#region Module Export
Export-ModuleMember -Function @(
    'New-UpgradeSchedule'
    'Get-UpgradeSchedule'
    'Remove-UpgradeSchedule'
    'Update-UpgradeSchedule'
    'New-QuickUpgradeSchedule'
    'Write-SchedulerLog'
)
#endregion