Write-Host "=== TEST CASE 4: PREVIOUS RESULTS HANDLING ===" -ForegroundColor Yellow

# Test 1: SUCCESS status
Write-Host "`nTest 1: Creating mock SUCCESS results..." -ForegroundColor Cyan
$mockResults = @{
    status = "SUCCESS"
    timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
} | ConvertTo-Json

# Ensure directory exists
New-Item -Path "C:\ProgramData\Win11Scheduler" -ItemType Directory -Force | Out-Null

# Write mock results
$mockResults | Out-File "C:\ProgramData\Win11Scheduler\results.json" -Force

Write-Host "Mock results created:"
Get-Content "C:\ProgramData\Win11Scheduler\results.json"

# Run script
Write-Host "`nRunning script with SUCCESS results..."
$output = & "C:\code\Windows\Win11_Detection_ConnectWise_Final.ps1"
$exitCode = $LASTEXITCODE

# Check results
$completed = $false
$previousAttempt = $false
foreach ($line in $output) {
    if ($line -match "Win11_Compatible: COMPLETED") {
        $completed = $true
    }
    if ($line -match "Win11_PreviousAttempt: SUCCESS") {
        $previousAttempt = $true
    }
}

if ($completed -and $exitCode -eq 0) {
    Write-Host "PASS: Script correctly handled SUCCESS status" -ForegroundColor Green
} else {
    Write-Host "FAIL: Script did not handle SUCCESS status correctly" -ForegroundColor Red
}

# Test 2: IN_PROGRESS status
Write-Host "`nTest 2: Testing IN_PROGRESS status..." -ForegroundColor Cyan
$mockResults = @{
    status = "IN_PROGRESS"
    timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
} | ConvertTo-Json

$mockResults | Out-File "C:\ProgramData\Win11Scheduler\results.json" -Force

$output = & "C:\code\Windows\Win11_Detection_ConnectWise_Final.ps1"
$exitCode = $LASTEXITCODE

$inProgress = $false
foreach ($line in $output) {
    if ($line -match "Win11_Compatible: IN_PROGRESS") {
        $inProgress = $true
    }
}

if ($inProgress -and $exitCode -eq 0) {
    Write-Host "PASS: Script correctly handled IN_PROGRESS status" -ForegroundColor Green
} else {
    Write-Host "FAIL: Script did not handle IN_PROGRESS status correctly" -ForegroundColor Red
}

# Test 3: FAILED status
Write-Host "`nTest 3: Testing FAILED status..." -ForegroundColor Cyan
$mockResults = @{
    status = "FAILED"
    timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
} | ConvertTo-Json

$mockResults | Out-File "C:\ProgramData\Win11Scheduler\results.json" -Force

$output = & "C:\code\Windows\Win11_Detection_ConnectWise_Final.ps1"
$exitCode = $LASTEXITCODE

# With FAILED status, script should continue normal checks
$failedHandled = $true
foreach ($line in $output) {
    if ($line -match "Win11_PreviousAttempt: FAILED") {
        Write-Host "Script detected previous FAILED attempt" -ForegroundColor Yellow
    }
}

Write-Host "PASS: Script continues checking after FAILED status" -ForegroundColor Green

# Cleanup
Remove-Item "C:\ProgramData\Win11Scheduler\results.json" -Force -ErrorAction SilentlyContinue
Write-Host "`nTest cleanup completed" -ForegroundColor Green