# Test the schedule time calculation logic
Write-Host "Testing schedule time calculations..." -ForegroundColor Cyan

# Test "Tonight - 10 PM"
$when = 'Tonight'
$time = '10 PM'

Write-Host "`nInput: $when - $time" -ForegroundColor Yellow

# Calculate the actual scheduled time (same logic as in the script)
$scheduledTime = Get-Date
Write-Host "Initial scheduledTime: $scheduledTime" -ForegroundColor Red

Switch ($when) {
    'Tonight' {
        # Same day evening
        Switch ($time) {
            '8 PM' { $scheduledTime = (Get-Date).Date.AddHours(20) }
            '10 PM' { $scheduledTime = (Get-Date).Date.AddHours(22) }
            '11 PM' { $scheduledTime = (Get-Date).Date.AddHours(23) }
        }
    }
    'Tomorrow' {
        # Next day
        $scheduledTime = (Get-Date).AddDays(1).Date
        Switch ($time) {
            'Morning (8 AM)' { $scheduledTime = $scheduledTime.AddHours(8) }
            'Afternoon (2 PM)' { $scheduledTime = $scheduledTime.AddHours(14) }
            'Evening (8 PM)' { $scheduledTime = $scheduledTime.AddHours(20) }
        }
    }
}

Write-Host "Calculated scheduledTime: $scheduledTime" -ForegroundColor Green

# Format the scheduled time nicely
$formattedTime = $scheduledTime.ToString('dddd, MMMM d, yyyy') + ' at ' + $scheduledTime.ToString('h:mm tt')
Write-Host "`nFormatted time: $formattedTime" -ForegroundColor Cyan

# Check if it's in the past
if ($scheduledTime -lt (Get-Date)) {
    Write-Host "`nWARNING: Scheduled time is in the past!" -ForegroundColor Red
}