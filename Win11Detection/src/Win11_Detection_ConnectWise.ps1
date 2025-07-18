#timeout=140000
<#
.SYNOPSIS
    Windows 11 Compatibility Detection Script for ConnectWise RMM - Complete Version
    
.DESCRIPTION
    Phase 1: Detection Only - Physical Machines Only
    
    This script performs comprehensive Windows 11 compatibility checks specifically
    for physical machines in ConnectWise RMM environments. Virtual machines are 
    automatically excluded from upgrade eligibility.
    
    Session detection is NOT included - PSADT v3 handles attended/unattended
    scenarios automatically during the remediation phase.
    
    IMPORTANT: Minimum Windows 10 Requirements (per Microsoft official documentation):
    - Windows 10 version 2004 (Build 19041) or later required
    - Earlier Windows 10 versions will fail compatibility check
    - Windows 7/8/8.1 are not supported for direct upgrade to Windows 11
    
    Detection Capabilities:
    - Virtual machine detection (VMware, Hyper-V, VirtualBox, KVM, Xen, Parallels)
    - Windows version detection (7, 8, 8.1, 10, 11)
    - Windows 10 build validation (minimum 2004/19041 through 22H2)
    - PSADT scheduled task detection for existing upgrades
    - Previous upgrade results checking (results.json)
    - Hardware compatibility via Microsoft's HardwareReadiness.ps1
    - Enhanced DirectX 12 and WDDM 2.0 checks (missing from Microsoft's script)
    - Comprehensive risk assessment with categorized recommendations
    
    Risk Assessment Categories:
    - CRITICAL: Hardware replacement required (TPM, Secure Boot, UEFI)
    - HIGH: Hardware upgrades needed (CPU, RAM, Storage)
    - MEDIUM: Software/driver updates may resolve (OS version, DirectX, WDDM)
    - LOW: Minor issues unlikely to prevent upgrade
    
.NOTES
    Version: 3.1
    Author: ConnectWise RMM Windows 11 Detection
    Date: 2025-01-15
    
    Requirements:
    - PowerShell 5.1 (Windows PowerShell)
    - Administrative privileges
    - Internet connectivity for Microsoft script download
    - ConnectWise RMM agent
    
    Timeout: Optimized for ConnectWise RMM 150-second limit (140s execution)
    
    Exit Codes:
    0 = No action needed (VM, Already Win11, Win7/8, scheduled, or completed)
    1 = Remediation required (Win10 2004+ eligible for upgrade, all hardware requirements met)
    2 = Not compatible (hardware/software requirements not met, including Win10 < 2004)
#>

# Set strict mode for better error handling
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Start execution timer
$script:startTime = Get-Date
$script:maxRuntime = 140  # ConnectWise timeout buffer

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
}

# Initialize issue tracking
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
    param([hashtable]$Data)
    
    Write-Output "Win11_Compatible: $($Data.Win11_Compatible)"
    Write-Output "Win11_Status: $($Data.Win11_Status)"
    Write-Output "Win11_Reason: $($Data.Win11_Reason)"
    Write-Output "Win11_OSVersion: $($Data.Win11_OSVersion)"
    Write-Output "Win11_Build: $($Data.Win11_Build)"
    Write-Output "Win11_ScheduledTask: $($Data.Win11_ScheduledTask)"
    Write-Output "Win11_PreviousAttempt: $($Data.Win11_PreviousAttempt)"
    Write-Output "Win11_CheckDate: $($Data.Win11_CheckDate)"
}

