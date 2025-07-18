# Quick 10-second PSADT-style countdown for testing
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

[Windows.Forms.Application]::EnableVisualStyles()

$form = New-Object System.Windows.Forms.Form
$form.Text = "Quick Countdown Test"
$form.Size = New-Object System.Drawing.Size(350, 150)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false

$labelCountdown = New-Object System.Windows.Forms.Label
$labelCountdown.Location = New-Object System.Drawing.Point(25, 20)
$labelCountdown.Size = New-Object System.Drawing.Size(300, 50)
$labelCountdown.Font = New-Object System.Drawing.Font("Arial", 28, [System.Drawing.FontStyle]::Bold)
$labelCountdown.TextAlign = "MiddleCenter"
$labelCountdown.Text = "00:00:00"
$labelCountdown.ForeColor = [System.Drawing.Color]::Blue

$labelMessage = New-Object System.Windows.Forms.Label
$labelMessage.Location = New-Object System.Drawing.Point(25, 75)
$labelMessage.Size = New-Object System.Drawing.Size(300, 20)
$labelMessage.TextAlign = "MiddleCenter"
$labelMessage.Text = "Visual countdown - does nothing when complete!"

$timer = New-Object System.Windows.Forms.Timer
# Using default 100ms interval like PSADT

$countdownSeconds = 10  # Quick 10-second test
$startTime = Get-Date
$countdownTime = $startTime.AddSeconds($countdownSeconds)

$timer.Add_Tick({
    $currentTime = Get-Date
    $remainingTime = $countdownTime.Subtract($currentTime)
    
    if ($countdownTime -le $currentTime) {
        $timer.Stop()
        $labelCountdown.Text = "00:00:00"
        $labelCountdown.ForeColor = [System.Drawing.Color]::Green
        $labelMessage.Text = "Complete! (Did nothing - as requested)"
        # Don't auto-close so user can see result
    }
    else {
        # Format as HH:MM:SS
        $totalHours = $remainingTime.Days * 24 + $remainingTime.Hours
        $labelCountdown.Text = "{0:d2}:{1:d2}:{2:d2}" -f $totalHours, $remainingTime.Minutes, $remainingTime.Seconds
        
        # Color changes
        if ($remainingTime.TotalSeconds -le 3) {
            $labelCountdown.ForeColor = [System.Drawing.Color]::Red
        }
        elseif ($remainingTime.TotalSeconds -le 5) {
            $labelCountdown.ForeColor = [System.Drawing.Color]::Orange
        }
    }
})

$form.Add_Load({
    $timer.Start()
})

$form.Add_FormClosed({
    $timer.Stop()
    $timer.Dispose()
})

$form.Controls.Add($labelCountdown)
$form.Controls.Add($labelMessage)

Write-Host "Starting 10-second visual countdown..."
$form.ShowDialog() | Out-Null
Write-Host "Countdown complete!"