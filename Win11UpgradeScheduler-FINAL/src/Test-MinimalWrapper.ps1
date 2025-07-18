<#
.SYNOPSIS
    Minimal test of wrapper functionality
#>

param(
    [string]$PSADTPath = "C:\Code\Win11UpgradeScheduler\Win11UpgradeScheduler-FINAL\src"
)

# Simple logging
function Write-TestLog {
    param($Message)
    $logPath = "$env:ProgramData\Win11UpgradeScheduler\Logs"
    if (-not (Test-Path $logPath)) {
        New-Item -Path $logPath -ItemType Directory -Force | Out-Null
    }
    $logFile = Join-Path $logPath "TestWrapper_$(Get-Date -Format 'yyyyMMdd').log"
    $entry = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $Message"
    Add-Content -Path $logFile -Value $entry -Force
    Write-Host $entry -ForegroundColor Yellow
}

try {
    Write-TestLog "Test wrapper started"
    Write-TestLog "PSADTPath: $PSADTPath"
    
    # Check context
    $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
    $isSystem = ($currentUser -eq 'NT AUTHORITY\SYSTEM')
    Write-TestLog "Current user: $currentUser (IsSystem: $isSystem)"
    
    # Check for user sessions
    $explorerProcesses = Get-CimInstance -ClassName Win32_Process -Filter "Name = 'explorer.exe'" |
        Where-Object { $_.SessionId -ne 0 }
    $hasUserSession = $explorerProcesses.Count -gt 0
    Write-TestLog "Has user session: $hasUserSession"
    
    if ($hasUserSession) {
        Write-TestLog "Loading PSADT toolkit..."
        $toolkitMain = Join-Path -Path $PSADTPath -ChildPath 'AppDeployToolkit\AppDeployToolkitMain.ps1'
        . $toolkitMain
        
        Write-TestLog "Creating countdown script..."
        $countdownScript = @"
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.MessageBox]::Show('Test from user context!', 'Test', 'OK', 'Information')
exit 0
"@
        
        $tempScript = "$env:TEMP\TestCountdown_$(Get-Date -Format 'yyyyMMddHHmmss').ps1"
        $countdownScript | Set-Content -Path $tempScript -Force
        
        Write-TestLog "Executing in user context..."
        if ($isSystem) {
            $result = Execute-ProcessAsUser -Path "$PSHOME\powershell.exe" `
                -Parameters "-ExecutionPolicy Bypass -File `"$tempScript`"" `
                -Wait
            Write-TestLog "Execute-ProcessAsUser exit code: $($result.ExitCode)"
        } else {
            $proc = Start-Process -FilePath 'powershell.exe' `
                -ArgumentList "-ExecutionPolicy Bypass -File `"$tempScript`"" `
                -Wait -PassThru
            Write-TestLog "Start-Process exit code: $($proc.ExitCode)"
        }
        
        Remove-Item -Path $tempScript -Force -ErrorAction SilentlyContinue
    }
    
    Write-TestLog "Test completed successfully"
} catch {
    Write-TestLog "ERROR: $_"
    Write-Host "Error details: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Stack trace: $($_.ScriptStackTrace)" -ForegroundColor Red
}