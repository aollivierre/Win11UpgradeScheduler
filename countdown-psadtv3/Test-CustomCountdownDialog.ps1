# Test script for the custom countdown dialog
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition

# Dot-source the custom countdown function
. "$scriptPath\Show-CustomCountdownDialog.ps1"

# Test with 20-second countdown
Write-Host "Starting custom countdown dialog test..."
$result = Show-CustomCountdownDialog -CountdownSeconds 20 -Message "This is a test of the visual countdown timer. It will do nothing when it reaches zero!" -Title "Custom Countdown Test"

Write-Host "Dialog result: $result"
Write-Host "Test completed!"