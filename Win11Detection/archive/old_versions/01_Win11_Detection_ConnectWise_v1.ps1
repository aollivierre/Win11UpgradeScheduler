#timeout=140000
<#
.SYNOPSIS
    Windows 11 Compatibility Detection Script for ConnectWise RMM
    
.DESCRIPTION
    Phase 1: Detection Only
    This script downloads and executes Microsoft's HardwareReadiness.ps1 script,
    parses the results, and returns them in ConnectWise RMM format.
    
    IMPORTANT: ConnectWise RMM has a fixed 150-second timeout limit.
    This script is optimized to complete within 140 seconds to ensure reliability.
    
    Exit Codes:
    0 = Windows 11 Compatible (CAPABLE)
    1 = Not Compatible (NOT CAPABLE)
    -1 = Undetermined
    -2 = Failed to run
    
.NOTES
    Version: 1.1
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
$script:exitCode = -2  # Default to failed state
$script:outputData = @{
    Win11_Compatible = "UNKNOWN"
    Win11_Status = "FAILED"
    Win11_Reason = "Script initialization"
    Win11_CheckDate = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
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
    
    # Output each field on a separate line for ConnectWise EDFs
    Write-Output "Win11_Compatible: $($Data.Win11_Compatible)"
    Write-Output "Win11_Status: $($Data.Win11_Status)"
    Write-Output "Win11_Reason: $($Data.Win11_Reason)"
    Write-Output "Win11_CheckDate: $($Data.Win11_CheckDate)"
}

# Function to handle script timeout with ConnectWise limits
function Start-ScriptWithTimeout {
    param(
        [scriptblock]$ScriptBlock,
        [int]$TimeoutSeconds = 90,  # Reduced default timeout
        [array]$ArgumentList = @()
    )
    
    # Check if we have enough time remaining
    $remainingTime = Test-ExecutionTime
    if ($TimeoutSeconds -gt $remainingTime) {
        $TimeoutSeconds = [Math]::Floor($remainingTime)
    }
    
    $job = Start-Job -ScriptBlock $ScriptBlock -ArgumentList $ArgumentList
    $completed = Wait-Job -Job $job -Timeout $TimeoutSeconds
    
    if ($null -eq $completed) {
        Stop-Job -Job $job
        Remove-Job -Job $job -Force
        throw "Script execution timed out after $TimeoutSeconds seconds"
    }
    
    $result = Receive-Job -Job $job
    Remove-Job -Job $job -Force
    
    return $result
}

