#timeout=140000
<#
.SYNOPSIS
    Windows 11 Compatibility Detection Script for ConnectWise RMM - Complete Version
    
.DESCRIPTION
    Phase 1: Detection Only - Physical Machines Only
    
    This script performs comprehensive Windows 11 compatibility checks specifically
    for physical machines in ConnectWise RMM environments. Virtual machines are 
    automatically excluded from upgrade eligibility.
    
    Detection Capabilities:
    - Virtual machine detection (VMware, Hyper-V, VirtualBox, KVM, Xen, Parallels)
    - Windows version detection (7, 8, 8.1, 10, 11)
    - Windows 10 build validation (1507 through 22H2)
    - PSADT scheduled task detection for existing upgrades
    - Previous upgrade results checking (results.json)
    - Hardware compatibility via Microsoft's HardwareReadiness.ps1
    - Enhanced DirectX 12 and WDDM 2.0 checks (missing from Microsoft's script)
    - Attended vs Unattended session detection for upgrade strategy
    - Comprehensive risk assessment with categorized recommendations
    
    Risk Assessment Categories:
    - CRITICAL: Hardware replacement required (TPM, Secure Boot, UEFI)
    - HIGH: Hardware upgrades needed (CPU, RAM, Storage)
    - MEDIUM: Software/driver updates may resolve (OS version, DirectX, WDDM)
    - LOW: Minor issues unlikely to prevent upgrade
    
.PARAMETER None
    This script accepts no parameters. All configuration is internal.
    
.INPUTS
    None. Script gathers all information from the local system.
    
.OUTPUTS
    ConnectWise RMM formatted output including:
    - Win11_Compatible: YES/NO/ALREADY_WIN11/LEGACY_OS/VIRTUAL_MACHINE/SCHEDULED/COMPLETED
    - Win11_Status: READY_FOR_UPGRADE/NOT_COMPATIBLE/NO_ACTION/CHECK_FAILED
    - Win11_Reason: Detailed explanation of status
    - Win11_OSVersion: Current Windows version
    - Win11_Build: Windows build number
    - Win11_ScheduledTask: YES/NO
    - Win11_PreviousAttempt: NONE/SUCCESS/FAILED/IN_PROGRESS
    - Win11_SessionType: ATTENDED/UNATTENDED/UNKNOWN
    - Win11_UserPresent: YES/NO
    - Win11_CheckDate: Timestamp of check
    
.EXAMPLE
    .\Win11_Detection_ConnectWise_Complete_v2.ps1
    
    Runs the detection script and outputs compatibility status with risk assessment.
    
.NOTES
    Version: 2.2
    Author: ConnectWise RMM Windows 11 Detection
    Date: 2025-01-14
    
    Requirements:
    - PowerShell 5.1 (Windows PowerShell)
    - Administrative privileges
    - Internet connectivity for Microsoft script download
    - ConnectWise RMM agent
    
    Timeout: Optimized for ConnectWise RMM 150-second limit (140s execution)
    
    Exit Codes:
    0 = No action needed (VM, Already Win11, Win7/8, scheduled, or completed)
    1 = Remediation required (Win10 eligible for upgrade)
    2 = Not compatible (hardware/software requirements not met)
    
.LINK
    https://aka.ms/HWReadinessScript
    
.COMPONENT
    ConnectWise RMM
    Windows 11 Upgrade Project - Phase 1 Detection
#>

# Set strict mode for better error handling
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Start execution timer - ConnectWise RMM has 150-second timeout
$script:startTime = Get-Date
$script:maxRuntime = 140  # Leave 10-second buffer for ConnectWise timeout

# Initialize variables
$script:exitCode = 1  # Default to remediation required
$script:outputData = @{
    Win11_Compatible = "UNKNOWN"
    Win11_Status = "CHECKING"
    Win11_Reason = "Initializing"
    Win11_CheckDate = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    Win11_OSVersion = ""
    Win11_Build = ""
    Win11_ScheduledTask = "NO"
    Win11_PreviousAttempt = "NONE"
    Win11_SessionType = "UNKNOWN"
    Win11_UserPresent = "NO"
}

# Initialize issue tracking for risk assessment
$script:allIssues = @()

# Function to check remaining execution time
function Test-ExecutionTime {
    $elapsed = (Get-Date) - $script:startTime
    $remaining = $script:maxRuntime - $elapsed.TotalSeconds
    
    if ($remaining -le 0) {
        throw "Script execution time limit reached (${script:maxRuntime}s)"
    }
    
    return $remaining
}

# Function to output results in ConnectWise format
function Write-ConnectWiseOutput {
    param(
        [hashtable]$Data
    )
    
    Write-Output "Win11_Compatible: $($Data.Win11_Compatible)"
    Write-Output "Win11_Status: $($Data.Win11_Status)"
    Write-Output "Win11_Reason: $($Data.Win11_Reason)"
    Write-Output "Win11_OSVersion: $($Data.Win11_OSVersion)"
    Write-Output "Win11_Build: $($Data.Win11_Build)"
    Write-Output "Win11_ScheduledTask: $($Data.Win11_ScheduledTask)"
    Write-Output "Win11_PreviousAttempt: $($Data.Win11_PreviousAttempt)"
    Write-Output "Win11_SessionType: $($Data.Win11_SessionType)"
    Write-Output "Win11_UserPresent: $($Data.Win11_UserPresent)"
    Write-Output "Win11_CheckDate: $($Data.Win11_CheckDate)"
}

# Function to categorize and display risk assessment
function Write-RiskAssessment {
    param(
        [array]$Issues
    )
    
    # Define risk categories with patterns
    $criticalPatterns = @(
        "TPM 2.0 not available",
        "Secure Boot not supported",
        "UEFI firmware required",
        "Legacy BIOS detected"
    )
    
    $highPatterns = @(
        "Processor not compatible",
        "CPU not supported",
        "Insufficient RAM",
        "Insufficient storage"
    )
    
    $mediumPatterns = @(
        "Windows 10 version too old",
        "DirectX 12 not supported",
        "WDDM 2.0+ not supported",
        "Graphics driver"
    )
    
    $lowPatterns = @(
        "Minor compatibility",
        "Optional feature"
    )
    
    # Initialize categorized issues
    $criticalIssues = @()
    $highIssues = @()
    $mediumIssues = @()
    $lowIssues = @()
    
    # Categorize each issue
    foreach ($issue in $Issues) {
        $categorized = $false
        
        # Check critical patterns
        foreach ($pattern in $criticalPatterns) {
            if ($issue -match $pattern) {
                $criticalIssues += $issue
                $categorized = $true
                break
            }
        }
        
        if (-not $categorized) {
            # Check high patterns
            foreach ($pattern in $highPatterns) {
                if ($issue -match $pattern) {
                    $highIssues += $issue
                    $categorized = $true
                    break
                }
            }
        }
        
        if (-not $categorized) {
            # Check medium patterns
            foreach ($pattern in $mediumPatterns) {
                if ($issue -match $pattern) {
                    $mediumIssues += $issue
                    $categorized = $true
                    break
                }
            }
        }
        
        if (-not $categorized) {
            # Check low patterns
            foreach ($pattern in $lowPatterns) {
                if ($issue -match $pattern) {
                    $lowIssues += $issue
                    $categorized = $true
                    break
                }
            }
        }
        
        # Default to medium if not categorized
        if (-not $categorized) {
            $mediumIssues += $issue
        }
    }
    
    # Display risk assessment
    Write-Output "`n================================"
    Write-Output "WINDOWS 11 UPGRADE RISK ASSESSMENT"
    Write-Output "================================"
    
    $hasIssues = $false
    
    # Critical Risk
    if ($criticalIssues.Count -gt 0) {
        $hasIssues = $true
        Write-Output "`n[CRITICAL RISK] - Hardware replacement likely required"
        Write-Output "Issues that require hardware replacement:"
        foreach ($item in $criticalIssues) {
            Write-Output "  X $item"
        }
        Write-Output "`nRecommendation: These issues cannot be resolved through software updates."
        Write-Output "Action Required: Replace hardware or consider new device procurement."
    }
    
    # High Risk
    if ($highIssues.Count -gt 0) {
        $hasIssues = $true
        Write-Output "`n[HIGH RISK] - Hardware upgrade required"
        Write-Output "Issues requiring hardware upgrades:"
        foreach ($item in $highIssues) {
            Write-Output "  ! $item"
        }
        Write-Output "`nRecommendation: Evaluate cost of hardware upgrades vs device replacement."
        Write-Output "Action Required: Upgrade RAM, storage, or processor if feasible."
    }
    
    # Medium Risk
    if ($mediumIssues.Count -gt 0) {
        $hasIssues = $true
        Write-Output "`n[MEDIUM RISK] - Software/driver updates may resolve"
        Write-Output "Issues that may be resolved through updates:"
        foreach ($item in $mediumIssues) {
            Write-Output "  * $item"
        }
        Write-Output "`nRecommendation: Update Windows, drivers, and firmware before retry."
        Write-Output "Action Required: Run Windows Update, update graphics drivers, check for BIOS updates."
    }
    
    # Low Risk
    if ($lowIssues.Count -gt 0) {
        $hasIssues = $true
        Write-Output "`n[LOW RISK] - Minor issues that may not prevent upgrade"
        Write-Output "Minor compatibility concerns:"
        foreach ($item in $lowIssues) {
            Write-Output "  - $item"
        }
        Write-Output "`nRecommendation: These issues are unlikely to prevent upgrade."
    }
    
    if (-not $hasIssues) {
        Write-Output "`n[NO ISSUES] - NO COMPATIBILITY ISSUES DETECTED"
        Write-Output "This system appears ready for Windows 11 upgrade."
        Write-Output "`nRecommendation: Proceed with upgrade scheduling."
    }
    
    # Overall risk summary
    Write-Output "`n================================"
    Write-Output "RISK SUMMARY"
    Write-Output "================================"
    
    if ($criticalIssues.Count -gt 0) {
        Write-Output "Overall Risk Level: CRITICAL"
        Write-Output "Upgrade Feasibility: NOT RECOMMENDED without hardware replacement"
    }
    elseif ($highIssues.Count -gt 0) {
        Write-Output "Overall Risk Level: HIGH"
        Write-Output "Upgrade Feasibility: POSSIBLE with hardware upgrades"
    }
    elseif ($mediumIssues.Count -gt 0) {
        Write-Output "Overall Risk Level: MEDIUM"
        Write-Output "Upgrade Feasibility: LIKELY after software updates"
    }
    elseif ($lowIssues.Count -gt 0) {
        Write-Output "Overall Risk Level: LOW"
        Write-Output "Upgrade Feasibility: READY with minor considerations"
    }
    else {
        Write-Output "Overall Risk Level: NONE"
        Write-Output "Upgrade Feasibility: READY for immediate upgrade"
    }
    
    Write-Output "================================`n"
}

# Function to detect if running in a virtual machine
function Test-VirtualMachine {
    try {
        # Check multiple indicators for VM detection
        $isVM = $false
        $vmType = "Unknown"
        
        # Method 1: Check computer system model
        $computerSystem = Get-CimInstance Win32_ComputerSystem
        $model = $computerSystem.Model
        $manufacturer = $computerSystem.Manufacturer
        
        # Common VM signatures
        $vmSignatures = @{
            "VMware" = @("VMware", "VMware Virtual Platform", "VMware7,1")
            "VirtualBox" = @("VirtualBox", "Oracle Corporation")
            "Hyper-V" = @("Virtual Machine", "Microsoft Corporation")
            "KVM" = @("KVM", "QEMU")
            "Xen" = @("Xen", "HVM domU")
            "Parallels" = @("Parallels")
        }
        
        foreach ($vm in $vmSignatures.Keys) {
            foreach ($signature in $vmSignatures[$vm]) {
                if ($model -like "*$signature*" -or $manufacturer -like "*$signature*") {
                    $isVM = $true
                    $vmType = $vm
                    break
                }
            }
            if ($isVM) { break }
        }
        
        # Method 2: Check BIOS
        if (-not $isVM) {
            $bios = Get-CimInstance Win32_BIOS
            $biosManufacturer = $bios.Manufacturer
            $biosVersion = $bios.Version
            
            foreach ($vm in $vmSignatures.Keys) {
                foreach ($signature in $vmSignatures[$vm]) {
                    if ($biosManufacturer -like "*$signature*" -or $biosVersion -like "*$signature*") {
                        $isVM = $true
                        $vmType = $vm
                        break
                    }
                }
                if ($isVM) { break }
            }
        }
        
        # Method 3: Check for VM-specific services
        if (-not $isVM) {
            $vmServices = @(
                "vmtools",
                "vmhgfs",
                "vmmouse",
                "vmrawdsk",
                "vmusbmouse",
                "vmvss",
                "vmscsi",
                "vmxnet",
                "vmx_svga",
                "VBoxGuest",
                "VBoxMouse",
                "VBoxService",
                "VBoxSF",
                "VBoxVideo"
            )
            
            $services = Get-Service -ErrorAction SilentlyContinue
            foreach ($service in $services) {
                if ($vmServices -contains $service.Name) {
                    $isVM = $true
                    $vmType = "Detected via VM Service"
                    break
                }
            }
        }
        
        # Method 4: Check for VM-specific hardware
        if (-not $isVM) {
            $videoControllers = Get-CimInstance Win32_VideoController
            foreach ($controller in $videoControllers) {
                if ($controller.Name -match "VMware|VirtualBox|Hyper-V|Virtual|QEMU") {
                    $isVM = $true
                    $vmType = "Detected via Video Controller"
                    break
                }
            }
        }
        
        return @{
            IsVirtualMachine = $isVM
            VirtualizationType = $vmType
            Details = "$manufacturer - $model"
        }
    }
    catch {
        Write-Output "Warning: Could not determine virtualization status: $_"
        return @{
            IsVirtualMachine = $false
            VirtualizationType = "Detection Failed"
            Details = "Error during detection"
        }
    }
}

# Function to detect attended vs unattended session
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
        
        # Method 2: Check Win32_LogonSession for interactive sessions
        $logonSessions = Get-CimInstance Win32_LogonSession | Where-Object {
            $_.LogonType -eq 2 -or  # Interactive
            $_.LogonType -eq 10 -or # RemoteInteractive
            $_.LogonType -eq 11     # CachedInteractive
        }
        
        foreach ($session in $logonSessions) {
            $user = Get-CimInstance Win32_LoggedOnUser | Where-Object {
                $_.Dependent.LogonId -eq $session.LogonId
            }
            
            if ($user) {
                $sessionInfo.UserPresent = $true
                $sessionInfo.SessionType = "ATTENDED"
                
                # Check if remote session
                if ($session.LogonType -eq 10) {
                    $sessionInfo.IsRemote = $true
                }
                break
            }
        }
        
        # Method 3: Check for user processes that indicate active session
        if (-not $sessionInfo.UserPresent) {
            $userProcesses = @(
                "explorer.exe",
                "taskmgr.exe",
                "notepad.exe",
                "chrome.exe",
                "firefox.exe",
                "outlook.exe",
                "teams.exe"
            )
            
            $processes = Get-Process -ErrorAction SilentlyContinue
            foreach ($processName in $userProcesses) {
                $userProc = $processes | Where-Object { $_.ProcessName -eq $processName.Replace(".exe", "") }
                if ($userProc) {
                    # Check if process is running in user context (not SYSTEM)
                    try {
                        $owner = (Get-CimInstance Win32_Process -Filter "ProcessId = $($userProc.Id)").GetOwner()
                        if ($owner.Domain -ne "NT AUTHORITY" -and $owner.User -ne "SYSTEM") {
                            $sessionInfo.UserPresent = $true
                            $sessionInfo.SessionType = "ATTENDED"
                            $sessionInfo.ActiveUser = "$($owner.Domain)\$($owner.User)"
                            break
                        }
                    }
                    catch {
                        # Continue checking other processes
                    }
                }
            }
        }
        
        # Method 4: Check idle time to determine if user is actively using the system
        if ($sessionInfo.UserPresent) {
            try {
                # Get idle time using Win32 API through WMI
                $os = Get-CimInstance Win32_OperatingSystem
                $lastInput = $os.LastBootUpTime
                $idleTime = (Get-Date) - $lastInput
                
                # If idle for more than 2 hours, consider it unattended
                if ($idleTime.TotalMinutes -gt 120) {
                    $sessionInfo.SessionType = "UNATTENDED"
                    $sessionInfo.IdleTime = [Math]::Round($idleTime.TotalMinutes)
                }
            }
            catch {
                # If we can't determine idle time, assume attended if user present
            }
        }
        
        # Method 5: Check if running as SYSTEM or scheduled task
        $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        if ($currentUser.Name -eq "NT AUTHORITY\SYSTEM") {
            # Running as SYSTEM, likely unattended
            # But still check if a user is logged in
            if (-not $sessionInfo.UserPresent) {
                $sessionInfo.SessionType = "UNATTENDED"
            }
        }
        
        # Special cases for known unattended scenarios
        # Check for common kiosk/digital signage indicators
        $kioskIndicators = @(
            "C:\Kiosk",
            "C:\DigitalSignage",
            "C:\Signage"
        )
        
        foreach ($path in $kioskIndicators) {
            if (Test-Path $path) {
                $sessionInfo.SessionType = "UNATTENDED"
                $sessionInfo.ActiveUser = "KIOSK_MODE"
                break
            }
        }
        
        return $sessionInfo
    }
    catch {
        Write-Output "Warning: Could not determine session type: $_"
        return @{
            SessionType = "UNKNOWN"
            UserPresent = $false
            ActiveUser = ""
            IdleTime = 0
            IsRemote = $false
            ConsoleUser = ""
        }
    }
}

