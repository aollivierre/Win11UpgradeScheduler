#region Module Header
<#
.SYNOPSIS
    Pre-Flight Checks Module for Windows 11 Upgrade (FINAL)
.DESCRIPTION
    Validates system readiness before Windows 11 upgrade by checking conditions that can fluctuate:
    - Windows version (soft warning for builds < 19041)
    - Disk space (with flexible thresholds)
    - Battery level (laptops)
    - Windows Update status
    - Pending reboot detection
    - System resources (CPU/Memory usage)
    
    NOTE: Hardware checks (TPM, CPU model, RAM size) should be done in detection phase,
    not pre-flight, as they don't change between scheduling and execution.
    
.NOTES
    Version:        2.1.0
    Updated:        2025-01-18
    Changes:        Added Windows version check (Phase 1 enhancement)
                   Issues soft warning for Windows 10 builds < 19041
                   Removed TPM checking (moved to detection phase)
                   Focus on fluctuating conditions only
#>
#endregion

#region Module Variables
$script:MinDiskSpaceGB = 25        # FAIL threshold
$script:WarnDiskSpaceGB = 50       # WARN threshold  
$script:OfficialDiskSpaceGB = 64   # Microsoft's official requirement (reference only)
$script:MinBatteryPercent = 50
$script:MinMemoryGB = 4
$script:LogPath = "$env:ProgramData\Win11UpgradeScheduler\Logs"
#endregion

#region Logging Function
function Write-PreFlightLog {
    <#
    .SYNOPSIS
        Writes a log entry for pre-flight checks
    .DESCRIPTION
        Creates timestamped log entries for pre-flight operations
    .PARAMETER Message
        The message to log
    .PARAMETER Severity
        Log severity level
    #>
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
    $logFile = Join-Path -Path $script:LogPath -ChildPath "PreFlightChecks_$(Get-Date -Format 'yyyyMMdd').log"
    $logEntry = "[$timestamp] [$Severity] $Message"
    
    Add-Content -Path $logFile -Value $logEntry -Force
}
#endregion

#region Check Functions
function Test-DiskSpace {
    <#
    .SYNOPSIS
        Checks available disk space on system drive with flexible thresholds
    .DESCRIPTION
        Ensures sufficient disk space for Windows 11 upgrade
        - Fails at < 25GB (absolute minimum)
        - Warns at 25-50GB (functional but not ideal)
        - Passes at > 50GB (recommended)
    .EXAMPLE
        Test-DiskSpace
    #>
    [CmdletBinding()]
    param()
    
    Write-PreFlightLog -Message "Checking disk space requirements"
    
    try {
        $systemDrive = $env:SystemDrive
        $disk = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DeviceID='$systemDrive'"
        
        if ($null -eq $disk) {
            Write-PreFlightLog -Message "Unable to query system drive information" -Severity Error
            return @{
                Passed = $false
                Message = "Unable to query system drive"
                FreeSpaceGB = 0
                RequiredGB = $script:MinDiskSpaceGB
                Severity = 'Error'
            }
        }
        
        $freeSpaceGB = [math]::Round($disk.FreeSpace / 1GB, 2)
        $totalSpaceGB = [math]::Round($disk.Size / 1GB, 2)
        $usedPercent = [math]::Round((($disk.Size - $disk.FreeSpace) / $disk.Size) * 100, 2)
        
        Write-PreFlightLog -Message "System drive $systemDrive - Total: ${totalSpaceGB}GB, Free: ${freeSpaceGB}GB, Used: ${usedPercent}%"
        
        if ($freeSpaceGB -lt $script:MinDiskSpaceGB) {
            Write-PreFlightLog -Message "FAIL: Insufficient disk space. Required: ${script:MinDiskSpaceGB}GB, Available: ${freeSpaceGB}GB" -Severity Error
            return @{
                Passed = $false
                Message = "Insufficient disk space. Need at least ${script:MinDiskSpaceGB}GB free, have ${freeSpaceGB}GB"
                FreeSpaceGB = $freeSpaceGB
                RequiredGB = $script:MinDiskSpaceGB
                Severity = 'Error'
            }
        }
        elseif ($freeSpaceGB -lt $script:WarnDiskSpaceGB) {
            Write-PreFlightLog -Message "WARNING: Low disk space. Available: ${freeSpaceGB}GB, Recommended: ${script:WarnDiskSpaceGB}GB" -Severity Warning
            return @{
                Passed = $true  # Still pass but with warning
                Message = "Low disk space warning. Have ${freeSpaceGB}GB free, recommended ${script:WarnDiskSpaceGB}GB for optimal upgrade experience"
                FreeSpaceGB = $freeSpaceGB
                RequiredGB = $script:WarnDiskSpaceGB
                Severity = 'Warning'
            }
        }
        
        return @{
            Passed = $true
            Message = "Sufficient disk space available (${freeSpaceGB}GB free)"
            FreeSpaceGB = $freeSpaceGB
            RequiredGB = $script:MinDiskSpaceGB
            Severity = 'Information'
        }
    }
    catch {
        Write-PreFlightLog -Message "Error checking disk space: $_" -Severity Error
        return @{
            Passed = $false
            Message = "Error checking disk space: $_"
            FreeSpaceGB = 0
            RequiredGB = $script:MinDiskSpaceGB
            Severity = 'Error'
        }
    }
}