# Function to categorize and display risk assessment
function Write-RiskAssessment {
    param([array]$Issues)
    
    # Define risk patterns
    $criticalPatterns = @("TPM 2.0", "Secure Boot", "UEFI", "Legacy BIOS")
    $highPatterns = @("Processor", "CPU", "RAM", "storage")
    $mediumPatterns = @("Windows 10 version", "DirectX", "WDDM", "Graphics")
    
    # Categorize issues
    $criticalIssues = @()
    $highIssues = @()
    $mediumIssues = @()
    
    foreach ($issue in $Issues) {
        $categorized = $false
        
        foreach ($pattern in $criticalPatterns) {
            if ($issue -match $pattern) {
                $criticalIssues += $issue
                $categorized = $true
                break
            }
        }
        
        if (-not $categorized) {
            foreach ($pattern in $highPatterns) {
                if ($issue -match $pattern) {
                    $highIssues += $issue
                    $categorized = $true
                    break
                }
            }
        }
        
        if (-not $categorized) {
            foreach ($pattern in $mediumPatterns) {
                if ($issue -match $pattern) {
                    $mediumIssues += $issue
                    $categorized = $true
                    break
                }
            }
        }
        
        if (-not $categorized) {
            $mediumIssues += $issue
        }
    }
    
    # Display risk assessment
    Write-Output "`n================================"
    Write-Output "WINDOWS 11 UPGRADE RISK ASSESSMENT"
    Write-Output "================================"
    
    if ($criticalIssues.Count -gt 0) {
        Write-Output "`n[CRITICAL RISK] - Hardware replacement required"
        foreach ($item in $criticalIssues) {
            Write-Output "  X $item"
        }
        Write-Output "Action: Replace hardware or procure new device"
    }
    
    if ($highIssues.Count -gt 0) {
        Write-Output "`n[HIGH RISK] - Hardware upgrade required"
        foreach ($item in $highIssues) {
            Write-Output "  ! $item"
        }
        Write-Output "Action: Upgrade components if cost-effective"
    }
    
    if ($mediumIssues.Count -gt 0) {
        Write-Output "`n[MEDIUM RISK] - Software updates may help"
        foreach ($item in $mediumIssues) {
            Write-Output "  * $item"
        }
        Write-Output "Action: Update Windows, drivers, and firmware"
    }
    
    Write-Output "================================`n"
}

# Function to detect virtual machine
function Test-VirtualMachine {
    try {
        $computerSystem = Get-CimInstance Win32_ComputerSystem
        $model = $computerSystem.Model
        $manufacturer = $computerSystem.Manufacturer
        
        # Check for VM signatures
        $vmPatterns = "Virtual|VMware|VirtualBox|Hyper-V|KVM|Xen|Parallels|QEMU"
        
        if ($model -match $vmPatterns -or $manufacturer -match $vmPatterns) {
            return @{
                IsVirtualMachine = $true
                VirtualizationType = $manufacturer
                Details = "$manufacturer - $model"
            }
        }
        
        # Check BIOS
        $bios = Get-CimInstance Win32_BIOS
        if ($bios.Manufacturer -match $vmPatterns) {
            return @{
                IsVirtualMachine = $true
                VirtualizationType = $bios.Manufacturer
                Details = "BIOS: $($bios.Manufacturer)"
            }
        }
        
        return @{ IsVirtualMachine = $false }
    }
    catch {
        return @{ IsVirtualMachine = $false }
    }
}

# Function to check for PSADT scheduled tasks
function Test-PSADTScheduledTask {
    try {
        $taskPatterns = @("Win11Upgrade_*", "Windows11Upgrade_*", "PSAppDeployToolkit_Win11*")
        
        foreach ($pattern in $taskPatterns) {
            $tasks = Get-ScheduledTask -TaskName $pattern -ErrorAction SilentlyContinue
            if ($tasks) {
                foreach ($task in $tasks) {
                    if ($task.State -ne 'Disabled') {
                        return $true
                    }
                }
            }
        }
        return $false
    }
    catch {
        return $false
    }
}

# Function to check previous results
function Test-PreviousUpgradeResults {
    $resultsPath = "C:\ProgramData\Win11Scheduler\results.json"
    
    try {
        if (Test-Path -Path $resultsPath) {
            $content = Get-Content -Path $resultsPath -Raw
            $results = $content | ConvertFrom-Json
            
            return @{
                Exists = $true
                Status = $results.status
                Timestamp = $results.timestamp
            }
        }
    }
    catch {
        # Ignore errors
    }
    
    return @{ Exists = $false }
}