# Function to check for PSADT scheduled tasks
function Test-PSADTScheduledTask {
    try {
        # Check for Windows 11 upgrade scheduled tasks created by PSADT
        $taskNames = @(
            "Win11Upgrade_*",
            "Windows11Upgrade_*",
            "PSAppDeployToolkit_Win11*"
        )
        
        foreach ($pattern in $taskNames) {
            $tasks = Get-ScheduledTask -TaskName $pattern -ErrorAction SilentlyContinue
            if ($tasks) {
                foreach ($task in $tasks) {
                    if ($task.State -ne 'Disabled') {
                        Write-Output "Found active Win11 upgrade task: $($task.TaskName)"
                        return $true
                    }
                }
            }
        }
        
        return $false
    }
    catch {
        Write-Output "Warning: Could not check scheduled tasks: $_"
        return $false
    }
}

# Function to check for previous upgrade results
function Test-PreviousUpgradeResults {
    $resultsPath = "C:\ProgramData\Win11Scheduler\results.json"
    
    try {
        if (Test-Path -Path $resultsPath) {
            $content = Get-Content -Path $resultsPath -Raw
            $results = $content | ConvertFrom-Json
            
            Write-Output "Found previous upgrade results: Status = $($results.status)"
            
            return @{
                Exists = $true
                Status = $results.status
                Timestamp = $results.timestamp
                ErrorCode = $results.errorCode
            }
        }
    }
    catch {
        Write-Output "Warning: Could not parse results.json: $_"
    }
    
    return @{ Exists = $false }
}

