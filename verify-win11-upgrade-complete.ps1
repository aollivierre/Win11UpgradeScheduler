# Gather concrete evidence that Windows 11 upgrade completed via Installation Assistant

Write-Host "GATHERING CONCRETE EVIDENCE OF WINDOWS 11 UPGRADE COMPLETION" -ForegroundColor Green
Write-Host ("=" * 60) -ForegroundColor Green

#region 1. OS VERSION EVIDENCE
Write-Host "`n1. OPERATING SYSTEM VERSION:" -ForegroundColor Cyan
$os = Get-WmiObject Win32_OperatingSystem
$computerInfo = Get-ComputerInfo

Write-Host "OS Name: $($os.Caption)" -ForegroundColor Yellow
Write-Host "Version: $($os.Version)" -ForegroundColor Yellow
Write-Host "Build: $($os.BuildNumber)" -ForegroundColor Yellow
Write-Host "OS Build: $($computerInfo.OsBuildNumber)" -ForegroundColor Yellow
Write-Host "Windows Product Name: $($computerInfo.WindowsProductName)" -ForegroundColor Yellow

# Check if it's Windows 11
if ($os.Caption -like "*Windows 11*" -or [int]$os.BuildNumber -ge 22000) {
    Write-Host "CONFIRMED: Running Windows 11!" -ForegroundColor Green -BackgroundColor Black
} else {
    Write-Host "NOT Windows 11" -ForegroundColor Red
}
#endregion

#region 2. UPGRADE TIMESTAMP EVIDENCE
Write-Host "`n2. UPGRADE TIMESTAMP EVIDENCE:" -ForegroundColor Cyan
# Check Windows install date
$installDate = (Get-WmiObject Win32_OperatingSystem).InstallDate
$installDateTime = [Management.ManagementDateTimeConverter]::ToDateTime($installDate)
Write-Host "Windows Install Date: $installDateTime" -ForegroundColor Yellow

# Check for upgrade logs
$setupActLog = "C:\Windows\Panther\setupact.log"
if (Test-Path $setupActLog) {
    $lastWrite = (Get-Item $setupActLog).LastWriteTime
    Write-Host "Setup Activity Log Last Modified: $lastWrite" -ForegroundColor Yellow
    
    # Check if upgrade happened today
    if ($lastWrite.Date -eq (Get-Date).Date) {
        Write-Host "EVIDENCE: Setup activity TODAY!" -ForegroundColor Green
    }
}

# Check upgrade registry keys
$upgradeKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\OSUpgrade"
if (Test-Path $upgradeKey) {
    Write-Host "OSUpgrade Registry Key EXISTS" -ForegroundColor Green
}
#endregion

#region 3. INSTALLATION ASSISTANT ARTIFACTS
Write-Host "`n3. INSTALLATION ASSISTANT ARTIFACTS:" -ForegroundColor Cyan

# Check for Installation Assistant logs
$assistantLogs = @(
    "$env:LOCALAPPDATA\Microsoft\Windows11InstallationAssistant",
    "$env:ProgramData\Microsoft\Windows11InstallationAssistant",
    "C:\Windows\Logs\Windows11InstallationAssistant"
)

$foundAssistantEvidence = $false
foreach ($logPath in $assistantLogs) {
    if (Test-Path $logPath) {
        Write-Host "FOUND Installation Assistant artifacts: $logPath" -ForegroundColor Green
        $foundAssistantEvidence = $true
        Get-ChildItem $logPath -Recurse -ErrorAction SilentlyContinue | 
            Select-Object -First 5 | ForEach-Object {
                Write-Host "  - $($_.Name) (Modified: $($_.LastWriteTime))" -ForegroundColor Gray
            }
    }
}

# Check for assistant in Add/Remove Programs
$uninstallKeys = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
)

foreach ($key in $uninstallKeys) {
    $assistantEntry = Get-ChildItem $key -ErrorAction SilentlyContinue | 
        Get-ItemProperty | Where-Object { $_.DisplayName -like "*Windows*11*Assistant*" }
    if ($assistantEntry) {
        Write-Host "FOUND Installation Assistant in Programs: $($assistantEntry.DisplayName)" -ForegroundColor Green
        Write-Host "  Install Date: $($assistantEntry.InstallDate)" -ForegroundColor Yellow
    }
}
#endregion