# Main execution block
try {
    Write-Output "Starting Windows 11 compatibility check..."
    
    # Define temporary paths
    $tempPath = Join-Path -Path $env:TEMP -ChildPath "Win11Check"
    $scriptPath = Join-Path -Path $tempPath -ChildPath "HardwareReadiness.ps1"
    $resultPath = Join-Path -Path $tempPath -ChildPath "HardwareReadiness.json"
    
    # Create temporary directory
    if (-not (Test-Path -Path $tempPath)) {
        New-Item -ItemType Directory -Path $tempPath -Force | Out-Null
    }
    
    # Clean up any existing files
    if (Test-Path -Path $scriptPath) {
        Remove-Item -Path $scriptPath -Force
    }
    if (Test-Path -Path $resultPath) {
        Remove-Item -Path $resultPath -Force
    }
    
    Write-Output "Downloading Microsoft HardwareReadiness script..."
    
    # Check execution time before download
    $null = Test-ExecutionTime
    
    # Download the script with reduced retry attempts for ConnectWise timeout
    $downloadUrl = "https://aka.ms/HWReadinessScript"
    $maxRetries = 2  # Reduced from 3
    $retryCount = 0
    $downloadSuccess = $false
    
    while ($retryCount -lt $maxRetries -and -not $downloadSuccess) {
        try {
            # Use different methods based on PowerShell version
            if ($PSVersionTable.PSVersion.Major -ge 3) {
                # Use Invoke-WebRequest for PS 3.0+
                $webClient = New-Object System.Net.WebClient
                
                # Set proxy if needed
                $proxy = [System.Net.WebRequest]::GetSystemWebProxy()
                $proxy.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials
                $webClient.Proxy = $proxy
                
                # Add TLS 1.2 support
                [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
                
                # Download the file
                $webClient.DownloadFile($downloadUrl, $scriptPath)
            } else {
                # Fallback for older PowerShell versions
                $webClient = New-Object System.Net.WebClient
                $webClient.DownloadFile($downloadUrl, $scriptPath)
            }
            
            if (Test-Path -Path $scriptPath) {
                $downloadSuccess = $true
                Write-Output "Download successful"
            }
        }
        catch {
            $retryCount++
            if ($retryCount -lt $maxRetries) {
                Write-Output "Download attempt $retryCount failed, retrying..."
                # Quick retry for ConnectWise timeout
                Start-Sleep -Seconds 1
            } else {
                throw "Failed to download HardwareReadiness.ps1 after $maxRetries attempts: $_"
            }
        }
    }
    
    # Verify the downloaded file
    if (-not (Test-Path -Path $scriptPath)) {
        throw "Downloaded script not found at: $scriptPath"
    }
    
    $fileSize = (Get-Item -Path $scriptPath).Length
    if ($fileSize -lt 1000) {
        throw "Downloaded file appears to be invalid (size: $fileSize bytes)"
    }
    
    Write-Output "Executing hardware readiness check..."
    
    # Check remaining time before execution
    $remainingTime = Test-ExecutionTime
    Write-Output "Time remaining: $([Math]::Round($remainingTime))s"
    
    # Execute the Microsoft script directly and capture output
    try {
        # Change to temp directory
        Push-Location -Path $tempPath
        
        # Execute the script and capture console output
        $scriptOutput = & powershell.exe -ExecutionPolicy Bypass -File $scriptPath -Quiet 2>&1
        
        # The script outputs JSON to console, let's capture it
        $jsonOutput = $scriptOutput | Where-Object { $_ -like "{*}" } | Select-Object -Last 1
        
        if ($jsonOutput) {
            Write-Output "Captured JSON output from console"
            # Save the JSON output to file
            $jsonOutput | Out-File -FilePath $resultPath -Encoding UTF8
        } else {
            # Try running with different parameters if no JSON in output
            Write-Output "No JSON in output, trying with OutputPath parameter..."
            
            # Clear any previous output
            if (Test-Path -Path $resultPath) {
                Remove-Item -Path $resultPath -Force
            }
            
            # Run with explicit output path
            $null = & powershell.exe -ExecutionPolicy Bypass -Command "& '$scriptPath' -Quiet -OutputPath '$resultPath'" 2>&1
            
            # Wait a moment for file creation
            Start-Sleep -Seconds 2
            
            # If still no file, check for default location
            if (-not (Test-Path -Path $resultPath)) {
                $defaultPath = Join-Path -Path $tempPath -ChildPath "HardwareReadiness.json"
                if (Test-Path -Path $defaultPath) {
                    Copy-Item -Path $defaultPath -Destination $resultPath -Force
                } else {
                    throw "Unable to capture hardware readiness results"
                }
            }
        }
    }
    finally {
        Pop-Location
    }
    
    Write-Output "Parsing results..."
    
    # Read and parse the JSON results
    $jsonContent = Get-Content -Path $resultPath -Raw
    $results = $jsonContent | ConvertFrom-Json
    
    # Map Microsoft's results to ConnectWise format
    switch ($results.returnCode) {
        0 {
            # CAPABLE - Windows 11 compatible
            $script:exitCode = 0
            $script:outputData.Win11_Compatible = "YES"
            $script:outputData.Win11_Status = "CAPABLE"
            $script:outputData.Win11_Reason = "System meets all Windows 11 requirements"
        }
        1 {
            # NOT CAPABLE - Not compatible
            $script:exitCode = 1
            $script:outputData.Win11_Compatible = "NO"
            $script:outputData.Win11_Status = "NOT CAPABLE"
            
            # Extract specific failure reasons
            $reasons = @()
            if ($results.returnReason) {
                # Clean up Microsoft's reason string (remove trailing comma/space)
                $cleanReason = $results.returnReason.Trim().TrimEnd(',').Trim()
                if ($cleanReason -and $cleanReason -ne "") {
                    $reasons += $cleanReason
                }
            }
            
            # Parse the logging string for specific failure conditions
            if ($results.logging) {
                $loggingStr = $results.logging.ToString()
                
                # Parse Memory
                if ($loggingStr -match "Memory:\s*System_Memory=(\d+)GB\.\s*(\w+)") {
                    $memorySize = [int]$matches[1]
                    $memoryStatus = $matches[2]
                    if ($memoryStatus -eq "FAIL") {
                        $reasons += "Insufficient RAM: ${memorySize}GB (requires 4GB+)"
                    }
                }
                
                # Parse Storage
                if ($loggingStr -match "Storage:\s*OSDiskSize=(\d+)GB\.\s*(\w+)") {
                    $storageSize = [int]$matches[1]
                    $storageStatus = $matches[2]
                    if ($storageStatus -eq "FAIL") {
                        $reasons += "Insufficient storage: ${storageSize}GB (requires 64GB+)"
                    }
                }
                
                # Parse TPM
                if ($loggingStr -match "TPM:\s*TPMVersion=([0-9.]+)[^.]*\.\s*(\w+)") {
                    $tpmVersion = $matches[1]
                    $tpmStatus = $matches[2]
                    if ($tpmStatus -eq "FAIL" -or [double]$tpmVersion -lt 2.0) {
                        $reasons += "TPM version $tpmVersion (requires 2.0+)"
                    }
                }
                
                # Parse SecureBoot
                if ($loggingStr -match "SecureBoot:\s*(\w+)\.\s*(\w+)") {
                    $secureBootCapable = $matches[1]
                    $secureBootStatus = $matches[2]
                    if ($secureBootStatus -eq "FAIL" -or $secureBootCapable -eq "NotCapable") {
                        $reasons += "Secure Boot not supported"
                    }
                }
                
                # Parse Processor
                if ($loggingStr -match "Processor:.*\.\s*(\w+)") {
                    $processorStatus = $matches[1]
                    if ($processorStatus -eq "FAIL") {
                        $reasons += "Processor not compatible"
                    }
                }
            }
            
            $script:outputData.Win11_Reason = if ($reasons.Count -gt 0) {
                $reasons -join "; "
            } else {
                "System does not meet Windows 11 requirements"
            }
        }
        -1 {
            # UNDETERMINED
            $script:exitCode = -1
            $script:outputData.Win11_Compatible = "UNKNOWN"
            $script:outputData.Win11_Status = "UNDETERMINED"
            $script:outputData.Win11_Reason = if ($results.returnReason) {
                $results.returnReason
            } else {
                "Unable to determine Windows 11 compatibility"
            }
        }
        -2 {
            # FAILED TO RUN
            $script:exitCode = -2
            $script:outputData.Win11_Compatible = "ERROR"
            $script:outputData.Win11_Status = "FAILED"
            $script:outputData.Win11_Reason = if ($results.returnReason) {
                $results.returnReason
            } else {
                "Hardware readiness check failed to execute"
            }
        }
        default {
            # Unexpected return code
            $script:exitCode = -2
            $script:outputData.Win11_Compatible = "ERROR"
            $script:outputData.Win11_Status = "FAILED"
            $script:outputData.Win11_Reason = "Unexpected return code: $($results.returnCode)"
        }
    }
    
    # Update check date with current timestamp
    $script:outputData.Win11_CheckDate = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    
    # Output limited diagnostic information to save time
    if ($results.logging -and $script:exitCode -ne 0) {
        # Only show diagnostics for non-compatible systems
        Write-Output "`nKey Diagnostics:"
        $loggingStr = $results.logging.ToString()
        
        # Extract key values from logging string
        if ($loggingStr -match "TPM:\s*TPMVersion=([0-9.]+)") {
            Write-Output "TPM Version: $($matches[1])"
        }
        if ($loggingStr -match "Memory:\s*System_Memory=(\d+)GB") {
            Write-Output "RAM: $($matches[1])GB"
        }
        if ($loggingStr -match "Storage:\s*OSDiskSize=(\d+)GB") {
            Write-Output "Storage: $($matches[1])GB"
        }
    }
}
catch {
    # Handle any errors
    $errorMessage = $_.Exception.Message
    Write-Output "ERROR: $errorMessage"
    
    $script:exitCode = -2
    $script:outputData.Win11_Compatible = "ERROR"
    $script:outputData.Win11_Status = "FAILED"
    $script:outputData.Win11_Reason = "Error: $errorMessage"
    $script:outputData.Win11_CheckDate = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
}
finally {
    # Calculate and display execution time
    $totalTime = (Get-Date) - $script:startTime
    Write-Output "`nExecution time: $([Math]::Round($totalTime.TotalSeconds, 2))s"
    
    # Clean up temporary files
    try {
        if (Test-Path -Path $tempPath) {
            Remove-Item -Path $tempPath -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Output "Warning: Could not clean up temporary files"
    }
    
    # Output results in ConnectWise format
    Write-Output "`nFinal Results:"
    Write-ConnectWiseOutput -Data $script:outputData
    
    # Exit with appropriate code
    exit $script:exitCode
}