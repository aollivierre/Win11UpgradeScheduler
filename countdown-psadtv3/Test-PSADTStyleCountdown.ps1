# PSADT-Style Visual Countdown Timer Implementation
# This demonstrates how PSADT v3 implements its countdown timers

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Enable Visual Styles for modern look
[Windows.Forms.Application]::EnableVisualStyles()

# Create the form
$form = New-Object System.Windows.Forms.Form
$form.Text = "PSADT-Style Countdown Timer"
$form.Size = New-Object System.Drawing.Size(400, 200)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
$form.MaximizeBox = $false
$form.MinimizeBox = $true

# Create countdown label
$labelCountdown = New-Object System.Windows.Forms.Label
$labelCountdown.Location = New-Object System.Drawing.Point(50, 30)
$labelCountdown.Size = New-Object System.Drawing.Size(300, 50)
$labelCountdown.Font = New-Object System.Drawing.Font("Arial", 24, [System.Drawing.FontStyle]::Bold)
$labelCountdown.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$labelCountdown.Text = "00:00:00"

# Create message label
$labelMessage = New-Object System.Windows.Forms.Label
$labelMessage.Location = New-Object System.Drawing.Point(50, 90)
$labelMessage.Size = New-Object System.Drawing.Size(300, 30)
$labelMessage.Font = New-Object System.Drawing.Font("Arial", 10)
$labelMessage.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$labelMessage.Text = "This window will close when countdown reaches zero"

# Create the timer (PSADT uses default 100ms interval)
$timer = New-Object System.Windows.Forms.Timer
# Note: PSADT doesn't set interval for countdown, using default 100ms
# $timer.Interval = 100  # This is the default

# Set countdown duration (60 seconds for demo)
$countdownSeconds = 60
[DateTime]$startTime = Get-Date
[DateTime]$countdownTime = $startTime.AddSeconds($countdownSeconds)

# Define the timer tick event (PSADT pattern)
$timer.Add_Tick({
    # Get current time
    [DateTime]$currentTime = Get-Date
    [TimeSpan]$remainingTime = $countdownTime.Subtract($currentTime)
    
    # Check if countdown is complete
    if ($countdownTime -le $currentTime) {
        # Stop the timer
        $timer.Stop()
        
        # Perform action (PSADT would click a button or close apps)
        [System.Windows.Forms.MessageBox]::Show(
            "Countdown completed! In PSADT, this would trigger the configured action.",
            "Countdown Complete",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
        
        # Close the form
        $form.Close()
    }
    else {
        # Update the countdown display (PSADT format)
        $labelCountdown.Text = [String]::Format('{0}:{1:d2}:{2:d2}', 
            $remainingTime.Days * 24 + $remainingTime.Hours, 
            $remainingTime.Minutes, 
            $remainingTime.Seconds
        )
        
        # Optional: Change color when less than 10 seconds remain
        if ($remainingTime.TotalSeconds -le 10) {
            $labelCountdown.ForeColor = [System.Drawing.Color]::Red
        }
        elseif ($remainingTime.TotalSeconds -le 30) {
            $labelCountdown.ForeColor = [System.Drawing.Color]::Orange
        }
    }
})

# Form load event (initialize countdown display)
$form.Add_Load({
    # Initialize the countdown display
    [DateTime]$currentTime = Get-Date
    [TimeSpan]$remainingTime = $countdownTime.Subtract($currentTime)
    $labelCountdown.Text = [String]::Format('{0}:{1:d2}:{2:d2}', 
        $remainingTime.Days * 24 + $remainingTime.Hours, 
        $remainingTime.Minutes, 
        $remainingTime.Seconds
    )
    
    # Start the timer
    $timer.Start()
    
    Write-Host "Timer started with interval: $($timer.Interval)ms (default is 100ms)"
    Write-Host "Countdown duration: $countdownSeconds seconds"
})

# Form closing event (cleanup)
$form.Add_FormClosed({
    # Stop and dispose timer
    $timer.Stop()
    $timer.Dispose()
    Write-Host "Timer stopped and disposed"
})

# Add controls to form
$form.Controls.Add($labelCountdown)
$form.Controls.Add($labelMessage)

# Show the form
Write-Host "Launching PSADT-style countdown timer..."
Write-Host "The timer uses the same implementation pattern as PSADT v3"
$form.ShowDialog()

Write-Host "Countdown demo completed"