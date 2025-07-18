# PSADT v3 Visual Countdown Timer Implementation

## Overview
PSADT v3 implements visual countdown timers in two main functions:
1. `Show-InstallationWelcome` - Countdown before closing applications
2. `Show-InstallationRestartPrompt` - Countdown before system restart

## Key Implementation Details

### 1. Timer Object
- Uses `System.Windows.Forms.Timer` for countdown functionality
- Default interval: 100ms (10 updates per second)
- No explicit interval setting for countdown mode (uses default)

### 2. Time Calculation Pattern
```powershell
# Initialize on form load
[DateTime]$startTime = Get-Date
[DateTime]$countdownTime = $startTime.AddSeconds($CountdownSeconds)

# In timer tick event
[DateTime]$currentTime = Get-Date
[TimeSpan]$remainingTime = $countdownTime.Subtract($currentTime)
```

### 3. Display Format
```powershell
# Format: HH:MM:SS (combines days into hours)
$labelCountdown.Text = [String]::Format('{0}:{1:d2}:{2:d2}', 
    $remainingTime.Days * 24 + $remainingTime.Hours, 
    $remainingTime.Minutes, 
    $remainingTime.Seconds
)
```

### 4. Timer Event Handler Structure
```powershell
[ScriptBlock]$welcomeTimer_Tick = {
    # Calculate remaining time
    [DateTime]$currentTime = Get-Date
    [DateTime]$countdownTime = $startTime.AddSeconds($CloseAppsCountdown)
    [Timespan]$remainingTime = $countdownTime.Subtract($currentTime)
    
    # Check if countdown complete
    If ($countdownTime -le $currentTime) {
        # Perform action (close apps, continue, restart, etc.)
        $buttonAction.PerformClick()
    }
    Else {
        # Update display
        $labelCountdown.Text = [String]::Format('{0}:{1:d2}:{2:d2}', 
            $remainingTime.Days * 24 + $remainingTime.Hours, 
            $remainingTime.Minutes, 
            $remainingTime.Seconds)
    }
}
```

## Implementation Steps

### Step 1: Create Timer Object
```powershell
$script:welcomeTimer = New-Object -TypeName 'System.Windows.Forms.Timer'
```

### Step 2: Define Timer Tick Event
```powershell
[ScriptBlock]$welcomeTimer_Tick = {
    # Countdown logic here
}
$script:welcomeTimer.add_Tick($welcomeTimer_Tick)
```

### Step 3: Initialize in Form Load Event
```powershell
[ScriptBlock]$Form_Load = {
    # Set initial countdown display
    [DateTime]$currentTime = Get-Date
    [DateTime]$countdownTime = $startTime.AddSeconds($CountdownSeconds)
    [Timespan]$remainingTime = $countdownTime.Subtract($currentTime)
    
    $labelCountdown.Text = [String]::Format('{0}:{1:d2}:{2:d2}', 
        $remainingTime.Days * 24 + $remainingTime.Hours, 
        $remainingTime.Minutes, 
        $remainingTime.Seconds)
    
    # Start timer
    $script:welcomeTimer.Start()
}
```

### Step 4: Cleanup on Form Close
```powershell
[ScriptBlock]$Form_Cleanup = {
    $script:welcomeTimer.remove_Tick($welcomeTimer_Tick)
    $script:welcomeTimer.Stop()
    $script:welcomeTimer.Dispose()
}
```

## Key Features

### 1. Smooth Updates
- 100ms interval provides smooth countdown (10 updates/second)
- No visible jumping or stuttering

### 2. Accurate Time Tracking
- Uses DateTime arithmetic for precision
- Not affected by timer drift
- Always calculates from original start time

### 3. Flexible Actions
- Welcome Dialog: Close apps or continue
- Restart Dialog: Force restart
- Customizable through button click events

### 4. UI State Management
- Countdown continues even if form is minimized
- Can force form to foreground near end of countdown
- Disable minimize button when countdown below threshold

## Additional PSADT Features

### Persistence Timer
- Separate timer to keep dialog on top
- Repositions form every few seconds
- Prevents user from ignoring dialog

### Dynamic Process Checking
- Another timer to re-check for running processes
- Updates UI if processes start/stop during countdown

### No-Hide Threshold
- Prevents minimizing when countdown below certain seconds
- Forces user attention for critical final seconds

## Code Locations in AppDeployToolkitMain.ps1

- Timer creation: ~line 10188
- Timer tick handler: ~lines 10192-10220
- Form load init: ~lines 10175-10183
- Timer start: ~line 10179
- Cleanup: ~line 10143

## Example Implementation
See `Test-PSADTStyleCountdown.ps1` for a working demonstration of the PSADT countdown pattern.