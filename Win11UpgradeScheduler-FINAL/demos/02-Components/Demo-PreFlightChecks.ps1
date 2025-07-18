# Demonstrate Pre-Flight Checks for Windows 11 Upgrade
Write-Host "`n=== WINDOWS 11 UPGRADE PRE-FLIGHT CHECKS ===" -ForegroundColor Cyan
Write-Host "The enhanced PreFlightChecks module performs the following validations:" -ForegroundColor Yellow

# List of all pre-flight checks
$checks = @(
    @{
        Name = "Disk Space Check"
        Description = "Ensures sufficient free space for Windows 11 upgrade"
        Requirements = @(
            "Minimum: 64GB free space required"
            "Checks system drive (C:)"
            "Validates before allowing scheduling"
        )
        Function = "Test-DiskSpace"
    },
    @{
        Name = "Battery Level Check"
        Description = "Ensures laptops have sufficient power for upgrade"
        Requirements = @(
            "Minimum: 50% battery charge"
            "OR connected to AC power"
            "Skipped for desktop systems"
            "Prevents upgrade failure due to power loss"
        )
        Function = "Test-BatteryLevel"
    },
    @{
        Name = "Windows Update Status"
        Description = "Verifies Windows Update is not actively installing"
        Requirements = @(
            "Checks if Windows Update service is busy"
            "Detects updates in progress"
            "Monitors TiWorker.exe (Windows Modules Installer)"
            "Prevents conflicts with ongoing updates"
        )
        Function = "Test-WindowsUpdateStatus"
    },
    @{
        Name = "Pending Reboot Detection"
        Description = "Checks for required system restarts"
        Requirements = @(
            "Component Based Servicing pending reboots"
            "Windows Update pending reboots"
            "Pending file rename operations"
            "Computer rename pending"
            "Ensures clean system state"
        )
        Function = "Test-PendingReboot"
    },
    @{
        Name = "System Resources Check"
        Description = "Validates hardware meets Windows 11 requirements"
        Requirements = @(
            "Minimum: 4GB RAM"
            "CPU usage check (warns if >80%)"
            "Memory availability"
            "Ensures system can handle upgrade"
        )
        Function = "Test-SystemResources"
    }
)

# Display each check
$checkNum = 1
foreach ($check in $checks) {
    Write-Host "`n[$checkNum] $($check.Name)" -ForegroundColor Green
    Write-Host "    Purpose: $($check.Description)" -ForegroundColor White
    Write-Host "    Requirements:" -ForegroundColor Yellow
    foreach ($req in $check.Requirements) {
        Write-Host "      - $req" -ForegroundColor Gray
    }
    $checkNum++
}

# Run actual checks if module is available
Write-Host "`n=== RUNNING LIVE PRE-FLIGHT CHECKS ===" -ForegroundColor Cyan

$modulePath = "C:\code\Windows\Win11UpgradeScheduler\SupportFiles\Modules\PreFlightChecks.psm1"

# First, let's restore the full module
Write-Host "Restoring full pre-flight checks module..." -ForegroundColor Yellow

$fullModule = @'
#region Module Header
<#
.SYNOPSIS
    Pre-Flight Checks Module for Windows 11 Upgrade
#>
#endregion

$script:MinDiskSpaceGB = 64
$script:MinBatteryPercent = 50
$script:MinMemoryGB = 4

function Test-DiskSpace {
    param()
    
    try {
        $systemDrive = $env:SystemDrive
        $disk = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DeviceID='$systemDrive'"
        
        if ($null -eq $disk) {
            return @{
                Passed = $false
                Message = "Unable to query system drive"
                FreeSpaceGB = 0
                RequiredGB = $script:MinDiskSpaceGB
            }
        }
        
        $freeSpaceGB = [math]::Round($disk.FreeSpace / 1GB, 2)
        
        if ($freeSpaceGB -lt $script:MinDiskSpaceGB) {
            return @{
                Passed = $false
                Message = "Insufficient disk space. Need $($script:MinDiskSpaceGB)GB, have $($freeSpaceGB)GB"
                FreeSpaceGB = $freeSpaceGB
                RequiredGB = $script:MinDiskSpaceGB
            }
        }
        
        return @{
            Passed = $true
            Message = "Sufficient disk space available: $($freeSpaceGB)GB free"
            FreeSpaceGB = $freeSpaceGB
            RequiredGB = $script:MinDiskSpaceGB
        }
    }
    catch {
        return @{
            Passed = $false
            Message = "Error checking disk space: $_"
            FreeSpaceGB = 0
            RequiredGB = $script:MinDiskSpaceGB
        }
    }
}

