# Test session detection function
function Test-UserSession {
    try {
        # Initialize session info
        $sessionInfo = @{
            SessionType = "UNATTENDED"
            UserPresent = $false
            ActiveUser = ""
            IdleTime = 0
            IsRemote = $false
            ConsoleUser = ""
        }
        
        # Method 1: Check for active console user session
        $computerSystem = Get-CimInstance Win32_ComputerSystem
        if ($computerSystem.UserName) {
            $sessionInfo.ConsoleUser = $computerSystem.UserName
            $sessionInfo.UserPresent = $true
            $sessionInfo.SessionType = "ATTENDED"
        }
        
        Write-Output "Computer System User: $($computerSystem.UserName)"
        
        # Method 2: Check Win32_LogonSession for interactive sessions
        $logonSessions = Get-CimInstance Win32_LogonSession | Where-Object {
            $_.LogonType -eq 2 -or  # Interactive
            $_.LogonType -eq 10 -or # RemoteInteractive
            $_.LogonType -eq 11     # CachedInteractive
        }
        
        Write-Output "Found $($logonSessions.Count) interactive sessions"
        
        # Method 3: Check current identity
        $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        Write-Output "Running as: $($currentUser.Name)"
        
        return $sessionInfo
    }
    catch {
        Write-Output "Error: $_"
        return @{
            SessionType = "UNKNOWN"
            UserPresent = $false
        }
    }
}

# Run the test
$result = Test-UserSession
Write-Output "`nSession Detection Results:"
Write-Output "Session Type: $($result.SessionType)"
Write-Output "User Present: $($result.UserPresent)"
Write-Output "Console User: $($result.ConsoleUser)"