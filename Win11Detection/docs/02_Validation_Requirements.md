# Windows 11 Detection Script - Comprehensive Validation and Testing Prompt

## Critical Context
You are tasked with empirically validating and testing a Windows 11 detection script for ConnectWise RMM deployment. This is a production-critical script that will run on thousands of enterprise machines. **EMPIRICAL TESTING IS MANDATORY** - do not make assumptions or provide theoretical answers.

## Script Location
Primary Script: `C:\code\Windows\Win11_Detection_ConnectWise_Final.ps1`

## Validation Requirements

### 1. Feature Completeness Verification
**TASK**: Compare the final script against the original 960-line version to ensure NO critical features were lost.

**Original Version**: `C:\code\Windows\.archive\Win11_Detection_ConnectWise_v2_960lines_WithSession.ps1`

**Required Features to Verify**:
- [ ] Virtual machine detection (VMware, Hyper-V, VirtualBox, KVM, Xen, Parallels)
- [ ] Windows version detection (7, 8, 8.1, 10, 11)
- [ ] Windows 10 build validation (1507-22H2)
- [ ] PSADT scheduled task detection
- [ ] Previous upgrade results checking
- [ ] Microsoft HardwareReadiness.ps1 download and execution
- [ ] DirectX 12 detection
- [ ] WDDM 2.0 detection
- [ ] Storage space parsing from Microsoft script output
- [ ] RAM insufficiency parsing
- [ ] TPM 2.0 detection
- [ ] Secure Boot detection
- [ ] Processor compatibility
- [ ] Corporate proxy configuration
- [ ] Risk assessment categorization (CRITICAL/HIGH/MEDIUM/LOW)
- [ ] ConnectWise RMM output formatting
- [ ] 140-second timeout enforcement

**Acceptable Removals**:
- Session detection (Test-UserSession function)
- Win11_SessionType output
- Win11_UserPresent output

### 2. Empirical Testing Requirements

#### Test Environment Setup
```powershell
# Create test directories
New-Item -Path "C:\ProgramData\Win11Scheduler" -ItemType Directory -Force
New-Item -Path "$env:TEMP\Win11DetectionTest" -ItemType Directory -Force
```

#### Test Case 1: Basic Execution
```powershell
# Run the script and capture output
$output = & "C:\code\Windows\Win11_Detection_ConnectWise_Final.ps1"
$exitCode = $LASTEXITCODE

# Verify output format
$output | ForEach-Object { Write-Host "OUTPUT: $_" }
Write-Host "EXIT CODE: $exitCode"
```

#### Test Case 2: Timeout Validation
```powershell
# Measure execution time
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
& "C:\code\Windows\Win11_Detection_ConnectWise_Final.ps1"
$stopwatch.Stop()

# Should complete within 140 seconds
if ($stopwatch.Elapsed.TotalSeconds -gt 140) {
    Write-Host "FAIL: Script exceeded 140-second timeout" -ForegroundColor Red
}
```

#### Test Case 3: Virtual Machine Detection
```powershell
# Test VM detection logic separately
$vmFunction = Get-Content "C:\code\Windows\Win11_Detection_ConnectWise_Final.ps1" -Raw
# Extract and test Test-VirtualMachine function
```

#### Test Case 4: Previous Results Handling
```powershell
# Create mock results file
$mockResults = @{
    status = "SUCCESS"
    timestamp = (Get-Date).ToString()
} | ConvertTo-Json

$mockResults | Out-File "C:\ProgramData\Win11Scheduler\results.json"

# Run script - should detect previous success
& "C:\code\Windows\Win11_Detection_ConnectWise_Final.ps1"
# Verify exit code is 0
```

#### Test Case 5: Scheduled Task Detection
```powershell
# Create a mock scheduled task
$action = New-ScheduledTaskAction -Execute "powershell.exe"
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddDays(1)
Register-ScheduledTask -TaskName "Win11Upgrade_Test" -Action $action -Trigger $trigger

# Run script - should detect scheduled task
& "C:\code\Windows\Win11_Detection_ConnectWise_Final.ps1"
# Verify exit code is 0

# Cleanup
Unregister-ScheduledTask -TaskName "Win11Upgrade_Test" -Confirm:$false
```

#### Test Case 6: Microsoft Script Download
```powershell
# Test proxy and download functionality
$testPath = "$env:TEMP\HWReadinessTest.ps1"
$webClient = New-Object System.Net.WebClient

# Configure proxy as in script
$proxy = [System.Net.WebRequest]::GetSystemWebProxy()
$proxy.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials
$webClient.Proxy = $proxy

# Test download
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
try {
    $webClient.DownloadFile("https://aka.ms/HWReadinessScript", $testPath)
    Write-Host "SUCCESS: Download working with proxy" -ForegroundColor Green
} catch {
    Write-Host "FAIL: Download failed - $_" -ForegroundColor Red
}
```