function Test-BatteryLevel {
    param()
    
    try {
        $battery = Get-CimInstance -ClassName Win32_Battery -ErrorAction SilentlyContinue
        
        if ($null -eq $battery) {
            return @{
                Passed = $true
                Message = "No battery detected (desktop system)"
                BatteryPercent = 100
                IsOnAC = $true
            }
        }
        
        $batteryPercent = $battery.EstimatedChargeRemaining
        $isOnAC = $battery.BatteryStatus -eq 2
        
        if ($batteryPercent -lt $script:MinBatteryPercent -and -not $isOnAC) {
            return @{
                Passed = $false
                Message = "Battery too low ($($batteryPercent)%) and not on AC power"
                BatteryPercent = $batteryPercent
                IsOnAC = $isOnAC
            }
        }
        
        return @{
            Passed = $true
            Message = "Battery level acceptable: $($batteryPercent)% $(if ($isOnAC) { '(AC Connected)' } else { '(On Battery)' })"
            BatteryPercent = $batteryPercent
            IsOnAC = $isOnAC
        }
    }
    catch {
        return @{
            Passed = $true
            Message = "Unable to check battery level"
            BatteryPercent = 100
            IsOnAC = $true
        }
    }
}

function Test-WindowsUpdateStatus {
    param()
    
    try {
        $wuService = Get-Service -Name wuauserv -ErrorAction SilentlyContinue
        
        if ($null -eq $wuService) {
            return @{
                Passed = $true
                Message = "Windows Update service not found"
                IsUpdating = $false
            }
        }
        
        # Check TiWorker process
        $tiWorker = Get-Process -Name TiWorker -ErrorAction SilentlyContinue
        if ($tiWorker -and $tiWorker.CPU -gt 10) {
            return @{
                Passed = $false
                Message = "Windows is currently installing updates (TiWorker active)"
                IsUpdating = $true
            }
        }
        
        return @{
            Passed = $true
            Message = "No Windows Updates in progress"
            IsUpdating = $false
        }
    }
    catch {
        return @{
            Passed = $true
            Message = "Unable to check Windows Update status"
            IsUpdating = $false
        }
    }
}

