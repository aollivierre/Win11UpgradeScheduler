Write-Host "=== TEST CASE 7: OUTPUT PARSING ===" -ForegroundColor Yellow

# Run script and capture output
$output = & "C:\code\Windows\Win11_Detection_ConnectWise_Final.ps1" 2>&1

# Define required output fields
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

Write-Host "`nChecking for required output fields..." -ForegroundColor Cyan

$allFieldsFound = $true
$foundFields = @{}

foreach ($field in $requiredFields) {
    $found = $false
    $pattern = "^${field}: (.+)$"
    foreach ($line in $output) {
        if ($line -match $pattern) {
            $found = $true
            $foundFields[$field] = $matches[1]
            break
        }
    }
    
    if ($found) {
        Write-Host ("  [OK] " + $field + ": " + $foundFields[$field]) -ForegroundColor Green
    } else {
        Write-Host ("  [MISSING] " + $field) -ForegroundColor Red
        $allFieldsFound = $false
    }
}

Write-Host "`nField Validation:" -ForegroundColor Cyan

# Validate Win11_Compatible values
$validCompatValues = @("YES", "NO", "VIRTUAL_MACHINE", "ALREADY_WIN11", "LEGACY_OS", "SCHEDULED", "COMPLETED", "IN_PROGRESS", "ERROR")
if ($foundFields["Win11_Compatible"] -in $validCompatValues) {
    Write-Host "  [OK] Win11_Compatible has valid value" -ForegroundColor Green
} else {
    Write-Host ("  [ERROR] Win11_Compatible has invalid value: " + $foundFields["Win11_Compatible"]) -ForegroundColor Red
}

# Validate Win11_Status values
$validStatusValues = @("READY_FOR_UPGRADE", "NO_ACTION", "NOT_COMPATIBLE", "CHECK_FAILED")
if ($foundFields["Win11_Status"] -in $validStatusValues) {
    Write-Host "  [OK] Win11_Status has valid value" -ForegroundColor Green
} else {
    Write-Host ("  [ERROR] Win11_Status has invalid value: " + $foundFields["Win11_Status"]) -ForegroundColor Red
}

# Validate Win11_ScheduledTask
if ($foundFields["Win11_ScheduledTask"] -in @("YES", "NO")) {
    Write-Host "  [OK] Win11_ScheduledTask has valid value" -ForegroundColor Green
} else {
    Write-Host ("  [ERROR] Win11_ScheduledTask has invalid value: " + $foundFields["Win11_ScheduledTask"]) -ForegroundColor Red
}

# Validate date format
$datePattern = '\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}'
if ($foundFields["Win11_CheckDate"] -match $datePattern) {
    Write-Host "  [OK] Win11_CheckDate has valid datetime format" -ForegroundColor Green
} else {
    Write-Host ("  [ERROR] Win11_CheckDate has invalid format: " + $foundFields["Win11_CheckDate"]) -ForegroundColor Red
}

Write-Host "`nOverall Result:" -ForegroundColor Cyan
if ($allFieldsFound) {
    Write-Host "PASS: All required fields present in output" -ForegroundColor Green
} else {
    Write-Host "FAIL: Some required fields missing from output" -ForegroundColor Red
}

# Display full output for verification
Write-Host "`nFull Script Output:" -ForegroundColor Cyan
$output | ForEach-Object { Write-Host $_ }