<#
.SYNOPSIS
    Launch Windows 11 Upgrade Scheduler - Enhanced PSADT Implementation
.DESCRIPTION
    Quick launcher for the organized Win11 Upgrade Scheduler project
#>

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('Deploy','Demo','Test','Docs')]
    [string]$Mode = 'Demo'
)

Write-Host "`n=== Windows 11 Upgrade Scheduler Launcher ===" -ForegroundColor Cyan
Write-Host "Organized Project Structure v2.0" -ForegroundColor Yellow

$projectRoot = $PSScriptRoot

switch ($Mode) {
    'Deploy' {
        Write-Host "`nLaunching Enhanced PSADT Deployment..." -ForegroundColor Green
        Write-Host "This will start the full Windows 11 upgrade scheduler" -ForegroundColor Gray
        
        Set-Location "$projectRoot\src"
        & powershell.exe -ExecutionPolicy Bypass -File ".\Deploy-Application-Enhanced.ps1" -DeploymentType Install -DeployMode Interactive
    }
    
    'Demo' {
        Write-Host "`nAvailable Demonstrations:" -ForegroundColor Green
        Write-Host "1. Individual Components Demo" -ForegroundColor White
        Write-Host "2. Enhanced Calendar Picker" -ForegroundColor White
        Write-Host "3. Pre-Flight Checks" -ForegroundColor White
        Write-Host "4. Full Workflow Demo" -ForegroundColor White
        
        $choice = Read-Host "`nSelect demo (1-4)"
        
        switch ($choice) {
            '1' { & "$projectRoot\demos\01-Components\03-Demo-Individual-Components.ps1" }
            '2' { & "$projectRoot\src\SupportFiles\UI\Show-EnhancedCalendarPicker.ps1" }
            '3' { & "$projectRoot\demos\01-Components\04-Show-PreFlightChecks.ps1" }
            '4' { & "$projectRoot\demos\02-Workflow\01-Demo-Full-Integration.ps1" }
            default { Write-Host "Invalid choice" -ForegroundColor Red }
        }
    }
    
    'Test' {
        Write-Host "`nRunning Validation Tests..." -ForegroundColor Green
        & "$projectRoot\tests\03-Validation\03-Validate-Enhancements.ps1"
    }
    
    'Docs' {
        Write-Host "`nProject Documentation:" -ForegroundColor Green
        Write-Host "`nMain Documentation:" -ForegroundColor Yellow
        Write-Host "  - README.md - Project overview" -ForegroundColor Gray
        Write-Host "  - PROJECT_MAP.md - Complete project structure" -ForegroundColor Gray
        
        Write-Host "`nDocumentation Folders:" -ForegroundColor Yellow
        Write-Host "  - docs\01-Requirements\ - Business requirements" -ForegroundColor Gray
        Write-Host "  - docs\02-Implementation\ - Implementation details" -ForegroundColor Gray
        Write-Host "  - docs\03-Testing\ - Test results" -ForegroundColor Gray
        Write-Host "  - docs\04-Deployment\ - Deployment guides" -ForegroundColor Gray
        
        Write-Host "`nOpening project root in explorer..." -ForegroundColor Cyan
        Start-Process explorer.exe $projectRoot
    }
}

Write-Host "`nProject Root: $projectRoot" -ForegroundColor Gray
Write-Host "Use -Mode parameter to select: Deploy, Demo, Test, or Docs" -ForegroundColor Gray