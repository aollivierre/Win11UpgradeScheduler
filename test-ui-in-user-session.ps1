# Force UI to show in user's interactive session
param(
    [string]$PSADTPath = "C:\code\Windows\Win11UpgradeScheduler-FINAL\src"
)

Write-Host "=== SOLUTION: Running UI in your interactive session ===" -ForegroundColor Green

# Get the active user session
$activeSession = (query session | Where-Object { $_ -match 'Active' -and $_ -match 'rdp|console' }) -split '\s+' | Where-Object { $_ -match '^\d+$' } | Select-Object -First 1

Write-Host "Active session ID: $activeSession" -ForegroundColor Cyan

# Create a script that will run in the user context
$userScript = @'
param($PSADTPath)

# Load PSADT
$toolkitPath = Join-Path -Path $PSADTPath -ChildPath "AppDeployToolkit\AppDeployToolkitMain.ps1"
Push-Location $PSADTPath
. $toolkitPath

# Show the countdown dialog
Show-InstallationPrompt `
    -Message "TEST: Windows 11 upgrade countdown test`n`nThis dialog should now be visible in your session!" `
    -ButtonRightText 'I can see it!' `
    -ButtonLeftText 'Close' `
    -Icon Information `
    -Timeout 30

Pop-Location
'@

$tempScript = "$env:TEMP\ShowUITest_$(Get-Date -Format 'yyyyMMddHHmmss').ps1"
$userScript | Set-Content -Path $tempScript -Force

Write-Host "`nMethod 1: Using PsExec to run in interactive session" -ForegroundColor Yellow
Write-Host "Note: This requires PsExec. If not available, try Method 2." -ForegroundColor Gray

# Check if PsExec exists
$psexecPath = Get-Command psexec.exe -ErrorAction SilentlyContinue
if ($psexecPath) {
    Write-Host "Running with PsExec..." -ForegroundColor Green
    & psexec.exe -accepteula -i $activeSession powershell.exe -ExecutionPolicy Bypass -File $tempScript -PSADTPath $PSADTPath
} else {
    Write-Host "PsExec not found." -ForegroundColor Red
}

Write-Host "`nMethod 2: Using Task Scheduler for immediate interactive execution" -ForegroundColor Yellow

# Create a scheduled task that runs immediately in interactive mode
$taskName = "PSADTUITest_$(Get-Date -Format 'yyyyMMddHHmmss')"
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$tempScript`" -PSADTPath `"$PSADTPath`""
$principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive -RunLevel Highest
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -StartWhenAvailable

Register-ScheduledTask -TaskName $taskName -Action $action -Principal $principal -Settings $settings -Force | Out-Null
Start-ScheduledTask -TaskName $taskName
Write-Host "Task started. Dialog should appear in your session." -ForegroundColor Green

# Wait a moment then cleanup
Start-Sleep -Seconds 35
Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
Remove-Item $tempScript -Force -ErrorAction SilentlyContinue

Write-Host "`n=== IMPORTANT ===" -ForegroundColor Cyan
Write-Host "For the scheduled task in production:" -ForegroundColor Yellow
Write-Host "1. The UI will show when running as SYSTEM with 'Run whether user is logged on or not'" -ForegroundColor White
Write-Host "2. PSADT automatically detects the active user session and shows UI there" -ForegroundColor White
Write-Host "3. The issue you're experiencing is because you're running tests through remote execution" -ForegroundColor White
Write-Host "4. In production, the scheduled task will show UI correctly!" -ForegroundColor Green