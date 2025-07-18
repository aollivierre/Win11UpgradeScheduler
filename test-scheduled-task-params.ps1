# Test script to validate scheduled task parameters
param(
    [string]$PSADTPath,
    [string]$DeploymentType,
    [string]$DeployMode
)

Write-Host "====== Parameter Test Results ======"
Write-Host "PSADTPath: $PSADTPath"
Write-Host "DeploymentType: $DeploymentType"
Write-Host "DeployMode: $DeployMode"
Write-Host ""

# Validate parameters
$errors = @()

if (-not $PSADTPath) {
    $errors += "PSADTPath is empty"
} elseif (-not (Test-Path $PSADTPath)) {
    $errors += "PSADTPath does not exist: $PSADTPath"
} else {
    Write-Host "[OK] PSADTPath exists"
}

if (-not $DeploymentType) {
    $errors += "DeploymentType is empty"
} elseif ($DeploymentType -notin @('Install', 'Uninstall')) {
    $errors += "DeploymentType invalid: $DeploymentType (must be Install or Uninstall)"
} else {
    Write-Host "[OK] DeploymentType is valid: $DeploymentType"
}

if (-not $DeployMode) {
    $errors += "DeployMode is empty"
} elseif ($DeployMode -notin @('Interactive', 'Silent', 'NonInteractive')) {
    $errors += "DeployMode invalid: $DeployMode (must be Interactive, Silent, or NonInteractive)"
} else {
    Write-Host "[OK] DeployMode is valid: $DeployMode"
}

# Check if wrapper script exists
$wrapperPath = Join-Path $PSADTPath -ChildPath 'SupportFiles\ScheduledTaskWrapper.ps1'
if (Test-Path $wrapperPath) {
    Write-Host "[OK] Wrapper script found at: $wrapperPath"
} else {
    $errors += "Wrapper script not found at: $wrapperPath"
}

Write-Host ""
if ($errors.Count -eq 0) {
    Write-Host "SUCCESS: All parameters are valid!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "ERRORS FOUND:" -ForegroundColor Red
    $errors | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    exit 1
}