function Test-BatteryLevel {
    <#
    .SYNOPSIS
        Checks battery level on laptops
    .DESCRIPTION
        Ensures sufficient battery charge for upgrade on portable devices.
        Desktops automatically pass this check.
    .EXAMPLE
        Test-BatteryLevel
    #>
    [CmdletBinding()]
    param()
    
    Write-PreFlightLog -Message "Checking battery level"
    
    try {
        # Check if system has a battery
        $battery = Get-CimInstance -ClassName Win32_Battery -ErrorAction SilentlyContinue
        
        if ($null -eq $battery) {
            Write-PreFlightLog -Message "No battery detected - system appears to be a desktop"
            return @{
                Passed = $true
                Message = "No battery detected (desktop system)"
                BatteryPercent = 100
                IsOnAC = $true
                Severity = 'Information'
            }
        }
        
        # Get battery status
        $batteryStatus = Get-CimInstance -ClassName BatteryStatus -Namespace root\wmi -ErrorAction SilentlyContinue |
            Select-Object -First 1
        
        if ($null -ne $batteryStatus) {
            $batteryPercent = $batteryStatus.RemainingCapacity / $batteryStatus.FullChargedCapacity * 100
            $batteryPercent = [math]::Round($batteryPercent, 0)
        }
        else {
            # Fallback method
            $batteryPercent = $battery.EstimatedChargeRemaining
        }
        
        # Check AC adapter status
        $acAdapter = Get-CimInstance -ClassName BatteryStaticData -Namespace root\wmi -ErrorAction SilentlyContinue
        $isOnAC = if ($null -ne $acAdapter) { $acAdapter.ACOnLine } else { $battery.BatteryStatus -eq 2 }
        
        Write-PreFlightLog -Message "Battery level: ${batteryPercent}%, AC Power: $isOnAC"
        
        if ($batteryPercent -lt $script:MinBatteryPercent -and -not $isOnAC) {
            Write-PreFlightLog -Message "Insufficient battery level and not on AC power" -Severity Warning
            return @{
                Passed = $false
                Message = "Battery level too low (${batteryPercent}%) and not connected to AC power. Connect to power or charge to at least ${script:MinBatteryPercent}%"
                BatteryPercent = $batteryPercent
                IsOnAC = $isOnAC
                Severity = 'Error'
            }
        }
        
        return @{
            Passed = $true
            Message = "Battery level acceptable"
            BatteryPercent = $batteryPercent
            IsOnAC = $isOnAC
            Severity = 'Information'
        }
    }
    catch {
        Write-PreFlightLog -Message "Error checking battery level: $_" -Severity Error
        # Don't fail on battery check errors
        return @{
            Passed = $true
            Message = "Unable to check battery level"
            BatteryPercent = 100
            IsOnAC = $true
            Severity = 'Warning'
        }
    }
}

