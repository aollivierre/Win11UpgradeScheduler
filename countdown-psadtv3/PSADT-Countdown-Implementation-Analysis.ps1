# PSADT v3 Countdown Timer Implementation Analysis
# Based on analysis of AppDeployToolkitMain.ps1

<#
KEY FINDINGS:

1. PSADT uses System.Windows.Forms.Timer for countdown functionality
2. When showCountdown is true, the timer uses default 100ms interval (10 updates/second)
3. The countdown logic is in the welcomeTimer_Tick scriptblock

IMPLEMENTATION PATTERN:
#>

# 1. Timer Creation (line ~10187-10189)
$script:welcomeTimer = New-Object -TypeName 'System.Windows.Forms.Timer'

# 2. Timer Tick Event Handler (line ~10192-10220)
[ScriptBlock]$welcomeTimer_Tick = {
    ## Get the time information
    [DateTime]$currentTime = Get-Date
    [DateTime]$countdownTime = $startTime.AddSeconds($CloseAppsCountdown)
    [Timespan]$remainingTime = $countdownTime.Subtract($currentTime)
    
    ## If the countdown is complete, close the application(s) or continue
    If ($countdownTime -le $currentTime) {
        # Perform action when countdown reaches zero
        If ($forceCountdown -eq $true) {
            Write-Log -Message 'Countdown timer has elapsed. Force continue.'
            $buttonContinue.PerformClick()
        }
        Else {
            Write-Log -Message 'Close application(s) countdown timer has elapsed.'
            If ($buttonCloseApps.CanFocus) {
                $buttonCloseApps.PerformClick()
            }
            Else {
                $buttonContinue.PerformClick()
            }
        }
    }
    Else {
        # Update the countdown display
        $labelCountdown.Text = [String]::Format('{0}:{1:d2}:{2:d2}', 
            $remainingTime.Days * 24 + $remainingTime.Hours, 
            $remainingTime.Minutes, 
            $remainingTime.Seconds)
    }
}

# 3. Timer Registration and Start (line ~10226 & 10179)
$script:welcomeTimer.add_Tick($welcomeTimer_Tick)
$script:welcomeTimer.Start()

# 4. Form Load Initialization (line ~10175-10183)
[ScriptBlock]$Welcome_Form_StateCorrection_Load = {
    ## Initialize the countdown timer
    [DateTime]$currentTime = Get-Date
    [DateTime]$countdownTime = $startTime.AddSeconds($CloseAppsCountdown)
    $script:welcomeTimer.Start()
    
    ## Set up the form with initial countdown value
    [Timespan]$remainingTime = $countdownTime.Subtract($currentTime)
    $labelCountdown.Text = [String]::Format('{0}:{1:d2}:{2:d2}', 
        $remainingTime.Days * 24 + $remainingTime.Hours, 
        $remainingTime.Minutes, 
        $remainingTime.Seconds)
}

<#
RESTART PROMPT COUNTDOWN IMPLEMENTATION:
The Show-InstallationRestartPrompt uses a similar pattern with timerCountdown
#>

# 1. Timer Creation (line ~11190)
$timerCountdown = New-Object -TypeName 'System.Windows.Forms.Timer'

# 2. Timer Tick Handler (line ~11256-11278)
[ScriptBlock]$timerCountdown_Tick = {
    ## Get the time information
    [DateTime]$currentTime = Get-Date
    [DateTime]$countdownTime = $startTime.AddSeconds($countdownSeconds)
    [Timespan]$remainingTime = $countdownTime.Subtract($currentTime)
    
    ## If the countdown is complete, restart the machine
    If ($countdownTime -le $currentTime) {
        $buttonRestartNow.PerformClick()
    }
    Else {
        ## Update the form
        $labelCountdown.Text = [String]::Format('{0}:{1:d2}:{2:d2}', 
            $remainingTime.Days * 24 + $remainingTime.Hours, 
            $remainingTime.Minutes, 
            $remainingTime.Seconds)
        If ($remainingTime.TotalSeconds -le $countdownNoHideSeconds) {
            $buttonRestartLater.Enabled = $false
            #  If the form is hidden when we hit the "No Hide", bring it back up
            If ($formRestart.WindowState -eq 'Minimized') {
                $formRestart.WindowState = 'Normal'
                $formRestart.TopMost = $TopMost
                $formRestart.BringToFront()
                $formRestart.Location = "$($formInstallationRestartPromptStartPosition.X),$($formInstallationRestartPromptStartPosition.Y)"
            }
        }
    }
}

# 3. Timer Start (in form load event)
$timerCountdown.Start()

<#
KEY IMPLEMENTATION DETAILS:

1. **Timer Interval**: PSADT relies on the default Windows Forms Timer interval of 100ms
   This means the countdown updates 10 times per second

2. **Time Calculation**: Uses DateTime arithmetic to calculate remaining time
   - $startTime = Get-Date (when form is created)
   - $countdownTime = $startTime.AddSeconds($CountdownSeconds)
   - $remainingTime = $countdownTime.Subtract($currentTime)

3. **Display Format**: Uses String.Format with pattern '{0}:{1:d2}:{2:d2}'
   - Combines days into hours: $remainingTime.Days * 24 + $remainingTime.Hours
   - Minutes and seconds use d2 format (2 digits with leading zeros)

4. **Countdown Actions**: 
   - Welcome dialog: Close apps or continue when countdown reaches zero
   - Restart prompt: Force restart when countdown reaches zero

5. **Form Management**: 
   - Countdown label is updated in the timer tick event
   - Form can be minimized/restored based on countdown state
   - NoHide threshold prevents minimizing near end of countdown

This implementation is efficient because:
- Uses built-in Windows Forms Timer
- Simple time arithmetic with DateTime/TimeSpan
- Updates display frequently (10x/second) for smooth countdown
- Minimal overhead in tick event handler
#>