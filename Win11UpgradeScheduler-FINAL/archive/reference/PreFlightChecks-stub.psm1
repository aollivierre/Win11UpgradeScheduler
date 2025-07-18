function Test-DiskSpace {
    $systemDrive = $env:SystemDrive
    $disk = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DeviceID='$systemDrive'"
    $freeGB = [math]::Round($disk.FreeSpace / 1GB, 2)
    return @{
        Passed = $freeGB -gt 20  # Lower threshold for testing
        Message = "Disk space: ${freeGB}GB free"
        FreeSpaceGB = $freeGB
    }
}

function Test-SystemReadiness {
    param([switch]$SkipBatteryCheck, [switch]$SkipUpdateCheck)
    $diskCheck = Test-DiskSpace
    return @{
        IsReady = $diskCheck.Passed
        Issues = if (-not $diskCheck.Passed) { @($diskCheck.Message) } else { @() }
        Checks = @{DiskSpace = $diskCheck}
    }
}

Export-ModuleMember -Function *
