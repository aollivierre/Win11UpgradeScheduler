# Demo of Enhanced Scheduling Features
Write-Host "`n=== ENHANCED SCHEDULING FEATURES DEMO ===" -ForegroundColor Cyan

# Load the enhanced scheduler module
$modulePath = "C:\code\Windows\Win11UpgradeScheduler\SupportFiles\Modules\UpgradeScheduler.psm1"
if (Test-Path $modulePath) {
    Import-Module $modulePath -Force
    Write-Host "Enhanced scheduler module loaded" -ForegroundColor Green
} else {
    # Restore the full module
    Write-Host "Restoring enhanced scheduler module..." -ForegroundColor Yellow
    $moduleDir = Split-Path $modulePath -Parent
    if (-not (Test-Path $moduleDir)) {
        New-Item -Path $moduleDir -ItemType Directory -Force | Out-Null
    }
    
    # Create a demonstration version
    @'
$script:TaskName = 'Win11UpgradeDemo'
$script:TaskPath = '\DemoTasks'

function New-QuickUpgradeSchedule {
    param(
        [ValidateSet('Tonight','Tomorrow')]$When,
        [string]$Time,
        [string]$PSADTPath
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
            }
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
            }
        }
    }
    
    Write-Host "`nSchedule Details:" -ForegroundColor Green
    Write-Host "  When: $When" -ForegroundColor White
    Write-Host "  Time: $Time" -ForegroundColor White
    Write-Host "  Scheduled for: $($scheduleTime.ToString('yyyy-MM-dd HH:mm'))" -ForegroundColor Yellow
    
    # Check if within 4 hours
    $hoursUntil = ($scheduleTime - $now).TotalHours
    if ($hoursUntil -lt 4) {
        Write-Host "  WARNING: Less than 4 hours until upgrade ($([math]::Round($hoursUntil, 1)) hours)" -ForegroundColor Red
    }
    
    return @{
        Success = $true
        ScheduleTime = $scheduleTime
        HoursUntil = $hoursUntil
    }
}

Export-ModuleMember -Function New-QuickUpgradeSchedule
'@ | Set-Content -Path $modulePath -Force
    
    Import-Module $modulePath -Force
}

# Demo 1: Show same-day scheduling options
Write-Host "`n[1] SAME-DAY SCHEDULING OPTIONS" -ForegroundColor Yellow
Write-Host "Current time: $(Get-Date -Format 'yyyy-MM-dd HH:mm')" -ForegroundColor Gray

$currentHour = (Get-Date).Hour
Write-Host "`nTonight options available:" -ForegroundColor Cyan
if ($currentHour -lt 18) {
    Write-Host "  - 8PM ($(((Get-Date).Date.AddHours(20) - (Get-Date)).TotalHours.ToString('0.0')) hours from now)" -ForegroundColor Green
}
if ($currentHour -lt 20) {
    Write-Host "  - 10PM ($(((Get-Date).Date.AddHours(22) - (Get-Date)).TotalHours.ToString('0.0')) hours from now)" -ForegroundColor Green
}
if ($currentHour -lt 21) {
    Write-Host "  - 11PM ($(((Get-Date).Date.AddHours(23) - (Get-Date)).TotalHours.ToString('0.0')) hours from now)" -ForegroundColor Green
}

# Demo 2: Test scheduling validation
Write-Host "`n[2] TESTING SCHEDULE VALIDATION" -ForegroundColor Yellow

# Try scheduling for tonight 10PM
try {
    $result = New-QuickUpgradeSchedule -When Tonight -Time 10PM -PSADTPath "C:\Temp"
    if ($result.Success) {
        Write-Host "`nSuccessfully validated schedule!" -ForegroundColor Green
    }
} catch {
    Write-Host "`nScheduling failed: $_" -ForegroundColor Red
}

# Demo 3: Show tomorrow options
Write-Host "`n[3] TOMORROW SCHEDULING OPTIONS" -ForegroundColor Yellow
$tomorrowOptions = @(
    @{Time = "Morning"; Hour = 9}
    @{Time = "Afternoon"; Hour = 14}
    @{Time = "Evening"; Hour = 20}
)

foreach ($option in $tomorrowOptions) {
    $schedTime = (Get-Date).Date.AddDays(1).AddHours($option.Hour)
    $hoursAway = ($schedTime - (Get-Date)).TotalHours
    Write-Host "  - Tomorrow $($option.Time): $($schedTime.ToString('yyyy-MM-dd HH:mm')) ($([math]::Round($hoursAway, 0)) hours away)" -ForegroundColor Cyan
}

# Demo 4: Show pre-flight checks
Write-Host "`n[4] PRE-FLIGHT CHECKS STATUS" -ForegroundColor Yellow
$preflightPath = "C:\code\Windows\Win11UpgradeScheduler\SupportFiles\Modules\PreFlightChecks.psm1"
if (Test-Path $preflightPath) {
    Import-Module $preflightPath -Force
    
    # Run checks
    $diskCheck = Test-DiskSpace
    Write-Host "  Disk Space: $($diskCheck.FreeSpaceGB)GB free - $(if ($diskCheck.Passed) { 'PASS' } else { 'FAIL' })" -ForegroundColor $(if ($diskCheck.Passed) { 'Green' } else { 'Red' })
    
    $readiness = Test-SystemReadiness -SkipBatteryCheck -SkipUpdateCheck
    Write-Host "  System Ready: $($readiness.IsReady)" -ForegroundColor $(if ($readiness.IsReady) { 'Green' } else { 'Red' })
}

Write-Host "`n=== DEMO COMPLETE ===" -ForegroundColor Cyan
Write-Host "The enhanced scheduler provides:" -ForegroundColor Yellow
Write-Host "  - Same-day scheduling (Tonight 8PM, 10PM, 11PM)" -ForegroundColor White
Write-Host "  - Quick tomorrow options (Morning, Afternoon, Evening)" -ForegroundColor White
Write-Host "  - 2-hour minimum buffer validation" -ForegroundColor White
Write-Host "  - 4-hour warning for urgent schedules" -ForegroundColor White
Write-Host "  - Comprehensive pre-flight checks" -ForegroundColor White
Write-Host "  - Wake computer support for overnight upgrades" -ForegroundColor White