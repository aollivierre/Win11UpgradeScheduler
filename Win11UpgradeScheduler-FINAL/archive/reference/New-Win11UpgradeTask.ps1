Function New-Win11UpgradeTask {
    <#
    .SYNOPSIS
        Creates a scheduled task for Windows 11 upgrade
    .DESCRIPTION
        Creates an actual Windows scheduled task that will run the Windows 11 upgrade
        at the specified date and time using Task Scheduler
    .PARAMETER ScheduledDate
        The date and time when the upgrade should run
    .PARAMETER TaskName
        Name of the scheduled task (default: "Windows11Upgrade")
    .PARAMETER TaskPath
        Task folder path (default: "\Microsoft\Windows\Win11Upgrade\")
    .PARAMETER UpgradeScriptPath
        Path to the upgrade script/executable
    .OUTPUTS
        Boolean - True if task created successfully, False otherwise
    .EXAMPLE
        New-Win11UpgradeTask -ScheduledDate (Get-Date).AddDays(1).AddHours(14)
    #>
    [CmdletBinding()]
    [OutputType([Boolean])]
    Param(
        [Parameter(Mandatory=$true)]
        [DateTime]$ScheduledDate,
        
        [Parameter(Mandatory=$false)]
        [String]$TaskName = "Windows11Upgrade",
        
        [Parameter(Mandatory=$false)]
        [String]$TaskPath = "\Microsoft\Windows\Win11Upgrade\",
        
        [Parameter(Mandatory=$false)]
        [String]$UpgradeScriptPath = "$env:SystemRoot\Temp\Win11Upgrade\Windows11InstallationAssistant.exe"
    )
    
    try {
        Write-Log -Message "Creating Windows 11 upgrade scheduled task..." -Source 'New-Win11UpgradeTask'
        
        # Check if task already exists
        $existingTask = Get-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath -ErrorAction SilentlyContinue
        if ($existingTask) {
            Write-Log -Message "Scheduled task already exists. Removing old task..." -Source 'New-Win11UpgradeTask'
            Unregister-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath -Confirm:$false
        }
        
        # Create task action
        Write-Log -Message "Creating task action for: $UpgradeScriptPath" -Source 'New-Win11UpgradeTask'
        $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -WindowStyle Hidden -Command `"& { Start-Process '$UpgradeScriptPath' -ArgumentList '/quietinstall /skipeula /auto upgrade /copylogs $env:SystemRoot\Temp' -Wait }`""
        
        # Create task trigger
        Write-Log -Message "Creating task trigger for: $($ScheduledDate.ToString('yyyy-MM-dd HH:mm:ss'))" -Source 'New-Win11UpgradeTask'
        $trigger = New-ScheduledTaskTrigger -Once -At $ScheduledDate
        
        # Create task principal (run with highest privileges)
        Write-Log -Message "Creating task principal with highest privileges" -Source 'New-Win11UpgradeTask'
        $principal = New-ScheduledTaskPrincipal -UserId "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount -RunLevel Highest
        
        # Create task settings
        Write-Log -Message "Creating task settings" -Source 'New-Win11UpgradeTask'
        $settings = New-ScheduledTaskSettingsSet `
            -AllowStartIfOnBatteries `
            -DontStopIfGoingOnBatteries `
            -StartWhenAvailable `
            -RestartCount 3 `
            -RestartInterval (New-TimeSpan -Minutes 10) `
            -ExecutionTimeLimit (New-TimeSpan -Hours 4) `
            -Priority 4
        
        # Register the scheduled task
        Write-Log -Message "Registering scheduled task: $TaskPath$TaskName" -Source 'New-Win11UpgradeTask'
        $task = Register-ScheduledTask `
            -TaskName $TaskName `
            -TaskPath $TaskPath `
            -Action $action `
            -Trigger $trigger `
            -Principal $principal `
            -Settings $settings `
            -Description "Windows 11 In-Place Upgrade - Scheduled for $($ScheduledDate.ToString('yyyy-MM-dd HH:mm:ss'))"
        
        if ($task) {
            Write-Log -Message "Scheduled task created successfully" -Source 'New-Win11UpgradeTask'
            
            # Verify task was created
            $verifyTask = Get-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath -ErrorAction SilentlyContinue
            if ($verifyTask) {
                Write-Log -Message "Task verification successful. State: $($verifyTask.State)" -Source 'New-Win11UpgradeTask'
                
                # Log task details
                Write-Log -Message "Task Name: $($verifyTask.TaskName)" -Source 'New-Win11UpgradeTask'
                Write-Log -Message "Task Path: $($verifyTask.TaskPath)" -Source 'New-Win11UpgradeTask'
                Write-Log -Message "Next Run Time: $($verifyTask.Triggers[0].StartBoundary)" -Source 'New-Win11UpgradeTask'
                
                return $true
            } else {
                Write-Log -Message "Task verification failed" -Severity 3 -Source 'New-Win11UpgradeTask'
                return $false
            }
        } else {
            Write-Log -Message "Failed to register scheduled task" -Severity 3 -Source 'New-Win11UpgradeTask'
            return $false
        }
        
    } catch {
        Write-Log -Message "Error creating scheduled task: $($_.Exception.Message)" -Severity 3 -Source 'New-Win11UpgradeTask'
        Write-Log -Message "Stack trace: $($_.Exception.StackTrace)" -Severity 3 -Source 'New-Win11UpgradeTask'
        return $false
    }
}

Function Remove-Win11UpgradeTask {
    <#
    .SYNOPSIS
        Removes the Windows 11 upgrade scheduled task
    .DESCRIPTION
        Removes the scheduled task created for Windows 11 upgrade
    .PARAMETER TaskName
        Name of the scheduled task (default: "Windows11Upgrade")
    .PARAMETER TaskPath
        Task folder path (default: "\Microsoft\Windows\Win11Upgrade\")
    .OUTPUTS
        Boolean - True if task removed successfully, False otherwise
    .EXAMPLE
        Remove-Win11UpgradeTask
    #>
    [CmdletBinding()]
    [OutputType([Boolean])]
    Param(
        [Parameter(Mandatory=$false)]
        [String]$TaskName = "Windows11Upgrade",
        
        [Parameter(Mandatory=$false)]
        [String]$TaskPath = "\Microsoft\Windows\Win11Upgrade\"
    )
    
    try {
        Write-Log -Message "Removing Windows 11 upgrade scheduled task..." -Source 'Remove-Win11UpgradeTask'
        
        # Check if task exists
        $existingTask = Get-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath -ErrorAction SilentlyContinue
        if ($existingTask) {
            Unregister-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath -Confirm:$false
            Write-Log -Message "Scheduled task removed successfully" -Source 'Remove-Win11UpgradeTask'
            return $true
        } else {
            Write-Log -Message "Scheduled task does not exist" -Source 'Remove-Win11UpgradeTask'
            return $true
        }
    } catch {
        Write-Log -Message "Error removing scheduled task: $($_.Exception.Message)" -Severity 3 -Source 'Remove-Win11UpgradeTask'
        return $false
    }
}

Function Get-Win11UpgradeTask {
    <#
    .SYNOPSIS
        Gets the Windows 11 upgrade scheduled task information
    .DESCRIPTION
        Retrieves information about the Windows 11 upgrade scheduled task
    .PARAMETER TaskName
        Name of the scheduled task (default: "Windows11Upgrade")
    .PARAMETER TaskPath
        Task folder path (default: "\Microsoft\Windows\Win11Upgrade\")
    .OUTPUTS
        ScheduledTask object or $null if not found
    .EXAMPLE
        Get-Win11UpgradeTask
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$false)]
        [String]$TaskName = "Windows11Upgrade",
        
        [Parameter(Mandatory=$false)]
        [String]$TaskPath = "\Microsoft\Windows\Win11Upgrade\"
    )
    
    try {
        $task = Get-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath -ErrorAction SilentlyContinue
        if ($task) {
            Write-Log -Message "Found Windows 11 upgrade task. State: $($task.State)" -Source 'Get-Win11UpgradeTask'
            return $task
        } else {
            Write-Log -Message "Windows 11 upgrade task not found" -Source 'Get-Win11UpgradeTask'
            return $null
        }
    } catch {
        Write-Log -Message "Error getting scheduled task: $($_.Exception.Message)" -Severity 3 -Source 'Get-Win11UpgradeTask'
        return $null
    }
}