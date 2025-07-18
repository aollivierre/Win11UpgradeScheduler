#timeout=140000
<#
.SYNOPSIS
    Windows 11 Compatibility Detection Script for ConnectWise RMM - Complete Version
    
.DESCRIPTION
    Phase 1: Detection Only
    This script performs comprehensive Windows 11 compatibility checks including:
    - Windows version detection (7, 8, 10, 11)
    - Windows 10 build validation (1507-22H2)
    - Scheduled task detection (PSADT created tasks)
    - Previous upgrade results checking
    - Hardware compatibility via Microsoft's HardwareReadiness.ps1
    - Additional DirectX 12 and WDDM 2.0 checks
    
    ConnectWise RMM Exit Codes:
    0 = No action needed (Already Win11, Win7/8, or upgrade scheduled/completed)
    1 = Remediation required (Win10 eligible for upgrade)
    2 = Not compatible (hardware doesn't meet requirements)
    
.NOTES
    Version: 2.0
    Author: ConnectWise RMM Windows 11 Detection
    Date: 2025-01-14
    Timeout: Optimized for ConnectWise RMM 150-second limit
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
}

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
    Write-Output "Win11_CheckDate: $($Data.Win11_CheckDate)"
}

# Function to categorize and display risk assessment
function Write-RiskAssessment {
    param(
        [array]$Issues
    )
    
    # Define risk categories
    $riskCategories = @{
        Critical = @{
            Items = @()
            Patterns = @(
                "TPM 2.0 not available",
                "Secure Boot not supported",
                "UEFI firmware required",
                "Legacy BIOS detected"
            )
            Message = "CRITICAL - Hardware replacement likely required"
        }
        High = @{
            Items = @()
            Patterns = @(
                "Processor not compatible",
                "CPU not supported",
                "Insufficient RAM",
                "Insufficient storage"
            )
            Message = "HIGH - Hardware upgrade required"
        }
        Medium = @{
            Items = @()
            Patterns = @(
                "Windows 10 version too old",
                "DirectX 12 not supported",
                "WDDM 2.0+ not supported",
                "Graphics driver"
            )
            Message = "MEDIUM - Software/driver updates may resolve"
        }
        Low = @{
            Items = @()
            Patterns = @(
                "Minor compatibility",
                "Optional feature"
            )
            Message = "LOW - Minor issues that may not prevent upgrade"
        }
    }
    
    # Categorize issues
    foreach ($issue in $Issues) {
        $categorized = $false
        
        foreach ($category in $riskCategories.Keys) {
            foreach ($pattern in $riskCategories[$category].Patterns) {
                if ($issue -match $pattern) {
                    $riskCategories[$category].Items += $issue
                    $categorized = $true
                    break
                }
            }
            if ($categorized) { break }
        }
        
        # If not categorized, put in Medium
        if (-not $categorized) {
            $riskCategories.Medium.Items += $issue
        }
    }
    
    # Display risk assessment
    Write-Output "`n================================"
    Write-Output "WINDOWS 11 UPGRADE RISK ASSESSMENT"
    Write-Output "================================"
    
    $hasIssues = $false
    
    # Critical Risk
    if ($riskCategories.Critical.Items.Count -gt 0) {
        $hasIssues = $true
        Write-Output "`n[CRITICAL RISK] - $($riskCategories.Critical.Message)"
        Write-Output "Issues that require hardware replacement:"
        foreach ($item in $riskCategories.Critical.Items) {
            Write-Output "  ✗ $item"
        }
        Write-Output "`nRecommendation: These issues cannot be resolved through software updates."
        Write-Output "Action Required: Replace hardware or consider new device procurement."
    }
    
    # High Risk
    if ($riskCategories.High.Items.Count -gt 0) {
        $hasIssues = $true
        Write-Output "`n[HIGH RISK] - $($riskCategories.High.Message)"
        Write-Output "Issues requiring hardware upgrades:"
        foreach ($item in $riskCategories.High.Items) {
            Write-Output "  ⚠ $item"
        }
        Write-Output "`nRecommendation: Evaluate cost of hardware upgrades vs device replacement."
        Write-Output "Action Required: Upgrade RAM, storage, or processor if feasible."
    }
    
    # Medium Risk
    if ($riskCategories.Medium.Items.Count -gt 0) {
        $hasIssues = $true
        Write-Output "`n[MEDIUM RISK] - $($riskCategories.Medium.Message)"
        Write-Output "Issues that may be resolved through updates:"
        foreach ($item in $riskCategories.Medium.Items) {
            Write-Output "  ⚡ $item"
        }
        Write-Output "`nRecommendation: Update Windows, drivers, and firmware before retry."
        Write-Output "Action Required: Run Windows Update, update graphics drivers, check for BIOS updates."
    }
    
    # Low Risk
    if ($riskCategories.Low.Items.Count -gt 0) {
        $hasIssues = $true
        Write-Output "`n[LOW RISK] - $($riskCategories.Low.Message)"
        Write-Output "Minor compatibility concerns:"
        foreach ($item in $riskCategories.Low.Items) {
            Write-Output "  ℹ $item"
        }
        Write-Output "`nRecommendation: These issues are unlikely to prevent upgrade."
    }
    
    if (-not $hasIssues) {
        Write-Output "`n✓ NO COMPATIBILITY ISSUES DETECTED"
        Write-Output "This system appears ready for Windows 11 upgrade."
        Write-Output "`nRecommendation: Proceed with upgrade scheduling."
    }
    
    # Overall risk summary
    Write-Output "`n================================"
    Write-Output "RISK SUMMARY"
    Write-Output "================================"
    
    if ($riskCategories.Critical.Items.Count -gt 0) {
        Write-Output "Overall Risk Level: CRITICAL"
        Write-Output "Upgrade Feasibility: NOT RECOMMENDED without hardware replacement"
    }
    elseif ($riskCategories.High.Items.Count -gt 0) {
        Write-Output "Overall Risk Level: HIGH"
        Write-Output "Upgrade Feasibility: POSSIBLE with hardware upgrades"
    }
    elseif ($riskCategories.Medium.Items.Count -gt 0) {
        Write-Output "Overall Risk Level: MEDIUM"
        Write-Output "Upgrade Feasibility: LIKELY after software updates"
    }
    elseif ($riskCategories.Low.Items.Count -gt 0) {
        Write-Output "Overall Risk Level: LOW"
        Write-Output "Upgrade Feasibility: READY with minor considerations"
    }
    else {
        Write-Output "Overall Risk Level: NONE"
        Write-Output "Upgrade Feasibility: READY for immediate upgrade"
    }
    
    Write-Output "================================`n"
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
        $script:outputData.Win11_Reason = "Windows 10 version too old (requires 2004/19041 or later)"
        # Don't exit yet - still check hardware
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
    
    $graphicsIssues = @()
    if ($dx12Support -eq $false) {
        $graphicsIssues += "DirectX 12 not supported"
    }
    if ($wddmSupport -eq $false) {
        $graphicsIssues += "WDDM 2.0+ not supported"
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
            $hardwareReasons = @()
            
            if ($results.returnCode -eq 1) {
                # Not capable - parse specific reasons
                if ($results.returnReason) {
                    $hardwareReasons += $results.returnReason.Trim().TrimEnd(',').Trim()
                }
                
                # Parse detailed logging
                if ($results.logging) {
                    $loggingStr = $results.logging.ToString()
                    
                    if ($loggingStr -match "Memory:\s*System_Memory=(\d+)GB\.\s*FAIL") {
                        $hardwareReasons += "Insufficient RAM: $($matches[1])GB (requires 4GB+)"
                    }
                    if ($loggingStr -match "Storage:\s*OSDiskSize=(\d+)GB\.\s*FAIL") {
                        $hardwareReasons += "Insufficient storage: $($matches[1])GB (requires 64GB+)"
                    }
                    if ($loggingStr -match "TPM:.*FAIL") {
                        $hardwareReasons += "TPM 2.0 not available"
                    }
                    if ($loggingStr -match "SecureBoot:.*FAIL") {
                        $hardwareReasons += "Secure Boot not supported"
                    }
                    if ($loggingStr -match "Processor:.*FAIL") {
                        $hardwareReasons += "Processor not compatible"
                    }
                }
            }
            
            # Combine all compatibility issues
            $allIssues = @()
            
            # Add OS version issue if applicable
            if ($buildNumber -lt 19041) {
                $allIssues += "Windows 10 version too old (requires 2004+)"
            }
            
            # Add graphics issues
            $allIssues += $graphicsIssues
            
            # Add hardware issues
            $allIssues += $hardwareReasons
            
            # Determine final status
            if ($allIssues.Count -eq 0 -and $results.returnCode -eq 0) {
                # All checks passed
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
                $script:outputData.Win11_Reason = $allIssues -join "; "
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
    if ($script:outputData.Win11_Status -eq "NOT_COMPATIBLE" -and $script:outputData.Win11_Reason -ne "Error") {
        # Parse issues from the reason string
        $issues = $script:outputData.Win11_Reason -split ";\s*" | Where-Object { $_ -ne "" }
        if ($issues.Count -gt 0) {
            Write-RiskAssessment -Issues $issues
        }
    }
    
    # Output results in ConnectWise format
    Write-Output "`nFinal Results:"
    Write-ConnectWiseOutput -Data $script:outputData
    
    # Exit with appropriate code
    exit $script:exitCode
}