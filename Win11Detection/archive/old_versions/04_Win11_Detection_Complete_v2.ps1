#timeout=300000
<#
.SYNOPSIS
    Complete Windows 11 Compatibility Detection for ConnectWise RMM v2
.DESCRIPTION
    Performs comprehensive Windows 11 compatibility checks including:
    - Windows 10 version 2004 (build 19041) or later requirement
    - DirectX 12 and WDDM 2.0 checks (missing from Microsoft's script)
    - Microsoft's HardwareReadiness.ps1 checks
    - Proper exit codes for ConnectWise RMM
.NOTES
    Microsoft's official script is missing:
    1. OS version check
    2. DirectX 12 check
    3. WDDM 2.0 driver check
    This wrapper adds those essential checks.
#>

# Initialize result tracking
$compatibilityIssues = @()
$allChecksPassed = $true

try {
    Write-Output "===== Windows 11 Compatibility Check Started ====="
    Write-Output "Check Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    Write-Output "Computer: $env:COMPUTERNAME"
    
    # CHECK 1: Windows 10 Version 2004 or later
    Write-Output "`n--- Checking Windows Version ---"
    
    $os = Get-CimInstance Win32_OperatingSystem
    $currentBuild = [int]$os.BuildNumber
    $osCaption = $os.Caption
    
    Write-Output "Current OS: $osCaption"
    Write-Output "Build Number: $currentBuild"
    
    if ($currentBuild -ge 22000) {
        Write-Output "Already running Windows 11 - no upgrade needed"
        Write-Output "Win11_Compatible: ALREADY_WIN11"
        exit 0
    }
    elseif ($currentBuild -ge 19041) {
        Write-Output "Windows 10 version check: PASS (2004 or later)"
    }
    else {
        Write-Output "Windows 10 version check: FAIL (pre-2004)"
        $compatibilityIssues += "OS Version Too Old (Requires 2004+, build 19041+)"
        $allChecksPassed = $false
    }
    
    # CHECK 2: DirectX 12 Support (Missing from Microsoft's script!)
    Write-Output "`n--- Checking DirectX 12 Support ---"
    
    try {
        $dxDiagPath = "$env:TEMP\dxdiag_output.txt"
        # Run dxdiag silently and save output
        Start-Process "dxdiag.exe" -ArgumentList "/t", $dxDiagPath -Wait -WindowStyle Hidden
        
        if (Test-Path $dxDiagPath) {
            $dxContent = Get-Content $dxDiagPath -Raw
            
            # Check for DirectX 12
            if ($dxContent -match "DirectX Version:\s*DirectX\s*12") {
                Write-Output "DirectX 12 check: PASS"
            }
            elseif ($dxContent -match "DirectX Version:\s*DirectX\s*(\d+)") {
                $dxVersion = $matches[1]
                Write-Output "DirectX check: FAIL (Version $dxVersion found, 12 required)"
                $compatibilityIssues += "DirectX 12 not supported"
                $allChecksPassed = $false
            }
            else {
                Write-Output "DirectX check: UNDETERMINED"
            }
            
            # Check for WDDM version
            if ($dxContent -match "Driver Model:\s*WDDM\s*([\d\.]+)") {
                $wddmVersion = $matches[1]
                if ([version]$wddmVersion -ge [version]"2.0") {
                    Write-Output "WDDM check: PASS (Version $wddmVersion)"
                }
                else {
                    Write-Output "WDDM check: FAIL (Version $wddmVersion, 2.0+ required)"
                    $compatibilityIssues += "WDDM 2.0 driver not supported"
                    $allChecksPassed = $false
                }
            }
            
            Remove-Item $dxDiagPath -Force -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Output "DirectX/WDDM check: ERROR - $_"
        # Non-fatal, continue with other checks
    }
    
    # Alternative method using WMI for graphics check
    try {
        $gpu = Get-CimInstance Win32_VideoController | Select-Object -First 1
        if ($gpu) {
            Write-Output "Graphics adapter: $($gpu.Name)"
            Write-Output "Driver version: $($gpu.DriverVersion)"
        }
    }
    catch {}
    
    # CHECK 3: Run Microsoft's Hardware Checks
    Write-Output "`n--- Running Microsoft Hardware Compatibility Checks ---"
    
    $scriptUrl = "https://aka.ms/HWReadinessScript"
    $localScript = "$env:TEMP\HardwareReadiness.ps1"
    
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        
        Write-Output "Downloading Microsoft HardwareReadiness.ps1..."
        Invoke-WebRequest -Uri $scriptUrl -OutFile $localScript -UseBasicParsing -ErrorAction Stop
        
        Write-Output "Executing hardware compatibility checks..."
        $hwResult = & powershell.exe -ExecutionPolicy Bypass -File $localScript
        
        $hwJson = $hwResult | ConvertFrom-Json
        
        Write-Output "`nHardware Check Result: $($hwJson.returnResult)"
        
        if ($hwJson.returnCode -ne 0) {
            Write-Output "Hardware compatibility: FAIL"
            Write-Output "Reason: $($hwJson.returnReason)"
            $compatibilityIssues += "Hardware: $($hwJson.returnReason)"
            $allChecksPassed = $false
        }
        else {
            Write-Output "Hardware compatibility: PASS"
        }
        
        # Log detailed hardware info
        if ($hwJson.logging) {
            Write-Output "`nDetailed Hardware Information:"
            # Truncate for readability in ConnectWise
            $logLines = $hwJson.logging -split ';' | Select-Object -First 5
            $logLines | ForEach-Object { Write-Output "  $_" }
        }
        
    }
    catch {
        Write-Output "ERROR: Failed to run hardware checks - $_"
        $compatibilityIssues += "Hardware Check Failed: $_"
        $allChecksPassed = $false
    }
    finally {
        if (Test-Path $localScript) {
            Remove-Item $localScript -Force -ErrorAction SilentlyContinue
        }
    }
    
    # Final compatibility determination
    Write-Output "`n===== Final Compatibility Status ====="
    
    if ($allChecksPassed -and $compatibilityIssues.Count -eq 0) {
        Write-Output "Win11_Compatible: YES"
        Write-Output "Win11_Status: CAPABLE"
        Write-Output "Win11_Reason: All checks passed"
        $exitCode = 0
    }
    else {
        Write-Output "Win11_Compatible: NO"
        Write-Output "Win11_Status: NOT CAPABLE"
        Write-Output "Win11_Reason: $($compatibilityIssues -join '; ')"
        $exitCode = 1
    }
    
    Write-Output "Win11_CheckDate: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    Write-Output "`n===== Windows 11 Compatibility Check Completed ====="
    
    exit $exitCode
    
}
catch {
    Write-Output "CRITICAL ERROR: Script execution failed"
    Write-Output "Error: $_"
    Write-Output "Win11_Compatible: ERROR"
    Write-Output "Win11_Status: FAILED TO RUN"
    exit -2
}