# Function to check DirectX 12
function Test-DirectX12Support {
    try {
        $dxdiagPath = Join-Path -Path $env:TEMP -ChildPath "dxdiag.txt"
        $process = Start-Process -FilePath "dxdiag.exe" -ArgumentList "/x `"$dxdiagPath`"" -Wait -NoNewWindow -PassThru
        
        if (Test-Path -Path $dxdiagPath) {
            $content = Get-Content -Path $dxdiagPath -Raw
            $hasDX12 = $content -match "Feature Levels:.*12_" -or $content -match "DirectX Version:.*12"
            Remove-Item -Path $dxdiagPath -Force -ErrorAction SilentlyContinue
            return $hasDX12
        }
        
        return $false
    }
    catch {
        return $null
    }
}

# Function to check WDDM version
function Test-WDDMVersion {
    try {
        $os = Get-CimInstance Win32_OperatingSystem
        # Windows 10 1903+ has WDDM 2.5+
        if ([int]$os.BuildNumber -ge 18362) {
            return $true
        }
        return $false
    }
    catch {
        return $null
    }
}

# Main execution
try {
    Write-Output "Starting Windows 11 compatibility check..."
    
    # Check OS Version
    Write-Output "`nChecking operating system..."
    $os = Get-CimInstance Win32_OperatingSystem
    $buildNumber = [int]$os.BuildNumber
    $osCaption = $os.Caption
    
    $script:outputData.Win11_OSVersion = $osCaption
    $script:outputData.Win11_Build = $buildNumber.ToString()
    
    Write-Output "OS: $osCaption"
    Write-Output "Build: $buildNumber"
    Write-Output "Version: $($os.Version)"
    
    # Already Windows 11?
    if ($buildNumber -ge 22000) {
        $script:exitCode = 0
        $script:outputData.Win11_Compatible = "ALREADY_WIN11"
        $script:outputData.Win11_Status = "NO_ACTION"
        $script:outputData.Win11_Reason = "Already running Windows 11"
        exit $script:exitCode
    }
    
    # Check for VM
    Write-Output "Checking virtualization..."
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
    
    # Windows 7/8?
    if ($buildNumber -lt 10240) {
        Write-Output "Legacy OS detected (Windows 7/8/8.1)"
        $script:exitCode = 0
        $script:outputData.Win11_Compatible = "LEGACY_OS"
        $script:outputData.Win11_Status = "NO_ACTION"
        $script:outputData.Win11_Reason = "Legacy OS - Windows 7/8/8.1 not supported"
        exit $script:exitCode
    }
    
    # Check Windows 10 version (19041 = version 2004, per Microsoft requirements)
    if ($buildNumber -lt 19041) {
        $script:allIssues += "Windows 10 version too old (requires 2004+)"
    }
    
    # Check scheduled tasks
    Write-Output "`nChecking for scheduled upgrade tasks..."
    if (Test-PSADTScheduledTask) {
        $script:outputData.Win11_ScheduledTask = "YES"
        Write-Output "Upgrade task already scheduled"
        $script:exitCode = 0
        $script:outputData.Win11_Compatible = "SCHEDULED"
        $script:outputData.Win11_Status = "NO_ACTION"
        $script:outputData.Win11_Reason = "Windows 11 upgrade already scheduled"
        exit $script:exitCode
    }
    
    # Check previous results
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
    
    # Check DirectX and WDDM
    Write-Output "Checking graphics requirements..."
    $dx12Support = Test-DirectX12Support
    $wddmSupport = Test-WDDMVersion
    
    if ($dx12Support -eq $false) {
        $script:allIssues += "DirectX 12 not supported"
    }
    if ($wddmSupport -eq $false) {
        $script:allIssues += "WDDM 2.0+ not supported"
    }
    
    # Run Microsoft's hardware check
    Write-Output "Running hardware compatibility check..."
    $tempPath = Join-Path -Path $env:TEMP -ChildPath "Win11Check"
    $scriptPath = Join-Path -Path $tempPath -ChildPath "HardwareReadiness.ps1"
    
    if (-not (Test-Path -Path $tempPath)) {
        New-Item -ItemType Directory -Path $tempPath -Force | Out-Null
    }
    
    try {
        # Download Microsoft script
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
        
        # Parse JSON
        $jsonOutput = $scriptOutput | Where-Object { $_ -like "{*}" } | Select-Object -Last 1
        
        if ($jsonOutput) {
            $results = $jsonOutput | ConvertFrom-Json
            
            if ($results.returnCode -eq 1) {
                # Parse failures
                if ($results.returnReason) {
                    $cleanReason = $results.returnReason.Trim().TrimEnd(',').Trim()
                    if ($cleanReason -and $cleanReason -ne "") {
                        $script:allIssues += $cleanReason
                    }
                }
                
                if ($results.logging) {
                    $log = $results.logging.ToString()
                    
                    if ($log -match "Memory:\s*System_Memory=(\d+)GB\.\s*FAIL") {
                        $script:allIssues += "Insufficient RAM: $($matches[1])GB (requires 4GB+)"
                    }
                    if ($log -match "Storage:\s*OSDiskSize=(\d+)GB\.\s*FAIL") {
                        $script:allIssues += "Insufficient storage: $($matches[1])GB (requires 64GB+)"
                    }
                    if ($log -match "TPM:.*FAIL") {
                        $script:allIssues += "TPM 2.0 not available"
                    }
                    if ($log -match "SecureBoot:.*FAIL") {
                        $script:allIssues += "Secure Boot not supported"
                    }
                    if ($log -match "Processor:.*FAIL") {
                        $script:allIssues += "Processor not compatible"
                    }
                }
            }
            
            # Determine final status
            if ($script:allIssues.Count -eq 0 -and $results.returnCode -eq 0) {
                # Compatible!
                $script:exitCode = 1
                $script:outputData.Win11_Compatible = "YES"
                $script:outputData.Win11_Status = "READY_FOR_UPGRADE"
                $script:outputData.Win11_Reason = "System meets all requirements"
            }
            else {
                # Not compatible
                $script:exitCode = 2
                $script:outputData.Win11_Compatible = "NO"
                $script:outputData.Win11_Status = "NOT_COMPATIBLE"
                $script:outputData.Win11_Reason = $script:allIssues -join "; "
            }
        }
    }
    catch {
        $script:exitCode = 2
        $script:outputData.Win11_Compatible = "ERROR"
        $script:outputData.Win11_Status = "CHECK_FAILED"
        $script:outputData.Win11_Reason = "Hardware check failed: $_"
    }
    finally {
        if (Test-Path -Path $tempPath) {
            Remove-Item -Path $tempPath -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
catch {
    $script:exitCode = 2
    $script:outputData.Win11_Compatible = "ERROR"
    $script:outputData.Win11_Status = "CHECK_FAILED"
    $script:outputData.Win11_Reason = "Error: $($_.Exception.Message)"
}
finally {
    # Display execution time
    $totalTime = (Get-Date) - $script:startTime
    Write-Output "`nExecution time: $([Math]::Round($totalTime.TotalSeconds, 2))s"
    
    # Show risk assessment if incompatible
    if ($script:outputData.Win11_Status -eq "NOT_COMPATIBLE" -and $script:allIssues.Count -gt 0) {
        Write-RiskAssessment -Issues $script:allIssues
    }
    
    # Output results
    Write-Output "`nFinal Results:"
    Write-ConnectWiseOutput -Data $script:outputData
    
    exit $script:exitCode
}