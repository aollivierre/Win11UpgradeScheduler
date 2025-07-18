#region Windows 11 Upgrade Functions
# Add these functions to your existing Deploy-Application.ps1

Function Test-Win11UpgradeRequirements {
    Write-Log -Message "Checking Windows 11 upgrade requirements..." -Source $appDeployToolkitName
    
    # Storage check with flexible thresholds
    $disk = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='C:'"
    $freeGB = [math]::Round($disk.FreeSpace / 1GB, 2)
    
    if ($freeGB -lt 25) {
        Write-Log -Message "FAIL: Only $freeGB GB free. Minimum 25 GB required for upgrade." -Severity 3 -Source $appDeployToolkitName
        Return @{
            Success = $false
            Message = "Insufficient disk space. You have $freeGB GB free, but need at least 25 GB."
            FreeSpaceGB = $freeGB
        }
    }
    elseif ($freeGB -lt 50) {
        Write-Log -Message "WARNING: Only $freeGB GB free. Recommended 50 GB for safe upgrade." -Severity 2 -Source $appDeployToolkitName
        # Continue but warn
    }
    
    # RAM check
    $ram = Get-WmiObject Win32_ComputerSystem
    $ramGB = [math]::Round($ram.TotalPhysicalMemory / 1GB, 2)
    
    if ($ramGB -lt 4) {
        Write-Log -Message "FAIL: Only $ramGB GB RAM. Minimum 4 GB required." -Severity 3 -Source $appDeployToolkitName
        Return @{
            Success = $false
            Message = "Insufficient RAM. You have $ramGB GB, but need at least 4 GB."
            RAMGB = $ramGB
        }
    }
    
    Return @{
        Success = $true
        FreeSpaceGB = $freeGB
        RAMGB = $ramGB
    }
}

Function Set-Win11RegistryBypasses {
    Write-Log -Message "Setting Windows 11 compatibility bypass registry keys..." -Source $appDeployToolkitName
    
    $labConfigPath = "HKLM:\SYSTEM\Setup\LabConfig"
    if (!(Test-Path $labConfigPath)) {
        New-Item -Path "HKLM:\SYSTEM\Setup" -Name "LabConfig" -Force | Out-Null
    }
    
    @{
        "BypassTPMCheck" = 1
        "BypassCPUCheck" = 1
        "BypassRAMCheck" = 1
        "BypassSecureBootCheck" = 1
        "BypassStorageCheck" = 1
    }.GetEnumerator() | ForEach-Object {
        Set-RegistryKey -Key $labConfigPath -Name $_.Key -Value $_.Value -Type DWord
    }
    
    Write-Log -Message "Registry bypass keys configured successfully" -Source $appDeployToolkitName
}

