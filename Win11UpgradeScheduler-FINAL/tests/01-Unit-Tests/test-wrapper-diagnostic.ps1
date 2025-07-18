# Diagnostic test for scheduled task wrapper behavior
param(
    [string]$PSADTPath = "C:\code\Windows\Win11UpgradeScheduler-FINAL\src"
)

Write-Host "=== DIAGNOSTIC TEST ===" -ForegroundColor Cyan

# 1. Check user session
Write-Host "`n1. Checking User Session:" -ForegroundColor Yellow
$explorerProcesses = Get-CimInstance -ClassName Win32_Process -Filter "Name = 'explorer.exe'" |
    Where-Object { $_.SessionId -ne 0 }
Write-Host "   Explorer processes: $($explorerProcesses.Count)"

$quser = @(quser 2>$null)
Write-Host "   Quser output:"
$quser | ForEach-Object { Write-Host "      $_" }

$isAttended = $explorerProcesses -or ($quser | Where-Object { $_ -match 'console|rdp' })
Write-Host "   Result: $(if ($isAttended) { 'ATTENDED SESSION' } else { 'UNATTENDED SESSION' })" -ForegroundColor $(if ($isAttended) { 'Green' } else { 'Red' })

# 2. Check pre-flight module
Write-Host "`n2. Checking Pre-Flight Module:" -ForegroundColor Yellow
$preFlightPath = Join-Path -Path $PSADTPath -ChildPath 'SupportFiles\Modules\02-PreFlightChecks.psm1'
if (Test-Path $preFlightPath) {
    Write-Host "   Module found: $preFlightPath" -ForegroundColor Green
    
    # Try to import and run
    try {
        Import-Module $preFlightPath -Force
        Write-Host "   Module imported successfully" -ForegroundColor Green
        
        Write-Host "   Running Test-SystemReadiness..." -ForegroundColor Cyan
        $result = Test-SystemReadiness -Verbose:$false
        Write-Host "   Ready: $($result.IsReady)" -ForegroundColor $(if ($result.IsReady) { 'Green' } else { 'Red' })
        if (-not $result.IsReady) {
            Write-Host "   Issues:" -ForegroundColor Red
            $result.Issues | ForEach-Object { Write-Host "      - $_" -ForegroundColor Red }
        }
    }
    catch {
        Write-Host "   ERROR: $_" -ForegroundColor Red
    }
} else {
    Write-Host "   Module NOT found!" -ForegroundColor Red
}

# 3. Check PSADT
Write-Host "`n3. Checking PSADT:" -ForegroundColor Yellow
$deployScript = Join-Path -Path $PSADTPath -ChildPath 'Deploy-Application.ps1'
if (Test-Path $deployScript) {
    Write-Host "   Deploy-Application.ps1 found" -ForegroundColor Green
} else {
    Write-Host "   Deploy-Application.ps1 NOT found!" -ForegroundColor Red
}

# 4. Expected behavior
Write-Host "`n4. EXPECTED BEHAVIOR:" -ForegroundColor Yellow
if ($isAttended) {
    Write-Host "   - You SHOULD see a 30-minute countdown dialog" -ForegroundColor Cyan
    Write-Host "   - Dialog title: 'Windows 11 upgrade will begin in 30 minutes'" -ForegroundColor Cyan
    Write-Host "   - Options: 'OK' button and 'Start Now' button" -ForegroundColor Cyan
    Write-Host "   - After countdown/click, PSADT UI should show upgrade progress" -ForegroundColor Cyan
} else {
    Write-Host "   - NO UI will be shown (unattended mode)" -ForegroundColor Cyan
    Write-Host "   - Upgrade will start immediately in background" -ForegroundColor Cyan
}

Write-Host "`n5. To see UI dialogs, ensure:" -ForegroundColor Yellow
Write-Host "   - You are logged in interactively (not just command line)" -ForegroundColor White
Write-Host "   - Explorer.exe is running for your session" -ForegroundColor White
Write-Host "   - You have a desktop session (RDP or console)" -ForegroundColor White
Write-Host "   - DeployMode is 'Interactive' (not 'Silent')" -ForegroundColor White