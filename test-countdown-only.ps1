# Test countdown dialog only
param(
    [string]$PSADTPath = "C:\code\Windows\Win11UpgradeScheduler-FINAL\src",
    [int]$Minutes = 1  # 1 minute for testing instead of 30
)

Write-Host "Loading PSADT toolkit..." -ForegroundColor Cyan
$toolkitPath = Join-Path -Path $PSADTPath -ChildPath "AppDeployToolkit\AppDeployToolkitMain.ps1"
. $toolkitPath

Write-Host "Showing countdown dialog for $Minutes minute(s)..." -ForegroundColor Yellow
Write-Host "You should see a dialog window now!" -ForegroundColor Green

# Show countdown
$result = Show-InstallationPrompt `
    -Message "Windows 11 upgrade will begin in $Minutes minute(s).`n`nPlease save your work. You can click 'Start Now' to begin immediately." `
    -ButtonRightText 'Start Now' `
    -ButtonLeftText 'OK' `
    -Icon Information `
    -Timeout ([timespan]::FromMinutes($Minutes).TotalSeconds) `
    -ExitOnTimeout $false

Write-Host "`nDialog closed!" -ForegroundColor Cyan
Write-Host "User clicked: $($global:psButtonClicked)" -ForegroundColor Yellow

if ($global:psButtonClicked -eq 'Start Now') {
    Write-Host "User wants to start immediately!" -ForegroundColor Green
} else {
    Write-Host "User clicked OK or countdown expired" -ForegroundColor Yellow
}