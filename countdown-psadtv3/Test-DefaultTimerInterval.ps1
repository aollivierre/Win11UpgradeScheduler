# Test to check the default interval of a Windows Forms Timer
Add-Type -AssemblyName System.Windows.Forms

$timer = New-Object System.Windows.Forms.Timer
Write-Host "Default Timer Interval: $($timer.Interval) ms"

# The default interval for Windows Forms Timer is 100ms
# However, PSADT might be relying on this being set elsewhere or using a different approach