function Test-WindowsUpdateStatus {
    <#
    .SYNOPSIS
        Checks if Windows Update is running
    .DESCRIPTION
        Ensures Windows Update is not currently installing updates to avoid conflicts
    .EXAMPLE
        Test-WindowsUpdateStatus
    #>
    [CmdletBinding()]
    param()
    
    Write-PreFlightLog -Message "Checking Windows Update status"
    
    try {
        # Check Windows Update service
        $wuService = Get-Service -Name wuauserv -ErrorAction SilentlyContinue
        
        if ($null -eq $wuService) {
            Write-PreFlightLog -Message "Windows Update service not found" -Severity Warning
            return @{
                Passed = $true
                Message = "Windows Update service not found"
                IsUpdating = $false
                Severity = 'Warning'
            }
        }
        
        # Check if updates are being installed
        $updateSession = New-Object -ComObject Microsoft.Update.Session
        $updateSearcher = $updateSession.CreateUpdateSearcher()
        
        # Check for updates in progress
        try {
            $searchResult = $updateSearcher.Search("IsInstalled=0")
            $updatesInProgress = $searchResult.Updates | Where-Object { $_.IsDownloaded -and -not $_.IsInstalled }
            
            if ($updatesInProgress.Count -gt 0) {
                Write-PreFlightLog -Message "Windows Updates in progress: $($updatesInProgress.Count) updates" -Severity Warning
                return @{
                    Passed = $false
                    Message = "Windows Updates are currently being installed. Please wait for completion."
                    IsUpdating = $true
                    UpdateCount = $updatesInProgress.Count
                    Severity = 'Error'
                }
            }
        }
        catch {
            Write-PreFlightLog -Message "Unable to query Windows Update status: $_" -Severity Warning
        }
        
        # Check TiWorker process (Windows Modules Installer Worker)
        $tiWorker = Get-Process -Name TiWorker -ErrorAction SilentlyContinue
        if ($tiWorker -and $tiWorker.CPU -gt 10) {
            Write-PreFlightLog -Message "Windows Modules Installer Worker is active" -Severity Warning
            return @{
                Passed = $false
                Message = "Windows is currently installing updates (TiWorker active)"
                IsUpdating = $true
                Severity = 'Error'
            }
        }
        
        return @{
            Passed = $true
            Message = "No Windows Updates in progress"
            IsUpdating = $false
            Severity = 'Information'
        }
    }
    catch {
        Write-PreFlightLog -Message "Error checking Windows Update status: $_" -Severity Error
        # Don't fail on update check errors
        return @{
            Passed = $true
            Message = "Unable to check Windows Update status"
            IsUpdating = $false
            Severity = 'Warning'
        }
    }
}