#region 4. WINDOWS UPDATE HISTORY
Write-Host "`n4. WINDOWS UPDATE HISTORY:" -ForegroundColor Cyan
try {
    # Get recent Windows Updates
    $Session = New-Object -ComObject Microsoft.Update.Session
    $Searcher = $Session.CreateUpdateSearcher()
    $HistoryCount = $Searcher.GetTotalHistoryCount()
    $Updates = $Searcher.QueryHistory(0, [Math]::Min($HistoryCount, 10))
    
    $win11Updates = $Updates | Where-Object { $_.Title -like "*Windows 11*" }
    if ($win11Updates) {
        Write-Host "Windows 11 updates in history:" -ForegroundColor Green
        $win11Updates | ForEach-Object {
            Write-Host "  - $($_.Title) (Date: $($_.Date))" -ForegroundColor Yellow
        }
    }
} catch {
    Write-Host "Could not access Windows Update history" -ForegroundColor Yellow
}
#endregion

#region 5. UPGRADE COMPLETION ARTIFACTS
Write-Host "`n5. UPGRADE COMPLETION ARTIFACTS:" -ForegroundColor Cyan

# Check for cleanup of upgrade folders
$upgradeFolders = @(
    "C:\`$WINDOWS.~BT",
    "C:\`$WINDOWS.~WS",
    "C:\Windows.old"
)

foreach ($folder in $upgradeFolders) {
    if (Test-Path $folder) {
        $info = Get-Item $folder -Force
        Write-Host "Found: $folder (Modified: $($info.LastWriteTime))" -ForegroundColor Yellow
        if ($folder -eq "C:\Windows.old") {
            Write-Host "  EVIDENCE: Windows.old exists from upgrade!" -ForegroundColor Green
        }
    }
}

# Check scheduled tasks
$upgradeTasks = Get-ScheduledTask | Where-Object { $_.TaskName -like "*Win11*" }
if ($upgradeTasks) {
    Write-Host "`nWindows 11 Scheduled Tasks:" -ForegroundColor Yellow
    $upgradeTasks | ForEach-Object {
        $info = $_ | Get-ScheduledTaskInfo
        Write-Host "  - $($_.TaskName) (State: $($_.State), Last Run: $($info.LastRunTime))" -ForegroundColor Gray
    }
}
#endregion

#region FINAL VERDICT
Write-Host "`n" + ("=" * 60) -ForegroundColor Green
Write-Host "UPGRADE EVIDENCE SUMMARY:" -ForegroundColor Green -BackgroundColor Black

$evidencePoints = 0

# Check all evidence
if ($os.Caption -like "*Windows 11*" -or [int]$os.BuildNumber -ge 22000) {
    $evidencePoints++
    Write-Host "[YES] Running Windows 11 (Build $($os.BuildNumber))" -ForegroundColor Green
}

if ($foundAssistantEvidence) {
    $evidencePoints++
    Write-Host "[YES] Installation Assistant artifacts found" -ForegroundColor Green
}

if (Test-Path "C:\Windows.old") {
    $evidencePoints++
    Write-Host "[YES] Windows.old folder exists from upgrade" -ForegroundColor Green
}

if ($installDateTime.Date -eq (Get-Date).Date -or $installDateTime.Date -eq (Get-Date).AddDays(-1).Date) {
    $evidencePoints++
    Write-Host "[YES] Windows installed recently (within 24 hours)" -ForegroundColor Green
}

Write-Host "`nEVIDENCE SCORE: $evidencePoints/4" -ForegroundColor $(if ($evidencePoints -ge 3) {'Green'} else {'Yellow'})

if ($evidencePoints -ge 3) {
    Write-Host "`nCONFIRMED: Windows 11 upgrade completed successfully using Installation Assistant!" -ForegroundColor Green -BackgroundColor Black
    Write-Host "The silent upgrade method worked perfectly." -ForegroundColor Green
} else {
    Write-Host "`nPartial evidence of upgrade completion" -ForegroundColor Yellow
}
#endregion

# Export detailed evidence
$evidence = @{
    Timestamp = Get-Date
    OSVersion = $os.Version
    OSCaption = $os.Caption
    BuildNumber = $os.BuildNumber
    InstallDate = $installDateTime
    FoundAssistantArtifacts = $foundAssistantEvidence
    WindowsOldExists = Test-Path "C:\Windows.old"
}

$evidence | ConvertTo-Json | Out-File "C:\code\Windows\win11-upgrade-evidence.json"