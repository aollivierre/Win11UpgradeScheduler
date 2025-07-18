# Minimal PSADT-Style Countdown Implementation
# This shows the core countdown logic without extra features

Add-Type -AssemblyName System.Windows.Forms
[Windows.Forms.Application]::EnableVisualStyles()

# Create form and label
$form = New-Object System.Windows.Forms.Form
$form.Text = "Minimal PSADT Countdown"
$form.Size = '300,150'
$form.StartPosition = "CenterScreen"

$label = New-Object System.Windows.Forms.Label
$label.Size = '250,50'
$label.Location = '25,30'
$label.Font = 'Arial,20,style=Bold'
$label.TextAlign = 'MiddleCenter'
$form.Controls.Add($label)

# PSADT countdown implementation
$countdownSeconds = 30
$startTime = Get-Date
$countdownTime = $startTime.AddSeconds($countdownSeconds)

# Create timer with default 100ms interval (PSADT pattern)
$timer = New-Object System.Windows.Forms.Timer

# Timer tick event (PSADT pattern)
$timer.Add_Tick({
    $currentTime = Get-Date
    $remainingTime = $countdownTime.Subtract($currentTime)
    
    if ($countdownTime -le $currentTime) {
        $timer.Stop()
        $form.Close()
    }
    else {
        # PSADT display format
        $label.Text = [String]::Format('{0}:{1:d2}:{2:d2}', 
            $remainingTime.Days * 24 + $remainingTime.Hours, 
            $remainingTime.Minutes, 
            $remainingTime.Seconds)
    }
})

# Form load - initialize and start
$form.Add_Load({
    $remainingTime = $countdownTime.Subtract((Get-Date))
    $label.Text = [String]::Format('{0}:{1:d2}:{2:d2}', 
        $remainingTime.Days * 24 + $remainingTime.Hours, 
        $remainingTime.Minutes, 
        $remainingTime.Seconds)
    $timer.Start()
})

# Cleanup
$form.Add_FormClosed({
    $timer.Dispose()
})

$form.ShowDialog()