Function Start-Win11SilentUpgrade {
    param(
        [string]$InstallAssistantPath,
        [DateTime]$ScheduledTime,
        [switch]$ShowCountdown
    )
    
    $taskName = "Win11Upgrade_$installName`_$(Get-Date -Format 'yyyyMMddHHmmss')"
    
    # Create the main upgrade task
    $upgradeAction = New-ScheduledTaskAction -Execute $InstallAssistantPath -Argument "/QuietInstall /SkipEULA"
    $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit (New-TimeSpan -Hours 4)
    
    if ($ScheduledTime) {
        Write-Log -Message "Scheduling Windows 11 upgrade for: $ScheduledTime" -Source $appDeployToolkitName
        $trigger = New-ScheduledTaskTrigger -Once -At $ScheduledTime
        
        if ($ShowCountdown) {
            # Create countdown task to run 30 minutes before
            $countdownTime = $ScheduledTime.AddMinutes(-30)
            $countdownTaskName = "$taskName`_Countdown"
            
            # Create a script block that will show countdown
            $countdownScript = @"
& '$scriptDirectory\$appDeployToolkitName' -DeploymentType 'Install' -DeployMode 'Interactive' -CountdownMinutes 30 -UpgradeTaskName '$taskName'
"@
            $countdownScriptPath = "$envTemp\Win11Countdown_$taskName.ps1"
            $countdownScript | Out-File -FilePath $countdownScriptPath -Force
            
            $countdownAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$countdownScriptPath`""
            $countdownTrigger = New-ScheduledTaskTrigger -Once -At $countdownTime
            
            Register-ScheduledTask -TaskName $countdownTaskName -Action $countdownAction -Principal $principal `
                                  -Settings $settings -Trigger $countdownTrigger -Force | Out-Null
        }
    }
    else {
        Write-Log -Message "Starting Windows 11 upgrade immediately" -Source $appDeployToolkitName
        $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddSeconds(10)
    }
    
    # Register the main upgrade task
    Register-ScheduledTask -TaskName $taskName -Action $upgradeAction -Principal $principal `
                          -Settings $settings -Trigger $trigger -Force | Out-Null
    
    if (!$ScheduledTime) {
        # Start immediately if not scheduled
        Start-ScheduledTask -TaskName $taskName
    }
    
    Return $taskName
}

#endregion

#region Main Deployment Logic
# Add this to your Pre-Installation section:

## Check if running in countdown mode
if ($CountdownMinutes -and $UpgradeTaskName) {
    # This is the countdown execution
    Write-Log -Message "Running in countdown mode for task: $UpgradeTaskName" -Source $appDeployToolkitName
    
    $endTime = (Get-Date).AddMinutes($CountdownMinutes)
    
    # Show initial notification
    Show-BalloonTip -BalloonTipText "Windows 11 upgrade will begin in $CountdownMinutes minutes. Please save your work." `
                    -BalloonTipTitle "Windows 11 Upgrade Scheduled" -BalloonTipIcon Info
    
    # Countdown loop
    while ((Get-Date) -lt $endTime) {
        $remaining = [math]::Round(($endTime - (Get-Date)).TotalMinutes, 0)
        
        if ($remaining -in @(20, 10, 5, 1)) {
            Show-BalloonTip -BalloonTipText "Windows 11 upgrade starts in $remaining minutes" `
                            -BalloonTipTitle "Upgrade Reminder" -BalloonTipIcon Warning
        }
        
        Start-Sleep -Seconds 60
    }
    
    # Final notification
    Show-BalloonTip -BalloonTipText "Windows 11 upgrade is starting now. Your computer will restart automatically." `
                    -BalloonTipTitle "Upgrade Starting" -BalloonTipIcon Info
    
    Exit-Script -ExitCode 0
}

## Normal deployment flow
Show-InstallationWelcome -CloseApps 'excel,winword,outlook' -CheckDiskSpace -PersistPrompt

# Check upgrade requirements
$requirements = Test-Win11UpgradeRequirements
if (!$requirements.Success) {
    Show-InstallationPrompt -Message $requirements.Message -ButtonRightText 'OK' -Icon Error
    Exit-Script -ExitCode 1618
}

# Set bypass keys
Set-Win11RegistryBypasses

# Download Installation Assistant
Write-Log -Message "Downloading Windows 11 Installation Assistant..." -Source $appDeployToolkitName
$assistantPath = "$dirFiles\Windows11InstallationAssistant.exe"

if (!(Test-Path $assistantPath)) {
    try {
        $null = New-Item -Path $dirFiles -ItemType Directory -Force -ErrorAction SilentlyContinue
        Invoke-WebRequest -Uri "https://go.microsoft.com/fwlink/?linkid=2171764" -OutFile $assistantPath -UseBasicParsing
        Write-Log -Message "Installation Assistant downloaded successfully" -Source $appDeployToolkitName
    }
    catch {
        Write-Log -Message "Failed to download Installation Assistant: $_" -Severity 3 -Source $appDeployToolkitName
        Show-InstallationPrompt -Message "Failed to download Windows 11 installer. Please check your internet connection." -ButtonRightText 'OK' -Icon Error
        Exit-Script -ExitCode 1603
    }
}

#endregion

#region Installation Phase
# Add this to your Installation section:

if ($deployMode -eq 'Silent') {
    # Unattended mode - upgrade immediately
    Write-Log -Message "Silent mode detected. Starting Windows 11 upgrade immediately..." -Source $appDeployToolkitName
    
    $taskName = Start-Win11SilentUpgrade -InstallAssistantPath $assistantPath
    
    # Show balloon notification
    Show-BalloonTip -BalloonTipText "Windows 11 upgrade is running in the background. Your computer will restart automatically when complete." `
                    -BalloonTipTitle "Windows 11 Upgrade in Progress" -BalloonTipIcon Info
}
else {
    # Interactive mode - show options
    $promptMessage = @"
Windows 11 upgrade is ready to install.

Current Status:
- Free Space: $($requirements.FreeSpaceGB) GB
- RAM: $($requirements.RAMGB) GB
- All requirements met

Choose when to upgrade:
"@
    
    $userChoice = Show-InstallationPrompt -Message $promptMessage `
        -ButtonLeftText 'Upgrade Now' -ButtonMiddleText 'Tonight at 2 AM' -ButtonRightText 'Cancel' `
        -Icon Information -Timeout 300 -ExitOnTimeout $false
    
    Switch ($userChoice) {
        'Upgrade Now' {
            Write-Log -Message "User selected: Upgrade Now" -Source $appDeployToolkitName
            
            $taskName = Start-Win11SilentUpgrade -InstallAssistantPath $assistantPath
            
            # Show progress window
            Show-InstallationProgress -StatusMessage @"
Windows 11 upgrade is now running in the background.

Important:
- Keep your computer plugged in
- Stay connected to the internet
- Your computer will restart automatically
- This process takes 30-90 minutes

You can continue using your computer normally.
"@
            
            # Keep progress window open for a bit
            Start-Sleep -Seconds 30
        }
        
        'Tonight at 2 AM' {
            Write-Log -Message "User selected: Schedule for tonight" -Source $appDeployToolkitName
            
            $tonight = (Get-Date).Date.AddDays(1).AddHours(2)
            $taskName = Start-Win11SilentUpgrade -InstallAssistantPath $assistantPath -ScheduledTime $tonight -ShowCountdown
            
            Show-InstallationPrompt -Message @"
Windows 11 upgrade scheduled for tonight at 2:00 AM.

You will receive a 30-minute warning before the upgrade begins.

Please ensure:
- Computer is plugged in
- Connected to internet
- All work is saved
"@ -ButtonRightText 'OK' -Icon Information
        }
        
        'Cancel' {
            Write-Log -Message "User cancelled Windows 11 upgrade" -Source $appDeployToolkitName
            Exit-Script -ExitCode 1602
        }
    }
}

#endregion