function Test-PendingReboot {
    <#
    .SYNOPSIS
        Checks for pending system reboots
    .DESCRIPTION
        Detects if system has pending reboots from various sources that could interfere with upgrade
    .EXAMPLE
        Test-PendingReboot
    #>
    [CmdletBinding()]
    param()
    
    Write-PreFlightLog -Message "Checking for pending reboots"
    
    $pendingReboot = $false
    $rebootReasons = @()
    
    try {
        # Check Component Based Servicing
        $cbsKey = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending'
        if (Test-Path -Path $cbsKey) {
            $pendingReboot = $true
            $rebootReasons += "Component Based Servicing"
            Write-PreFlightLog -Message "Pending reboot detected: Component Based Servicing" -Severity Warning
        }
        
        # Check Windows Update
        $wuKey = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired'
        if (Test-Path -Path $wuKey) {
            $pendingReboot = $true
            $rebootReasons += "Windows Update"
            Write-PreFlightLog -Message "Pending reboot detected: Windows Update" -Severity Warning
        }
        
        # Check Session Manager
        $smKey = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager'
        $pendingFileRename = Get-ItemProperty -Path $smKey -Name PendingFileRenameOperations -ErrorAction SilentlyContinue
        if ($pendingFileRename -and $pendingFileRename.PendingFileRenameOperations) {
            $pendingReboot = $true
            $rebootReasons += "Pending File Rename Operations"
            Write-PreFlightLog -Message "Pending reboot detected: File Rename Operations" -Severity Warning
        }
        
        # Check Computer Rename
        $activeComputerName = (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\ComputerName\ActiveComputerName' -Name ComputerName).ComputerName
        $pendingComputerName = (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\ComputerName\ComputerName' -Name ComputerName).ComputerName
        
        if ($activeComputerName -ne $pendingComputerName) {
            $pendingReboot = $true
            $rebootReasons += "Computer Rename"
            Write-PreFlightLog -Message "Pending reboot detected: Computer rename from $activeComputerName to $pendingComputerName" -Severity Warning
        }
        
        if ($pendingReboot) {
            return @{
                Passed = $false
                Message = "System has pending reboot: $($rebootReasons -join ', ')"
                PendingReboot = $true
                Reasons = $rebootReasons
                Severity = 'Error'
            }
        }
        
        return @{
            Passed = $true
            Message = "No pending reboots detected"
            PendingReboot = $false
            Reasons = @()
            Severity = 'Information'
        }
    }
    catch {
        Write-PreFlightLog -Message "Error checking pending reboot status: $_" -Severity Error
        # Don't fail on reboot check errors
        return @{
            Passed = $true
            Message = "Unable to check pending reboot status"
            PendingReboot = $false
            Reasons = @()
            Severity = 'Warning'
        }
    }
}

function Test-WindowsVersion {
    <#
    .SYNOPSIS
        Checks Windows version meets minimum requirements
    .DESCRIPTION
        Validates that Windows 10 build is 19041 (version 2004) or higher.
        Issues a WARNING only - does not block upgrade process.
        Windows 11 Installation Assistant will make final compatibility decision.
    .EXAMPLE
        Test-WindowsVersion
    #>
    [CmdletBinding()]
    param()
    
    Write-PreFlightLog -Message "Checking Windows version requirements"
    
    try {
        # Get Windows version info
        $os = Get-CimInstance -ClassName Win32_OperatingSystem
        $buildNumber = [int]$os.BuildNumber
        
        # Get more detailed version info
        $currentVersion = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name DisplayVersion -ErrorAction SilentlyContinue).DisplayVersion
        if ($null -eq $currentVersion) {
            $currentVersion = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name ReleaseId -ErrorAction SilentlyContinue).ReleaseId
        }
        
        $productName = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name ProductName -ErrorAction SilentlyContinue).ProductName
        
        Write-PreFlightLog -Message "Detected: $productName, Version: $currentVersion, Build: $buildNumber"
        
        # Check if already on Windows 11
        if ($buildNumber -ge 22000) {
            Write-PreFlightLog -Message "System is already running Windows 11 (Build: $buildNumber)"
            return @{
                Passed = $true
                Message = "Already running Windows 11"
                BuildNumber = $buildNumber
                Version = $currentVersion
                MinimumBuild = 19041
                Severity = 'Information'
            }
        }
        
        # Check Windows 10 minimum build requirement (19041 = version 2004)
        if ($buildNumber -lt 19041) {
            Write-PreFlightLog -Message "WARNING: Windows 10 build $buildNumber is below minimum requirement (19041)" -Severity Warning
            Write-PreFlightLog -Message "Windows 11 requires Windows 10 version 2004 or later" -Severity Warning
            Write-PreFlightLog -Message "Current version: $currentVersion (Build: $buildNumber)" -Severity Warning
            Write-PreFlightLog -Message "Proceeding anyway - Windows 11 Installation Assistant will verify final compatibility" -Severity Warning
            
            return @{
                Passed = $true  # Still pass but with warning
                Message = "Windows 10 build $buildNumber is below recommended minimum (19041). Windows 11 requires version 2004 or later. Proceeding - installer will verify compatibility."
                BuildNumber = $buildNumber
                Version = $currentVersion
                MinimumBuild = 19041
                Severity = 'Warning'
            }
        }
        
        # Build meets requirements
        return @{
            Passed = $true
            Message = "Windows version meets requirements (Build: $buildNumber)"
            BuildNumber = $buildNumber
            Version = $currentVersion
            MinimumBuild = 19041
            Severity = 'Information'
        }
    }
    catch {
        Write-PreFlightLog -Message "Error checking Windows version: $_" -Severity Warning
        # Don't fail on version check errors - let installer decide
        return @{
            Passed = $true
            Message = "Unable to verify Windows version. Proceeding - installer will verify compatibility."
            BuildNumber = 0
            Version = "Unknown"
            MinimumBuild = 19041
            Severity = 'Warning'
        }
    }
}

