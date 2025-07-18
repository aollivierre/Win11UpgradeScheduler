#region Initialize
# Set script location and import PSADT
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$psadtPath = Join-Path $scriptPath "PSAppDeployToolkit\Toolkit\AppDeployToolkit"
. "$psadtPath\AppDeployToolkitMain.ps1"
#endregion

#region Custom Countdown Function
function Show-CustomCountdownTimer {
    param(
        [int]$Seconds = 60,
        [string]$Message = "Custom countdown timer demonstration"
    )
    
    # Create a custom form using PSADT's built-in form creation
    $timerForm = New-Object -TypeName 'System.Windows.Forms.Form'
    $timerForm.Text = $appName
    $timerForm.Size = New-Object -TypeName 'System.Drawing.Size' -ArgumentList (450, 200)
    $timerForm.StartPosition = 'CenterScreen'
    $timerForm.FormBorderStyle = 'FixedDialog'
    $timerForm.MaximizeBox = $false
    $timerForm.MinimizeBox = $false
    $timerForm.TopMost = $true
    $timerForm.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($psadtPath + '\AppDeployToolkitLogo.ico')
    
    # Message label
    $lblMessage = New-Object -TypeName 'System.Windows.Forms.Label'
    $lblMessage.Location = New-Object -TypeName 'System.Drawing.Point' -ArgumentList (20, 20)
    $lblMessage.Size = New-Object -TypeName 'System.Drawing.Size' -ArgumentList (410, 40)
    $lblMessage.Text = $Message
    $lblMessage.TextAlign = 'MiddleCenter'
    $lblMessage.Font = New-Object -TypeName 'System.Drawing.Font' -ArgumentList ('Microsoft Sans Serif', 10)
    
    # Countdown label
    $lblCountdown = New-Object -TypeName 'System.Windows.Forms.Label'
    $lblCountdown.Location = New-Object -TypeName 'System.Drawing.Point' -ArgumentList (20, 70)
    $lblCountdown.Size = New-Object -TypeName 'System.Drawing.Size' -ArgumentList (410, 40)
    $lblCountdown.Text = "Time remaining: $Seconds seconds"
    $lblCountdown.TextAlign = 'MiddleCenter'
    $lblCountdown.Font = New-Object -TypeName 'System.Drawing.Font' -ArgumentList ('Microsoft Sans Serif', 12, [System.Drawing.FontStyle]::Bold)
    $lblCountdown.ForeColor = [System.Drawing.Color]::Blue
    
    # OK button
    $btnOK = New-Object -TypeName 'System.Windows.Forms.Button'
    $btnOK.Location = New-Object -TypeName 'System.Drawing.Point' -ArgumentList (175, 120)
    $btnOK.Size = New-Object -TypeName 'System.Drawing.Size' -ArgumentList (100, 30)
    $btnOK.Text = 'OK'
    $btnOK.DialogResult = [System.Windows.Forms.DialogResult]::OK
    
    # Add controls
    $timerForm.Controls.Add($lblMessage)
    $timerForm.Controls.Add($lblCountdown)
    $timerForm.Controls.Add($btnOK)
    
    # Create timer
    $timer = New-Object -TypeName 'System.Windows.Forms.Timer'
    $timer.Interval = 1000  # 1 second
    $remainingSeconds = $Seconds
    
    $timer.Add_Tick({
        $remainingSeconds--
        if ($remainingSeconds -ge 0) {
            $lblCountdown.Text = "Time remaining: $remainingSeconds seconds"
            if ($remainingSeconds -eq 0) {
                $lblCountdown.Text = "Countdown complete!"
                $lblCountdown.ForeColor = [System.Drawing.Color]::Green
            }
        }
        else {
            $timer.Stop()
            $timerForm.Close()
        }
    })
    
    # Start timer
    $timer.Start()
    
    # Show form
    $result = $timerForm.ShowDialog()
    
    # Cleanup
    $timer.Dispose()
    $timerForm.Dispose()
    
    return $result
}
#endregion

#region Main Script
try {
    # Initialize the toolkit
    $appName = "Custom Countdown Demo"
    $appVersion = "1.0"
    $appVendor = "Test"
    
    Write-Log "Starting custom countdown timer test..." -Source "Test-CustomCountdown"
    
    # Show custom countdown timer - does nothing when it reaches zero!
    $result = Show-CustomCountdownTimer -Seconds 30 -Message "This is a visual countdown that does nothing when it reaches zero!"
    
    Write-Log "Custom countdown completed! No apps closed, no restart!" -Source "Test-CustomCountdown"
    
    # Show confirmation
    Show-InstallationPrompt -Message "The countdown reached zero and nothing happened! Just as designed." -ButtonRightText "Great!"
}
catch {
    Write-Log "Error: $($_.Exception.Message)" -Source "Test-CustomCountdown" -Severity 3
}
#endregion