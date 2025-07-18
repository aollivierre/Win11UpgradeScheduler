$script:TaskName = 'TestWin11Upgrade'
$script:TaskPath = '\Test'

function Write-SchedulerLog {
    param($Message, $Severity = 'Information')
    # Minimal logging for test
}

function New-UpgradeSchedule {
    param($ScheduleTime, $PSADTPath)
    return @{Success = $true; TaskName = $script:TaskName}
}

function Get-UpgradeSchedule {
    return $null
}

Export-ModuleMember -Function *
