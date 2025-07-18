# Windows 11 Silent Upgrade - PSADT Integration Plan

## Executive Summary
Based on our successful test, we can achieve completely silent Windows 11 upgrades using the Installation Assistant (no ISO required) when run as SYSTEM with `/QuietInstall /SkipEULA` parameters.

## Storage Requirements (Based on Empirical Data)

### Actual Storage Usage from Test:
- **Windows.old backup**: 25.74 GB
- **Net space consumed**: 36.37 GB  
- **Total space needed**: ~67 GB
- **Downloaded files**: ~4 GB (Installation Assistant downloads Windows 11)

### Recommended Thresholds:
```powershell
$storageRequirements = @{
    FailThreshold = 25      # FAIL if less than 25 GB (absolutely minimum)
    WarnThreshold = 50      # WARN if less than 50 GB (below safe minimum)
    OfficialRequirement = 64 # Microsoft's official requirement
}
```

## Architecture Overview

### 1. PSADT Components

```
Deploy-Application.ps1 (Main orchestrator)
    |
    +-- Pre-Installation Phase
    |     +-- Hardware checks (RAM, CPU, Storage)
    |     +-- Set registry bypass keys
    |     +-- Download Installation Assistant
    |
    +-- Installation Phase  
    |     +-- Attended Mode
    |     |     +-- Show "Upgrade Now" or "Schedule" dialog
    |     |     +-- If scheduled: Create scheduled task
    |     |     +-- If now: Show background notification
    |     |
    |     +-- Unattended Mode
    |           +-- Create and run scheduled task immediately
    |
    +-- Post-Installation Phase
            +-- Cleanup temporary files
            +-- Log results
```

### 2. Key Functions to Implement

#### A. Storage Check Function
```powershell
Function Test-Win11StorageRequirements {
    param(
        [int]$FailThresholdGB = 25,
        [int]$WarnThresholdGB = 50
    )
    
    $disk = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='C:'"
    $freeGB = [math]::Round($disk.FreeSpace / 1GB, 2)
    
    if ($freeGB -lt $FailThresholdGB) {
        Write-Log -Message "FAIL: Only $freeGB GB free. Minimum $FailThresholdGB GB required." -Severity 3
        Return $false
    }
    elseif ($freeGB -lt $WarnThresholdGB) {
        Write-Log -Message "WARNING: Only $freeGB GB free. Recommended $WarnThresholdGB GB." -Severity 2
        # Continue but warn user
    }
    
    Return $true
}
```

#### B. Registry Bypass Setup
```powershell
Function Set-Win11BypassKeys {
    $labConfigPath = "HKLM:\SYSTEM\Setup\LabConfig"
    
    if (!(Test-Path $labConfigPath)) {
        New-Item -Path "HKLM:\SYSTEM\Setup" -Name "LabConfig" -Force | Out-Null
    }
    
    $bypassKeys = @{
        "BypassTPMCheck" = 1
        "BypassCPUCheck" = 1
        "BypassRAMCheck" = 1
        "BypassSecureBootCheck" = 1
        "BypassStorageCheck" = 1
    }
    
    foreach ($key in $bypassKeys.Keys) {
        Set-ItemProperty -Path $labConfigPath -Name $key -Value $bypassKeys[$key] -Type DWord -Force
    }
}
```

#### C. Installation Assistant Download
```powershell
Function Get-Win11InstallationAssistant {
    param(
        [string]$DestinationPath = "$envTemp\Windows11InstallationAssistant.exe"
    )
    
    if (!(Test-Path $DestinationPath)) {
        Write-Log -Message "Downloading Windows 11 Installation Assistant..."
        $url = "https://go.microsoft.com/fwlink/?linkid=2171764"
        Invoke-WebRequest -Uri $url -OutFile $DestinationPath -UseBasicParsing
    }
    
    Return $DestinationPath
}
```

#### D. Scheduled Task Creation
```powershell
Function New-Win11UpgradeTask {
    param(
        [string]$TaskName = "Win11SilentUpgrade_$(Get-Date -Format 'yyyyMMddHHmmss')",
        [string]$ExecutablePath,
        [DateTime]$StartTime = (Get-Date).AddMinutes(30),
        [switch]$RunImmediately
    )
    
    $action = New-ScheduledTaskAction -Execute $ExecutablePath -Argument "/QuietInstall /SkipEULA"
    $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
    
    if ($RunImmediately) {
        $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddSeconds(5)
    } else {
        $trigger = New-ScheduledTaskTrigger -Once -At $StartTime
    }
    
    Register-ScheduledTask -TaskName $TaskName -Action $action -Principal $principal -Settings $settings -Trigger $trigger -Force
    
    if ($RunImmediately) {
        Start-ScheduledTask -TaskName $TaskName
    }
    
    Return $TaskName
}
```