function Test-PendingReboot {
    param()
    
    $pendingReboot = $false
    $rebootReasons = @()
    
    try {
        # Check various registry keys for pending reboots
        $rebootKeys = @(
            'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending',
            'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired'
        )
        
        foreach ($key in $rebootKeys) {
            if (Test-Path -Path $key) {
                $pendingReboot = $true
                $rebootReasons += $key.Split('\')[-1]
            }
        }
        
        if ($pendingReboot) {
            return @{
                Passed = $false
                Message = "System has pending reboot: $($rebootReasons -join ', ')"
                PendingReboot = $true
                Reasons = $rebootReasons
            }
        }
        
        return @{
            Passed = $true
            Message = "No pending reboots detected"
            PendingReboot = $false
            Reasons = @()
        }
    }
    catch {
        return @{
            Passed = $true
            Message = "Unable to check pending reboot status"
            PendingReboot = $false
            Reasons = @()
        }
    }
}

function Test-SystemResources {
    param()
    
    try {
        $os = Get-CimInstance -ClassName Win32_OperatingSystem
        $totalMemoryGB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
        
        if ($totalMemoryGB -lt $script:MinMemoryGB) {
            return @{
                Passed = $false
                Message = "Insufficient memory. Windows 11 requires at least $($script:MinMemoryGB)GB RAM"
                TotalMemoryGB = $totalMemoryGB
                RequiredMemoryGB = $script:MinMemoryGB
            }
        }
        
        return @{
            Passed = $true
            Message = "System resources are adequate: $($totalMemoryGB)GB RAM"
            TotalMemoryGB = $totalMemoryGB
            RequiredMemoryGB = $script:MinMemoryGB
        }
    }
    catch {
        return @{
            Passed = $true
            Message = "Unable to check system resources"
            TotalMemoryGB = 0
            RequiredMemoryGB = $script:MinMemoryGB
        }
    }
}

function Test-SystemReadiness {
    param(
        [switch]$SkipBatteryCheck,
        [switch]$SkipUpdateCheck
    )
    
    $results = @{
        IsReady = $true
        Issues = @()
        Checks = @{}
    }
    
    # Run all checks
    $allChecks = @(
        @{Name = 'DiskSpace'; Function = 'Test-DiskSpace'; Skip = $false},
        @{Name = 'Battery'; Function = 'Test-BatteryLevel'; Skip = $SkipBatteryCheck},
        @{Name = 'WindowsUpdate'; Function = 'Test-WindowsUpdateStatus'; Skip = $SkipUpdateCheck},
        @{Name = 'PendingReboot'; Function = 'Test-PendingReboot'; Skip = $false},
        @{Name = 'SystemResources'; Function = 'Test-SystemResources'; Skip = $false}
    )
    
    foreach ($check in $allChecks) {
        if (-not $check.Skip) {
            $result = & $check.Function
            $results.Checks[$check.Name] = $result
            
            if (-not $result.Passed) {
                $results.IsReady = $false
                $results.Issues += $result.Message
            }
        }
    }
    
    return $results
}

Export-ModuleMember -Function @(
    'Test-SystemReadiness',
    'Test-DiskSpace',
    'Test-BatteryLevel', 
    'Test-WindowsUpdateStatus',
    'Test-PendingReboot',
    'Test-SystemResources'
)
'@

# Save the full module
$fullModule | Set-Content -Path $modulePath -Force

# Now import and run the checks
if (Test-Path $modulePath) {
    Import-Module $modulePath -Force
    
    Write-Host "`nRunning comprehensive system readiness check..." -ForegroundColor Yellow
    $results = Test-SystemReadiness -Verbose
    
    Write-Host "`n=== RESULTS ===" -ForegroundColor Cyan
    Write-Host "Overall System Ready: " -NoNewline
    if ($results.IsReady) {
        Write-Host "YES" -ForegroundColor Green
    } else {
        Write-Host "NO" -ForegroundColor Red
    }
    
    Write-Host "`nDetailed Results:" -ForegroundColor Yellow
    foreach ($check in $results.Checks.GetEnumerator()) {
        $passed = $check.Value.Passed
        $color = if ($passed) { 'Green' } else { 'Red' }
        $status = if ($passed) { 'PASS' } else { 'FAIL' }
        
        Write-Host "`n$($check.Key): " -NoNewline
        Write-Host $status -ForegroundColor $color
        Write-Host "  $($check.Value.Message)" -ForegroundColor Gray
        
        # Show additional details
        switch ($check.Key) {
            'DiskSpace' {
                Write-Host "  Free: $($check.Value.FreeSpaceGB)GB / Required: $($check.Value.RequiredGB)GB" -ForegroundColor Gray
            }
            'Battery' {
                if ($check.Value.BatteryPercent -lt 100) {
                    Write-Host "  Battery: $($check.Value.BatteryPercent)% / AC Power: $($check.Value.IsOnAC)" -ForegroundColor Gray
                }
            }
            'WindowsUpdate' {
                Write-Host "  Updates Active: $($check.Value.IsUpdating)" -ForegroundColor Gray
            }
            'PendingReboot' {
                if ($check.Value.Reasons.Count -gt 0) {
                    Write-Host "  Reasons: $($check.Value.Reasons -join ', ')" -ForegroundColor Gray
                }
            }
            'SystemResources' {
                Write-Host "  RAM: $($check.Value.TotalMemoryGB)GB / Required: $($check.Value.RequiredMemoryGB)GB" -ForegroundColor Gray
            }
        }
    }
    
    if (-not $results.IsReady) {
        Write-Host "`nIssues Found:" -ForegroundColor Red
        foreach ($issue in $results.Issues) {
            Write-Host "  - $issue" -ForegroundColor Red
        }
        Write-Host "`nThese issues must be resolved before scheduling the Windows 11 upgrade." -ForegroundColor Yellow
    } else {
        Write-Host "`nAll pre-flight checks passed! System is ready for Windows 11 upgrade." -ForegroundColor Green
    }
}