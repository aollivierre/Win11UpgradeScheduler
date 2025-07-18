<#
.SYNOPSIS
    Test the fixed wrapper countdown functionality
#>

Write-Host "Testing fixed wrapper countdown..." -ForegroundColor Green
Write-Host "This will simulate running as SYSTEM with Execute-ProcessAsUser" -ForegroundColor Yellow

# Run the wrapper with a short countdown for testing
& "$PSScriptRoot\SupportFiles\ScheduledTaskWrapper.ps1" `
    -PSADTPath $PSScriptRoot `
    -DeploymentType Install `
    -DeployMode Interactive

Write-Host "`nTest complete. Check the logs at: $env:ProgramData\Win11UpgradeScheduler\Logs" -ForegroundColor Cyan