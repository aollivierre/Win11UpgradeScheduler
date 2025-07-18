<#
.SYNOPSIS
    Quick start demo for Windows 11 Upgrade Scheduler
.DESCRIPTION
    Demonstrates the basic usage of the Windows 11 Upgrade Scheduler
#>
# Import the required modules
$modulePath = "..\..\src\SupportFiles\Modules"
Import-Module "$modulePath\01-UpgradeScheduler.psm1" -Force
Import-Module "$modulePath\02-PreFlightChecks.psm1" -Force
# Show the calendar picker
Write-Host "Launching Windows 11 Upgrade Scheduler..." -ForegroundColor Cyan
& "..\..\src\SupportFiles\UI\01-Show-EnhancedCalendarPicker.ps1"
Write-Host "`nFor full deployment, run the main Deploy-Application.ps1 script." -ForegroundColor Green