function Test-SystemResources {
    <#
    .SYNOPSIS
        Checks current system resource usage
    .DESCRIPTION
        Ensures system isn't under heavy load during upgrade.
        Checks CPU usage and available memory.
    .EXAMPLE
        Test-SystemResources
    #>
    [CmdletBinding()]
    param()
    
    Write-PreFlightLog -Message "Checking system resources"
    
    try {
        # Check CPU usage
        $cpuUsage = (Get-Counter '\Processor(_Total)\% Processor Time' -SampleInterval 2 -MaxSamples 3 |
            Select-Object -ExpandProperty CounterSamples |
            Select-Object -ExpandProperty CookedValue |
            Measure-Object -Average).Average
        
        $cpuUsage = [math]::Round($cpuUsage, 2)
        Write-PreFlightLog -Message "Average CPU usage: ${cpuUsage}%"
        
        # Check memory
        $os = Get-CimInstance -ClassName Win32_OperatingSystem
        $totalMemoryGB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
        $freeMemoryGB = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
        $usedMemoryPercent = [math]::Round((($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / $os.TotalVisibleMemorySize) * 100, 2)
        
        Write-PreFlightLog -Message "Memory - Total: ${totalMemoryGB}GB, Free: ${freeMemoryGB}GB, Used: ${usedMemoryPercent}%"
        
        # High CPU usage warning (but don't fail)
        if ($cpuUsage -gt 80) {
            Write-PreFlightLog -Message "High CPU usage detected: ${cpuUsage}%" -Severity Warning
            return @{
                Passed = $true  # Still pass but warn
                Message = "High CPU usage (${cpuUsage}%). Consider waiting for system to be less busy."
                TotalMemoryGB = $totalMemoryGB
                FreeMemoryGB = $freeMemoryGB
                CPUUsagePercent = $cpuUsage
                Severity = 'Warning'
            }
        }
        
        # Low free memory warning (but don't fail)
        if ($freeMemoryGB -lt 2) {
            Write-PreFlightLog -Message "Low free memory: ${freeMemoryGB}GB" -Severity Warning
            return @{
                Passed = $true  # Still pass but warn
                Message = "Low free memory (${freeMemoryGB}GB). Consider closing some applications."
                TotalMemoryGB = $totalMemoryGB
                FreeMemoryGB = $freeMemoryGB
                CPUUsagePercent = $cpuUsage
                Severity = 'Warning'
            }
        }
        
        return @{
            Passed = $true
            Message = "System resources are adequate"
            TotalMemoryGB = $totalMemoryGB
            FreeMemoryGB = $freeMemoryGB
            CPUUsagePercent = $cpuUsage
            Severity = 'Information'
        }
    }
    catch {
        Write-PreFlightLog -Message "Error checking system resources: $_" -Severity Error
        # Don't fail on resource check errors
        return @{
            Passed = $true
            Message = "Unable to check system resources"
            TotalMemoryGB = 0
            FreeMemoryGB = 0
            CPUUsagePercent = 0
            Severity = 'Warning'
        }
    }
}
#endregion

#region Main Check Function
function Test-SystemReadiness {
    <#
    .SYNOPSIS
        Performs all pre-flight checks for conditions that can fluctuate
    .DESCRIPTION
        Runs system readiness checks for things that can change between scheduling and execution.
        Does NOT check hardware (TPM, CPU, fixed RAM) as those should be in detection phase.
    .PARAMETER SkipBatteryCheck
        Skip battery check for testing
    .PARAMETER SkipUpdateCheck
        Skip Windows Update check for testing
    .EXAMPLE
        Test-SystemReadiness
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [switch]$SkipBatteryCheck,
        
        [Parameter(Mandatory=$false)]
        [switch]$SkipUpdateCheck
    )
    
    Write-PreFlightLog -Message ("=" * 60)
    Write-PreFlightLog -Message "Starting system readiness checks for fluctuating conditions"
    
    $results = @{
        IsReady = $true
        Issues = @()
        Warnings = @()
        Checks = @{}
    }
    
    # Run Windows version check (Phase 1 enhancement)
    Write-Verbose "Checking Windows version..."
    $versionCheck = Test-WindowsVersion
    $results.Checks['WindowsVersion'] = $versionCheck
    if ($versionCheck.Severity -eq 'Error') {
        $results.IsReady = $false
        $results.Issues += $versionCheck.Message
    }
    elseif ($versionCheck.Severity -eq 'Warning') {
        $results.Warnings += $versionCheck.Message
    }
    
    # Run disk space check
    Write-Verbose "Checking disk space..."
    $diskCheck = Test-DiskSpace
    $results.Checks['DiskSpace'] = $diskCheck
    if ($diskCheck.Severity -eq 'Error') {
        $results.IsReady = $false
        $results.Issues += $diskCheck.Message
    }
    elseif ($diskCheck.Severity -eq 'Warning') {
        $results.Warnings += $diskCheck.Message
    }
    
    # Run battery check
    if (-not $SkipBatteryCheck) {
        Write-Verbose "Checking battery level..."
        $batteryCheck = Test-BatteryLevel
        $results.Checks['Battery'] = $batteryCheck
        if ($batteryCheck.Severity -eq 'Error') {
            $results.IsReady = $false
            $results.Issues += $batteryCheck.Message
        }
        elseif ($batteryCheck.Severity -eq 'Warning') {
            $results.Warnings += $batteryCheck.Message
        }
    }
    
    # Run Windows Update check
    if (-not $SkipUpdateCheck) {
        Write-Verbose "Checking Windows Update status..."
        $updateCheck = Test-WindowsUpdateStatus
        $results.Checks['WindowsUpdate'] = $updateCheck
        if ($updateCheck.Severity -eq 'Error') {
            $results.IsReady = $false
            $results.Issues += $updateCheck.Message
        }
        elseif ($updateCheck.Severity -eq 'Warning') {
            $results.Warnings += $updateCheck.Message
        }
    }
    
    # Run pending reboot check
    Write-Verbose "Checking for pending reboots..."
    $rebootCheck = Test-PendingReboot
    $results.Checks['PendingReboot'] = $rebootCheck
    if ($rebootCheck.Severity -eq 'Error') {
        $results.IsReady = $false
        $results.Issues += $rebootCheck.Message
    }
    elseif ($rebootCheck.Severity -eq 'Warning') {
        $results.Warnings += $rebootCheck.Message
    }
    
    # Run system resources check
    Write-Verbose "Checking system resources..."
    $resourceCheck = Test-SystemResources
    $results.Checks['SystemResources'] = $resourceCheck
    if ($resourceCheck.Severity -eq 'Error') {
        $results.IsReady = $false
        $results.Issues += $resourceCheck.Message
    }
    elseif ($resourceCheck.Severity -eq 'Warning') {
        $results.Warnings += $resourceCheck.Message
    }
    
    # Log summary
    if ($results.IsReady) {
        Write-PreFlightLog -Message "All critical pre-flight checks passed - system is ready for upgrade"
        if ($results.Warnings.Count -gt 0) {
            Write-PreFlightLog -Message "$($results.Warnings.Count) warning(s) found:" -Severity Warning
            foreach ($warning in $results.Warnings) {
                Write-PreFlightLog -Message "  - $warning" -Severity Warning
            }
        }
    }
    else {
        Write-PreFlightLog -Message "Pre-flight checks failed - $($results.Issues.Count) critical issue(s) found" -Severity Warning
        foreach ($issue in $results.Issues) {
            Write-PreFlightLog -Message "  - $issue" -Severity Warning
        }
    }
    
    Write-PreFlightLog -Message "Completed system readiness checks"
    Write-PreFlightLog -Message ("=" * 60)
    
    return $results
}
#endregion

#region Module Export
Export-ModuleMember -Function @(
    'Test-SystemReadiness'
    'Test-WindowsVersion'
    'Test-DiskSpace'
    'Test-BatteryLevel'
    'Test-WindowsUpdateStatus'
    'Test-PendingReboot'
    'Test-SystemResources'
    'Write-PreFlightLog'
)
#endregion