#### E. Countdown Timer (for scheduled upgrades)
```powershell
Function Show-Win11UpgradeCountdown {
    param(
        [int]$Minutes = 30
    )
    
    # This will be called by the scheduled task
    $endTime = (Get-Date).AddMinutes($Minutes)
    
    # Use PSADT's Show-InstallationProgress or custom balloon
    while ((Get-Date) -lt $endTime) {
        $remaining = $endTime - (Get-Date)
        $message = "Windows 11 upgrade will start in: $($remaining.Minutes) minutes"
        
        # Update balloon notification or progress window
        Show-BalloonTip -BalloonTipText $message -BalloonTipTitle "Windows 11 Upgrade Scheduled"
        
        Start-Sleep -Seconds 60
    }
    
    # Time's up - start the upgrade
    Start-Win11SilentUpgrade
}
```

### 3. Implementation in Deploy-Application.ps1

#### Pre-Installation Section:
```powershell
## Perform Pre-Installation tasks here
Show-InstallationWelcome -CloseApps 'excel,winword,outlook' -CheckDiskSpace -PersistPrompt

# Check storage with flexible thresholds
if (!(Test-Win11StorageRequirements -FailThresholdGB 25 -WarnThresholdGB 50)) {
    Show-InstallationPrompt -Message "Insufficient disk space for Windows 11 upgrade. Please free up space and try again." -ButtonRightText 'OK' -Icon Error
    Exit-Script -ExitCode 1618
}

# Set bypass registry keys
Set-Win11BypassKeys

# Download Installation Assistant
$installerPath = Get-Win11InstallationAssistant
```

#### Installation Section:
```powershell
## Handle Zero-Config
if ($useDefaultMsi) {
    # Unattended mode - upgrade immediately
    Write-Log -Message "Unattended mode detected. Starting silent upgrade..."
    $taskName = New-Win11UpgradeTask -ExecutablePath $installerPath -RunImmediately
    Show-BalloonTip -BalloonTipText "Windows 11 upgrade is running in the background. Your computer will restart automatically." -BalloonTipTitle "Upgrade in Progress"
}
else {
    # Attended mode - show options
    $userChoice = Show-InstallationPrompt -Message "Windows 11 upgrade is ready. Choose when to upgrade:" `
        -ButtonLeftText 'Upgrade Now' -ButtonRightText 'Schedule for Tonight' -Icon Information
    
    if ($userChoice -eq 'Upgrade Now') {
        $taskName = New-Win11UpgradeTask -ExecutablePath $installerPath -RunImmediately
        Show-InstallationProgress -StatusMessage "Windows 11 upgrade is running in the background. Please keep your computer plugged in and connected to the internet."
    }
    else {
        # Schedule for tonight (e.g., 2 AM)
        $tonight = (Get-Date).Date.AddDays(1).AddHours(2)
        $taskName = New-Win11UpgradeTask -ExecutablePath $installerPath -StartTime $tonight
        
        # Create a separate task for the countdown timer
        $countdownScript = @"
& '$scriptDirectory\Deploy-Application.exe' -DeploymentType 'Install' -DeployMode 'Interactive' -ShowCountdown
"@
        # Schedule countdown 30 minutes before upgrade
        $countdownTime = $tonight.AddMinutes(-30)
        # Create countdown task...
    }
}
```

### 4. Special Countdown Mode

Add a parameter to Deploy-Application.ps1:
```powershell
Param (
    [switch]$ShowCountdown
)

if ($ShowCountdown) {
    # This is being called by scheduled task to show countdown
    Show-Win11UpgradeCountdown -Minutes 30
    Exit-Script -ExitCode 0
}
```

### 5. Testing Strategy

Since the machine is already Windows 11:
1. Test all pre-flight checks
2. Test scheduled task creation
3. Test countdown timer display
4. Verify Installation Assistant starts correctly
5. Test both attended and unattended flows

### 6. Key Benefits of This Approach

1. **No ISO Required**: 4MB download vs 3GB+
2. **Truly Silent**: No EULA prompts when run as SYSTEM
3. **User-Friendly**: Options for immediate or scheduled upgrade
4. **Safe**: Pre-flight checks with flexible storage thresholds
5. **PSADT Integration**: Leverages existing logging, UI, and error handling

## Next Steps

1. Implement the core functions
2. Integrate into existing Deploy-Application.ps1
3. Test scheduled task creation and execution
4. Test countdown timer functionality
5. Validate on a Windows 10 machine

This approach gives you the best of both worlds: the simplicity of the Installation Assistant with the power and flexibility of PSADT!