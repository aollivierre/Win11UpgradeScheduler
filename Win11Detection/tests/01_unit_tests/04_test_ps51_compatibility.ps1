Write-Host "=== CODE QUALITY CHECK: PowerShell 5.1 Compatibility ===" -ForegroundColor Yellow

# Read script content
$scriptPath = "C:\code\Windows\Win11_Detection_ConnectWise_Final.ps1"
$scriptContent = Get-Content $scriptPath -Raw

Write-Host "`nChecking for PowerShell 7+ features..." -ForegroundColor Cyan

$issues = @()

# Check for null coalescing operator (??)
if ($scriptContent -match '\?\?') {
    $issues += "Found PS7 null coalescing operator (??)"
    Write-Host "  [FAIL] Found null coalescing operator (??)" -ForegroundColor Red
} else {
    Write-Host "  [PASS] No null coalescing operator found" -ForegroundColor Green
}

# Check for null conditional operator (?.)
if ($scriptContent -match '\?\.') {
    $issues += "Found PS7 null conditional operator (?.)"
    Write-Host "  [FAIL] Found null conditional operator (?.)" -ForegroundColor Red
} else {
    Write-Host "  [PASS] No null conditional operator found" -ForegroundColor Green
}

# Check for ternary operator (? :)
if ($scriptContent -match '\s+\?\s+.*\s+:\s+') {
    $issues += "Possible ternary operator found"
    Write-Host "  [WARNING] Possible ternary operator pattern detected" -ForegroundColor Yellow
} else {
    Write-Host "  [PASS] No ternary operator found" -ForegroundColor Green
}

# Check for proper null comparisons ($null -eq, not $var -eq $null)
$improperNullChecks = [regex]::Matches($scriptContent, '\$\w+\s+-eq\s+\$null')
if ($improperNullChecks.Count -gt 0) {
    $issues += "Found $($improperNullChecks.Count) improper null comparisons"
    Write-Host "  [FAIL] Found improper null comparisons (should be `$null -eq)" -ForegroundColor Red
    foreach ($match in $improperNullChecks) {
        Write-Host "    Line contains: $($match.Value)" -ForegroundColor Yellow
    }
} else {
    Write-Host "  [PASS] All null comparisons properly formatted" -ForegroundColor Green
}

# Check for variable colon syntax issues ($var:value)
if ($scriptContent -match '\$\w+:\s*\w+' -and $scriptContent -notmatch '\$script:') {
    $issues += "Possible variable colon syntax issue"
    Write-Host "  [WARNING] Possible variable colon syntax issue" -ForegroundColor Yellow
} else {
    Write-Host "  [PASS] No variable colon syntax issues" -ForegroundColor Green
}

# Check for && and || operators
if ($scriptContent -match '&&' -or $scriptContent -match '\|\|') {
    $issues += "Found PS7 logical operators (&& or ||)"
    Write-Host "  [FAIL] Found PS7 logical operators (&& or ||)" -ForegroundColor Red
} else {
    Write-Host "  [PASS] No PS7 logical operators found" -ForegroundColor Green
}

# Check Set-StrictMode
if ($scriptContent -match 'Set-StrictMode\s+-Version\s+Latest') {
    Write-Host "  [PASS] Set-StrictMode -Version Latest is set" -ForegroundColor Green
} else {
    Write-Host "  [WARNING] Set-StrictMode not found or not set to Latest" -ForegroundColor Yellow
}

# Check error handling
if ($scriptContent -match '\$ErrorActionPreference\s*=\s*[''"]Stop[''"]') {
    Write-Host "  [PASS] ErrorActionPreference set to Stop" -ForegroundColor Green
} else {
    Write-Host "  [WARNING] ErrorActionPreference not set to Stop" -ForegroundColor Yellow
}

# Check for #timeout directive
if ($scriptContent -match '^#timeout=\d+') {
    Write-Host "  [PASS] ConnectWise timeout directive found" -ForegroundColor Green
} else {
    Write-Host "  [WARNING] No #timeout directive found" -ForegroundColor Yellow
}

# Verify PowerShell version compatibility
Write-Host "`nPowerShell Version Check:" -ForegroundColor Cyan
Write-Host "  Current PS Version: $($PSVersionTable.PSVersion)" -ForegroundColor Cyan
if ($PSVersionTable.PSVersion.Major -eq 5 -and $PSVersionTable.PSVersion.Minor -eq 1) {
    Write-Host "  [INFO] Running on PowerShell 5.1 - target environment" -ForegroundColor Green
} else {
    Write-Host "  [INFO] Not running on PS 5.1 - some compatibility issues may not be detected" -ForegroundColor Yellow
}

# Summary
Write-Host "`nSummary:" -ForegroundColor Cyan
if ($issues.Count -eq 0) {
    Write-Host "PASS: Script is PowerShell 5.1 compatible" -ForegroundColor Green
} else {
    Write-Host "FAIL: Found $($issues.Count) compatibility issues:" -ForegroundColor Red
    foreach ($issue in $issues) {
        Write-Host "  - $issue" -ForegroundColor Red
    }
}