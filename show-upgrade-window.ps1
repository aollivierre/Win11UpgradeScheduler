# Try to bring Windows 11 Installation Assistant window to foreground
$process = Get-Process -Name "Windows11InstallationAssistant" -ErrorAction SilentlyContinue
if ($process) {
    Write-Host "Found Installation Assistant process: PID $($process.Id)" -ForegroundColor Green
    
    # Try to activate the window
    Add-Type @"
    using System;
    using System.Runtime.InteropServices;
    public class Win32 {
        [DllImport("user32.dll")]
        public static extern bool SetForegroundWindow(IntPtr hWnd);
        [DllImport("user32.dll")]
        public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    }
"@
    
    $process | ForEach-Object {
        if ($_.MainWindowHandle -ne 0) {
            [Win32]::ShowWindow($_.MainWindowHandle, 5) # SW_SHOW
            [Win32]::SetForegroundWindow($_.MainWindowHandle)
            Write-Host "Attempted to show window" -ForegroundColor Yellow
        } else {
            Write-Host "No visible window found - running in background" -ForegroundColor Yellow
        }
    }
} else {
    Write-Host "Installation Assistant not running!" -ForegroundColor Red
}