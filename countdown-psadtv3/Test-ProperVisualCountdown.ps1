#region Initialize
# Set script location and import PSADT
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$psadtPath = Join-Path $scriptPath "PSAppDeployToolkit\Toolkit\AppDeployToolkit"
. "$psadtPath\AppDeployToolkitMain.ps1"
#endregion

#region Custom Visual Countdown Function (PSADT-Style)
function Show-PSADTStyleCountdownTimer {
    param(
        [int]$CountdownSeconds = 60,
        [string]$Message = "This is a visual countdown timer demonstration"
    )
    
    # Load assemblies
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    
    # Create form
    $timerForm = New-Object -TypeName 'System.Windows.Forms.Form'
    $timerForm.Text = $appName
    $timerForm.Size = New-Object -TypeName 'System.Drawing.Size' -ArgumentList (500, 250)
    $timerForm.StartPosition = 'CenterScreen'
    $timerForm.FormBorderStyle = 'FixedDialog'
    $timerForm.MaximizeBox = $false
    $timerForm.MinimizeBox = $false
    $timerForm.TopMost = $true
    
    # Try to set icon
    try {
        $iconPath = "$psadtPath\AppDeployToolkitLogo.ico"
        if (Test-Path $iconPath) {
            $timerForm.Icon = [System.Drawing.Icon]::new($iconPath)
        }
    }
    catch {
        # Continue without icon
    }
    
    # Message label
    $lblMessage = New-Object -TypeName 'System.Windows.Forms.Label'
    $lblMessage.Location = New-Object -TypeName 'System.Drawing.Point' -ArgumentList (20, 20)
    $lblMessage.Size = New-Object -TypeName 'System.Drawing.Size' -ArgumentList (460, 60)
    $lblMessage.Text = $Message
    $lblMessage.TextAlign = 'MiddleCenter'
    $lblMessage.Font = New-Object -TypeName 'System.Drawing.Font' -ArgumentList ('Segoe UI', 11)
    
    # Countdown time label
    $lblCountdownTime = New-Object -TypeName 'System.Windows.Forms.Label'
    $lblCountdownTime.Location = New-Object -TypeName 'System.Drawing.Point' -ArgumentList (20, 90)
    $lblCountdownTime.Size = New-Object -TypeName 'System.Drawing.Size' -ArgumentList (460, 50)
    $lblCountdownTime.Text = "00:00:00"
    $lblCountdownTime.TextAlign = 'MiddleCenter'
    $lblCountdownTime.Font = New-Object -TypeName 'System.Drawing.Font' -ArgumentList ('Segoe UI', 24, [System.Drawing.FontStyle]::Bold)
    $lblCountdownTime.ForeColor = [System.Drawing.Color]::DarkBlue
    
    # Status label
    $lblStatus = New-Object -TypeName 'System.Windows.Forms.Label'
    $lblStatus.Location = New-Object -TypeName 'System.Drawing.Point' -ArgumentList (20, 145)
    $lblStatus.Size = New-Object -TypeName 'System.Drawing.Size' -ArgumentList (460, 20)
    $lblStatus.Text = "Countdown in progress..."
    $lblStatus.TextAlign = 'MiddleCenter'
    $lblStatus.Font = New-Object -TypeName 'System.Drawing.Font' -ArgumentList ('Segoe UI', 9)
    $lblStatus.ForeColor = [System.Drawing.Color]::DarkGray
    
    # OK button
    $btnOK = New-Object -TypeName 'System.Windows.Forms.Button'
    $btnOK.Location = New-Object -TypeName 'System.Drawing.Point' -ArgumentList (200, 175)
    $btnOK.Size = New-Object -TypeName 'System.Drawing.Size' -ArgumentList (100, 30)
    $btnOK.Text = 'OK'
    $btnOK.Font = New-Object -TypeName 'System.Drawing.Font' -ArgumentList ('Segoe UI', 9)
    $btnOK.Enabled = $false  # Disabled during countdown
    
    # Add controls
    $timerForm.Controls.Add($lblMessage)
    $timerForm.Controls.Add($lblCountdownTime)
    $timerForm.Controls.Add($lblStatus)
    $timerForm.Controls.Add($btnOK)
    
    # PSADT-style timer implementation
    $startTime = Get-Date
    $countdownTime = $startTime.AddSeconds($CountdownSeconds)
    
    # Create timer (PSADT uses default 100ms interval)
    $timer = New-Object -TypeName 'System.Windows.Forms.Timer'
    
    # Timer tick event (PSADT-style)
    $timer.Add_Tick({
        $currentTime = Get-Date
        $remainingTime = $countdownTime.Subtract($currentTime)
        
        if ($countdownTime -le $currentTime) {
            # Countdown complete
            $timer.Stop()
            $lblCountdownTime.Text = "00:00:00"
            $lblCountdownTime.ForeColor = [System.Drawing.Color]::Green
            $lblStatus.Text = "Countdown complete! (Did nothing - as designed)"
            $lblStatus.ForeColor = [System.Drawing.Color]::Green
            $btnOK.Enabled = $true
            $btnOK.Select()  # Focus the button
        }
        else {
            # Update countdown display (PSADT format)
            $days = $remainingTime.Days
            $hours = $remainingTime.Hours
            $minutes = $remainingTime.Minutes
            $seconds = $remainingTime.Seconds
            
            # Combine days into hours like PSADT does
            $totalHours = ($days * 24) + $hours
            
            # Format as HH:MM:SS
            $lblCountdownTime.Text = [String]::Format('{0:d2}:{1:d2}:{2:d2}', $totalHours, $minutes, $seconds)
        }
    })
    
    # Button click handler
    $btnOK.Add_Click({
        $timer.Stop()
        $timerForm.DialogResult = [System.Windows.Forms.DialogResult]::OK
        $timerForm.Close()
    })
    
    # Form closing handler
    $timerForm.Add_FormClosing({
        $timer.Stop()
        $timer.Dispose()
    })
    
    # Start the timer
    $timer.Start()
    
    # Show the form
    $result = $timerForm.ShowDialog()
    
    # Cleanup
    $timerForm.Dispose()
    
    return $result
}
#endregion

#region Main Script
try {
    # Initialize the toolkit
    $appName = "PSADT-Style Countdown Demo"
    $appVersion = "1.0"
    $appVendor = "Test"
    
    Write-Log "Starting PSADT-style visual countdown timer test..." -Source "Test-ProperCountdown"
    
    # Show PSADT-style countdown timer - does nothing when it reaches zero!
    $result = Show-PSADTStyleCountdownTimer -CountdownSeconds 30 -Message "This visual countdown timer will count from 30 to 0 without taking any action!"
    
    Write-Log "PSADT-style countdown completed! No apps closed, no restart!" -Source "Test-ProperCountdown"
    
    # Show confirmation
    Show-InstallationPrompt -Message "The countdown successfully reached zero without closing apps or restarting!" -ButtonRightText "Perfect!"
}
catch {
    Write-Log "Error: $($_.Exception.Message)" -Source "Test-ProperCountdown" -Severity 3
    Show-InstallationPrompt -Message "An error occurred: $($_.Exception.Message)" -ButtonRightText "OK"
}
#endregion