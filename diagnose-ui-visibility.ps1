# Diagnose UI visibility issues
Write-Host "=== UI VISIBILITY DIAGNOSTICS ===" -ForegroundColor Cyan

# 1. Check current session
Write-Host "`n1. Current Session Info:" -ForegroundColor Yellow
Write-Host "   Username: $env:USERNAME"
Write-Host "   Session ID: $PID"
Write-Host "   Interactive: $([Environment]::UserInteractive)"

# 2. Check all sessions
Write-Host "`n2. All User Sessions:" -ForegroundColor Yellow
$sessions = query session 2>$null
$sessions | ForEach-Object { Write-Host "   $_" }

# 3. Check current desktop
Write-Host "`n3. Desktop Context:" -ForegroundColor Yellow
$currentDesktop = [System.Threading.Thread]::CurrentThread.GetApartmentState()
Write-Host "   Apartment State: $currentDesktop"

# 4. Test simple Windows Forms dialog
Write-Host "`n4. Testing Windows Forms MessageBox:" -ForegroundColor Yellow
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.MessageBox]::Show("Can you see this message box?", "UI Test", 'OK', 'Information')
Write-Host "   MessageBox test completed"

# 5. Test WScript.Shell popup
Write-Host "`n5. Testing WScript.Shell Popup:" -ForegroundColor Yellow
$wshell = New-Object -ComObject Wscript.Shell
$result = $wshell.Popup("Can you see this popup? It will auto-close in 10 seconds.", 10, "UI Test 2", 64)
Write-Host "   Popup result: $result"

# 6. Check if running in remote/SSH session
Write-Host "`n6. Remote Session Check:" -ForegroundColor Yellow
Write-Host "   SSH_CLIENT: $env:SSH_CLIENT"
Write-Host "   SSH_TTY: $env:SSH_TTY"
Write-Host "   SESSIONNAME: $env:SESSIONNAME"

# 7. Check display
Write-Host "`n7. Display Check:" -ForegroundColor Yellow
$screens = [System.Windows.Forms.Screen]::AllScreens
Write-Host "   Number of screens: $($screens.Count)"
$screens | ForEach-Object {
    Write-Host "   - $($_.DeviceName): $($_.Bounds.Width)x$($_.Bounds.Height) Primary=$($_.Primary)"
}