#### Test Case 7: Output Parsing
```powershell
# Run script and parse output
$output = & "C:\code\Windows\Win11_Detection_ConnectWise_Final.ps1" 2>&1

# Check for required output fields
$requiredFields = @(
    "Win11_Compatible",
    "Win11_Status", 
    "Win11_Reason",
    "Win11_OSVersion",
    "Win11_Build",
    "Win11_ScheduledTask",
    "Win11_PreviousAttempt",
    "Win11_CheckDate"
)

foreach ($field in $requiredFields) {
    if ($output -notmatch "$field`:") {
        Write-Host "FAIL: Missing output field - $field" -ForegroundColor Red
    }
}
```

#### Test Case 8: Error Handling
```powershell
# Test with restricted permissions
# Create a standard user context test if possible
# Verify script handles errors gracefully
```

### 3. Code Quality Checks

#### PowerShell 5.1 Compatibility
```powershell
# Check for PS7+ features that shouldn't be present
$scriptContent = Get-Content "C:\code\Windows\Win11_Detection_ConnectWise_Final.ps1" -Raw

# Check for null coalescing (??)
if ($scriptContent -match '\?\?') {
    Write-Host "FAIL: Found PS7 null coalescing operator" -ForegroundColor Red
}

# Check for ternary operator (? :)
if ($scriptContent -match '\?.*:') {
    Write-Host "WARNING: Possible ternary operator found" -ForegroundColor Yellow
}

# Check for proper null comparisons
if ($scriptContent -match '\$\w+\s+-eq\s+\$null') {
    Write-Host "FAIL: Improper null comparison (should be $null -eq)" -ForegroundColor Red
}
```

#### Exit Code Validation
Verify the script returns correct exit codes:
- 0 = No action needed (VM, Win11, Win7/8, scheduled, completed)
- 1 = Remediation required (eligible for upgrade)
- 2 = Not compatible (requirements not met)

### 4. Performance Testing

#### Memory Usage
```powershell
$process = Start-Process powershell -ArgumentList "-File `"C:\code\Windows\Win11_Detection_ConnectWise_Final.ps1`"" -PassThru
Start-Sleep -Seconds 5
$memoryUsage = (Get-Process -Id $process.Id -ErrorAction SilentlyContinue).WorkingSet64 / 1MB
Write-Host "Memory Usage: $([Math]::Round($memoryUsage, 2)) MB"
```

### 5. ConnectWise RMM Integration Test

Create a mock ConnectWise environment:
```powershell
# Simulate ConnectWise execution
$env:PROCESSOR_ARCHITECTURE = "AMD64"
$timeoutJob = Start-Job -ScriptBlock {
    & "C:\code\Windows\Win11_Detection_ConnectWise_Final.ps1"
}

# Wait max 150 seconds (ConnectWise limit)
$result = Wait-Job -Job $timeoutJob -Timeout 150
if (-not $result) {
    Write-Host "FAIL: Script would timeout in ConnectWise" -ForegroundColor Red
    Stop-Job -Job $timeoutJob
}
```

### 6. Regression Testing

Compare outputs between old and new versions on the same machine:
```powershell
# Note: Skip session-related outputs in comparison
$oldOutput = & "C:\code\Windows\.archive\Win11_Detection_ConnectWise_v2_960lines_WithSession.ps1" 2>&1
$newOutput = & "C:\code\Windows\Win11_Detection_ConnectWise_Final.ps1" 2>&1

# Compare non-session outputs
# Document any differences
```

### 7. Edge Case Testing

1. **No Internet Connection**: Disconnect network and run script
2. **Corrupted Results File**: Create malformed JSON in results.json
3. **Permission Issues**: Run with limited permissions
4. **Already Windows 11**: Test on Windows 11 machine if available
5. **Legacy OS**: Test on Windows 7/8 VM if available

## Deliverables Required

1. **Test Execution Report**:
   - Each test case result (PASS/FAIL)
   - Actual output captured
   - Execution times
   - Any errors encountered

2. **Feature Comparison Matrix**:
   - Feature present in 960-line version: ✓/✗
   - Feature present in final version: ✓/✗
   - Justification if removed

3. **Performance Metrics**:
   - Average execution time
   - Memory usage
   - CPU usage during execution

4. **Recommendations**:
   - Any bugs found
   - Performance improvements needed
   - Code corrections required

## Critical Reminders

1. **DO NOT SIMULATE** - Actually run every test
2. **DO NOT ASSUME** - Verify every feature works
3. **CAPTURE ALL OUTPUT** - Include actual command outputs
4. **TEST ERROR PATHS** - Don't just test happy path
5. **MEASURE PERFORMANCE** - Use actual timing/metrics

## Script Safety Check

Before testing, verify the script is safe:
1. Check for any destructive operations
2. Verify it only reads system information
3. Ensure temporary files are cleaned up
4. Confirm no system modifications are made

## Expected Timeline

This comprehensive validation should take 1-2 hours to complete thoroughly. Do not rush - accuracy is more important than speed.

Remember: This script will run on production systems. Your validation directly impacts thousands of enterprise computers. Be thorough, be empirical, be accurate.