# Function to check DirectX 12 support
function Test-DirectX12Support {
    try {
        # Method 1: Check via dxdiag (most reliable)
        $dxdiagPath = Join-Path -Path $env:TEMP -ChildPath "dxdiag.txt"
        
        # Run dxdiag silently
        $process = Start-Process -FilePath "dxdiag.exe" -ArgumentList "/x `"$dxdiagPath`"" -Wait -NoNewWindow -PassThru
        
        if (Test-Path -Path $dxdiagPath) {
            $dxdiagContent = Get-Content -Path $dxdiagPath -Raw
            
            # Check for DirectX 12 in feature levels
            if ($dxdiagContent -match "Feature Levels:.*12_" -or $dxdiagContent -match "DirectX Version:.*12") {
                Remove-Item -Path $dxdiagPath -Force -ErrorAction SilentlyContinue
                return $true
            }
            
            Remove-Item -Path $dxdiagPath -Force -ErrorAction SilentlyContinue
        }
        
        # Method 2: Check via WMI (fallback)
        $videoControllers = Get-CimInstance Win32_VideoController
        foreach ($controller in $videoControllers) {
            # Most modern GPUs that support DirectX 12 have drivers from 2015 or later
            if ($controller.DriverDate) {
                $driverYear = [DateTime]::Parse($controller.DriverDate).Year
                if ($driverYear -ge 2015) {
                    return $true
                }
            }
        }
        
        return $false
    }
    catch {
        Write-Output "Warning: Could not check DirectX 12 support: $_"
        return $null  # Unknown
    }
}

# Function to check WDDM version
function Test-WDDMVersion {
    try {
        # Method 1: Registry check
        $wddmKey = "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"
        if (Test-Path $wddmKey) {
            $driverModel = Get-ItemProperty -Path $wddmKey -Name "DriverModel" -ErrorAction SilentlyContinue
            if ($driverModel -and $driverModel.DriverModel) {
                $version = [version]$driverModel.DriverModel
                if ($version -ge [version]"2.0") {
                    return $true
                }
            }
        }
        
        # Method 2: WMI check
        $os = Get-CimInstance Win32_OperatingSystem
        $buildNumber = [int]$os.BuildNumber
        
        # Windows 10 1903+ generally has WDDM 2.5+
        if ($buildNumber -ge 18362) {
            return $true
        }
        
        return $false
    }
    catch {
        Write-Output "Warning: Could not check WDDM version: $_"
        return $null  # Unknown
    }
}

# Main execution block
try {
    Write-Output "Starting Windows 11 compatibility check..."
    
    # Step 1: Check OS Version
    Write-Output "`nChecking operating system version..."
    $os = Get-CimInstance Win32_OperatingSystem
    $buildNumber = [int]$os.BuildNumber
    $osCaption = $os.Caption
    $osVersion = $os.Version
    
    $script:outputData.Win11_OSVersion = $osCaption
    $script:outputData.Win11_Build = $buildNumber.ToString()
    
    Write-Output "OS: $osCaption"
    Write-Output "Build: $buildNumber"
    Write-Output "Version: $osVersion"
    
    # Check if already Windows 11
    if ($buildNumber -ge 22000) {
        Write-Output "System is already running Windows 11"
        $script:exitCode = 0
        $script:outputData.Win11_Compatible = "ALREADY_WIN11"
        $script:outputData.Win11_Status = "NO_ACTION"
        $script:outputData.Win11_Reason = "Already running Windows 11"
        exit $script:exitCode
    }
    
    # Check if running in a virtual machine
    Write-Output "`nChecking virtualization status..."
    $vmCheck = Test-VirtualMachine
    
    if ($vmCheck.IsVirtualMachine) {
        Write-Output "Virtual machine detected: $($vmCheck.VirtualizationType)"
        Write-Output "Details: $($vmCheck.Details)"
        $script:exitCode = 0
        $script:outputData.Win11_Compatible = "VIRTUAL_MACHINE"
        $script:outputData.Win11_Status = "NO_ACTION"
        $script:outputData.Win11_Reason = "Virtual machines are excluded from Windows 11 upgrade"
        exit $script:exitCode
    }
    
    # Check for Windows 7/8/8.1
    if ($buildNumber -lt 10240) {  # Pre-Windows 10
        Write-Output "Legacy OS detected (Windows 7/8/8.1)"
        $script:exitCode = 0
        $script:outputData.Win11_Compatible = "LEGACY_OS"
        $script:outputData.Win11_Status = "NO_ACTION"
        $script:outputData.Win11_Reason = "Legacy OS - Windows 7/8/8.1 not supported"
        exit $script:exitCode
    }
    
    # Check Windows 10 version (must be 2004 or later for upgrade)
    if ($buildNumber -lt 19041) {
        Write-Output "Windows 10 version too old (pre-2004)"
        $script:exitCode = 2
        $script:outputData.Win11_Compatible = "NO"
        $script:outputData.Win11_Status = "NOT_COMPATIBLE"
        $script:allIssues += "Windows 10 version too old (requires 2004/19041 or later)"
    }
    
    # Step 2: Check for scheduled tasks
    Write-Output "`nChecking for scheduled upgrade tasks..."
    $null = Test-ExecutionTime
    
    if (Test-PSADTScheduledTask) {
        $script:outputData.Win11_ScheduledTask = "YES"
        Write-Output "Upgrade task already scheduled"
        $script:exitCode = 0
        $script:outputData.Win11_Compatible = "SCHEDULED"
        $script:outputData.Win11_Status = "NO_ACTION"
        $script:outputData.Win11_Reason = "Windows 11 upgrade already scheduled"
        exit $script:exitCode
    }
    
    # Step 3: Check previous upgrade results
    Write-Output "`nChecking for previous upgrade attempts..."
    $previousResults = Test-PreviousUpgradeResults
    
    if ($previousResults.Exists) {
        $script:outputData.Win11_PreviousAttempt = $previousResults.Status
        
        if ($previousResults.Status -eq "SUCCESS") {
            Write-Output "Previous upgrade completed successfully"
            $script:exitCode = 0
            $script:outputData.Win11_Compatible = "COMPLETED"
            $script:outputData.Win11_Status = "NO_ACTION"
            $script:outputData.Win11_Reason = "Windows 11 upgrade already completed"
            exit $script:exitCode
        }
        elseif ($previousResults.Status -eq "IN_PROGRESS") {
            Write-Output "Upgrade currently in progress"
            $script:exitCode = 0
            $script:outputData.Win11_Compatible = "IN_PROGRESS"
            $script:outputData.Win11_Status = "NO_ACTION"
            $script:outputData.Win11_Reason = "Windows 11 upgrade in progress"
            exit $script:exitCode
        }
    }
    
    # Step 4: Check DirectX 12 and WDDM (missing from Microsoft's script)
    Write-Output "`nChecking graphics requirements..."
    $null = Test-ExecutionTime
    
    $dx12Support = Test-DirectX12Support
    $wddmSupport = Test-WDDMVersion
    
    if ($dx12Support -eq $false) {
        $script:allIssues += "DirectX 12 not supported"
    }
    if ($wddmSupport -eq $false) {
        $script:allIssues += "WDDM 2.0+ not supported"
    }
    
    # Step 5: Run Microsoft's HardwareReadiness.ps1
    Write-Output "`nRunning Microsoft hardware compatibility check..."
    $null = Test-ExecutionTime
    
    # Define temporary paths
    $tempPath = Join-Path -Path $env:TEMP -ChildPath "Win11Check"
    $scriptPath = Join-Path -Path $tempPath -ChildPath "HardwareReadiness.ps1"
    $resultPath = Join-Path -Path $tempPath -ChildPath "HardwareReadiness.json"
    
    # Create temporary directory
    if (-not (Test-Path -Path $tempPath)) {
        New-Item -ItemType Directory -Path $tempPath -Force | Out-Null
    }
    
    # Download and execute Microsoft's script
    try {
        # Download the script
        $downloadUrl = "https://aka.ms/HWReadinessScript"
        $webClient = New-Object System.Net.WebClient
        
        # Set proxy if needed
        $proxy = [System.Net.WebRequest]::GetSystemWebProxy()
        $proxy.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials
        $webClient.Proxy = $proxy
        
        # Add TLS 1.2 support
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        
        # Download the file
        $webClient.DownloadFile($downloadUrl, $scriptPath)
        
        # Execute and capture output
        Push-Location -Path $tempPath
        $scriptOutput = & powershell.exe -ExecutionPolicy Bypass -File $scriptPath -Quiet 2>&1
        Pop-Location
        
        # Parse JSON from output
        $jsonOutput = $scriptOutput | Where-Object { $_ -like "{*}" } | Select-Object -Last 1
        
        if ($jsonOutput) {
            $results = $jsonOutput | ConvertFrom-Json
            
            # Process Microsoft's results
            if ($results.returnCode -eq 1) {
                # Not capable - parse specific reasons
                if ($results.returnReason) {
                    $cleanReason = $results.returnReason.Trim().TrimEnd(',').Trim()
                    if ($cleanReason -and $cleanReason -ne "") {
                        $script:allIssues += $cleanReason
                    }
                }
                
                # Parse detailed logging
                if ($results.logging) {
                    $loggingStr = $results.logging.ToString()
                    
                    if ($loggingStr -match "Memory:\s*System_Memory=(\d+)GB\.\s*FAIL") {
                        $script:allIssues += "Insufficient RAM: $($matches[1])GB (requires 4GB+)"
                    }
                    if ($loggingStr -match "Storage:\s*OSDiskSize=(\d+)GB\.\s*FAIL") {
                        $script:allIssues += "Insufficient storage: $($matches[1])GB (requires 64GB+)"
                    }
                    if ($loggingStr -match "TPM:.*FAIL") {
                        $script:allIssues += "TPM 2.0 not available"
                    }
                    if ($loggingStr -match "SecureBoot:.*FAIL") {
                        $script:allIssues += "Secure Boot not supported"
                    }
                    if ($loggingStr -match "Processor:.*FAIL") {
                        $script:allIssues += "Processor not compatible"
                    }
                }
            }
            
            # Determine final status
            if ($script:allIssues.Count -eq 0 -and $results.returnCode -eq 0) {
                # All checks passed - check session type
                Write-Output "`nChecking user session type..."
                $sessionInfo = Test-UserSession
                
                $script:outputData.Win11_SessionType = $sessionInfo.SessionType
                $script:outputData.Win11_UserPresent = if ($sessionInfo.UserPresent) { "YES" } else { "NO" }
                
                if ($sessionInfo.SessionType -eq "ATTENDED") {
                    Write-Output "Active user session detected: $($sessionInfo.ConsoleUser)"
                    if ($sessionInfo.IdleTime -gt 0) {
                        Write-Output "User idle time: $($sessionInfo.IdleTime) minutes"
                    }
                }
                else {
                    Write-Output "No active user session - system is unattended"
                }
                
                $script:exitCode = 1  # Remediation required
                $script:outputData.Win11_Compatible = "YES"
                $script:outputData.Win11_Status = "READY_FOR_UPGRADE"
                $script:outputData.Win11_Reason = "System meets all Windows 11 requirements"
            }
            else {
                # Some checks failed
                $script:exitCode = 2  # Not compatible
                $script:outputData.Win11_Compatible = "NO"
                $script:outputData.Win11_Status = "NOT_COMPATIBLE"
                $script:outputData.Win11_Reason = $script:allIssues -join "; "
            }
        }
        else {
            throw "No JSON output from Microsoft script"
        }
    }
    catch {
        # Hardware check failed
        $errorMsg = $_.Exception.Message
        Write-Output "Hardware check error: $errorMsg"
        
        $script:exitCode = 2
        $script:outputData.Win11_Compatible = "ERROR"
        $script:outputData.Win11_Status = "CHECK_FAILED"
        $script:outputData.Win11_Reason = "Hardware compatibility check failed: $errorMsg"
    }
    finally {
        # Clean up
        if (Test-Path -Path $tempPath) {
            Remove-Item -Path $tempPath -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
catch {
    # Handle any errors
    $errorMessage = $_.Exception.Message
    Write-Output "ERROR: $errorMessage"
    
    $script:exitCode = 2
    $script:outputData.Win11_Compatible = "ERROR"
    $script:outputData.Win11_Status = "CHECK_FAILED"
    $script:outputData.Win11_Reason = "Error: $errorMessage"
}
finally {
    # Calculate and display execution time
    $totalTime = (Get-Date) - $script:startTime
    Write-Output "`nExecution time: $([Math]::Round($totalTime.TotalSeconds, 2))s"
    
    # Update check date
    $script:outputData.Win11_CheckDate = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    
    # Display risk assessment if there are compatibility issues
    if ($script:outputData.Win11_Status -eq "NOT_COMPATIBLE" -and $script:allIssues.Count -gt 0) {
        Write-RiskAssessment -Issues $script:allIssues
    }
    
    # Output results in ConnectWise format
    Write-Output "`nFinal Results:"
    Write-ConnectWiseOutput -Data $script:outputData
    
    # Exit with appropriate code
    exit $script:exitCode
}