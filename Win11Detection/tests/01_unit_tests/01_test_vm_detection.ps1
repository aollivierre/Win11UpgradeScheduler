Write-Host "=== TEST CASE 3: VIRTUAL MACHINE DETECTION ===" -ForegroundColor Yellow

# Test VM detection
$cs = Get-CimInstance Win32_ComputerSystem
$bios = Get-CimInstance Win32_BIOS

Write-Host "`nSystem Information:" -ForegroundColor Cyan
Write-Host "  Manufacturer: $($cs.Manufacturer)"
Write-Host "  Model: $($cs.Model)"
Write-Host "  BIOS: $($bios.Manufacturer)"

# Test pattern matching
$vmPatterns = "Virtual|VMware|VirtualBox|Hyper-V|KVM|Xen|Parallels|QEMU"

$modelMatch = $cs.Model -match $vmPatterns
$mfrMatch = $cs.Manufacturer -match $vmPatterns
$biosMatch = $bios.Manufacturer -match $vmPatterns

Write-Host "`nPattern Matching Results:" -ForegroundColor Cyan
Write-Host "  Model matches VM pattern: $modelMatch"
Write-Host "  Manufacturer matches VM pattern: $mfrMatch"
Write-Host "  BIOS matches VM pattern: $biosMatch"

# Run script and check output
Write-Host "`nRunning detection script..." -ForegroundColor Yellow
$output = & "C:\code\Windows\Win11_Detection_ConnectWise_Final.ps1"
$exitCode = $LASTEXITCODE

# Check for VM detection in output
$vmDetected = $false
$correctStatus = $false

foreach ($line in $output) {
    if ($line -match "Virtual machine detected") {
        $vmDetected = $true
    }
    if ($line -match "Win11_Compatible: VIRTUAL_MACHINE") {
        $correctStatus = $true
    }
}

Write-Host "`nTest Results:" -ForegroundColor Cyan
if ($vmDetected) {
    Write-Host "PASS: Script detected virtual machine" -ForegroundColor Green
} else {
    Write-Host "FAIL: Script did not detect virtual machine" -ForegroundColor Red
}

if ($correctStatus) {
    Write-Host "PASS: Correct VIRTUAL_MACHINE status set" -ForegroundColor Green
} else {
    Write-Host "FAIL: Incorrect status for VM" -ForegroundColor Red
}

if ($exitCode -eq 0) {
    Write-Host "PASS: Correct exit code (0) for VM" -ForegroundColor Green
} else {
    Write-Host "FAIL: Wrong exit code ($exitCode) for VM" -ForegroundColor Red
}