Write-Host "=== FEATURE COMPARISON: Final vs 960-line Version ===" -ForegroundColor Yellow

$finalScript = "C:\code\Windows\Win11_Detection_ConnectWise_Final.ps1"
$originalScript = "C:\code\Windows\.archive\Win11_Detection_ConnectWise_v2_960lines_WithSession.ps1"

# Get content
$finalContent = Get-Content $finalScript -Raw
$originalContent = Get-Content $originalScript -Raw

Write-Host "`nScript Sizes:" -ForegroundColor Cyan
Write-Host "  Final Script: $((Get-Item $finalScript).Length) bytes, $((Get-Content $finalScript).Count) lines"
Write-Host "  Original Script: $((Get-Item $originalScript).Length) bytes, $((Get-Content $originalScript).Count) lines"

# Feature checklist
$features = @{
    "Virtual Machine Detection" = @{
        Pattern = "Test-VirtualMachine|Virtual|VMware|VirtualBox|Hyper-V"
        Required = $true
    }
    "Windows Version Detection" = @{
        Pattern = "Win32_OperatingSystem|BuildNumber|Windows 7|Windows 8"
        Required = $true
    }
    "Windows 10 Build Validation" = @{
        Pattern = "19041|19042|19043|19044|19045|22H2|21H2"
        Required = $true
    }
    "PSADT Task Detection" = @{
        Pattern = "Test-PSADTScheduledTask|Win11Upgrade_\*|Windows11Upgrade_\*"
        Required = $true
    }
    "Previous Results Check" = @{
        Pattern = "Test-PreviousUpgradeResults|results\.json"
        Required = $true
    }
    "Microsoft Script Download" = @{
        Pattern = "HardwareReadiness\.ps1|aka\.ms/HWReadinessScript"
        Required = $true
    }
    "DirectX 12 Detection" = @{
        Pattern = "Test-DirectX12Support|dxdiag|DirectX.*12|Feature Levels.*12_"
        Required = $true
    }
    "WDDM 2.0 Detection" = @{
        Pattern = "Test-WDDMVersion|WDDM.*2\."
        Required = $true
    }
    "Storage Space Parsing" = @{
        Pattern = "OSDiskSize|storage.*64GB|Insufficient storage"
        Required = $true
    }
    "RAM Parsing" = @{
        Pattern = "System_Memory|RAM.*4GB|Insufficient RAM"
        Required = $true
    }
    "TPM 2.0 Detection" = @{
        Pattern = "TPM.*2\.0|TPM:.*FAIL"
        Required = $true
    }
    "Secure Boot Detection" = @{
        Pattern = "SecureBoot|Secure Boot"
        Required = $true
    }
    "Processor Compatibility" = @{
        Pattern = "Processor:.*FAIL|Processor not compatible"
        Required = $true
    }
    "Corporate Proxy Config" = @{
        Pattern = "GetSystemWebProxy|DefaultNetworkCredentials|\$webClient\.Proxy"
        Required = $true
    }
    "Risk Assessment" = @{
        Pattern = "Write-RiskAssessment|CRITICAL.*RISK|HIGH.*RISK|MEDIUM.*RISK"
        Required = $true
    }
    "ConnectWise Output" = @{
        Pattern = "Write-ConnectWiseOutput|Win11_Compatible:|Win11_Status:"
        Required = $true
    }
    "140s Timeout" = @{
        Pattern = "#timeout=140|maxRuntime.*140"
        Required = $true
    }
    "Session Detection" = @{
        Pattern = "Test-UserSession|explorer\.exe|Win11_SessionType|Win11_UserPresent"
        Required = $false
    }
}

Write-Host "`nFeature Comparison:" -ForegroundColor Cyan

$missingRequired = @()
$presentFeatures = @()
$removedAcceptable = @()

foreach ($feature in $features.GetEnumerator()) {
    $name = $feature.Key
    $pattern = $feature.Value.Pattern
    $required = $feature.Value.Required
    
    $inFinal = $finalContent -match $pattern
    $inOriginal = $originalContent -match $pattern
    
    if ($inFinal) {
        Write-Host ("  [OK] " + $name) -ForegroundColor Green
        $presentFeatures += $name
    } elseif ($required) {
        Write-Host ("  [MISSING] " + $name + " - REQUIRED!") -ForegroundColor Red
        $missingRequired += $name
    } else {
        Write-Host ("  [REMOVED] " + $name + " - Acceptable") -ForegroundColor Yellow
        $removedAcceptable += $name
    }
}

# Additional checks
Write-Host "`nAdditional Analysis:" -ForegroundColor Cyan

# Check exit codes
if ($finalContent -match 'exit.*0.*no.*action|exit.*1.*remediation|exit.*2.*not.*compatible') {
    Write-Host "  [OK] Exit codes properly implemented" -ForegroundColor Green
} else {
    Write-Host "  [WARNING] Exit code implementation unclear" -ForegroundColor Yellow
}

# Check TLS 1.2
if ($finalContent -match 'SecurityProtocol.*Tls12') {
    Write-Host "  [OK] TLS 1.2 support enabled" -ForegroundColor Green
} else {
    Write-Host "  [MISSING] TLS 1.2 configuration" -ForegroundColor Red
}

# Summary
Write-Host "`nSummary:" -ForegroundColor Cyan
Write-Host "  Features Present: $($presentFeatures.Count)"
Write-Host "  Required Missing: $($missingRequired.Count)"
Write-Host "  Acceptable Removals: $($removedAcceptable.Count)"

if ($missingRequired.Count -eq 0) {
    Write-Host "`nPASS: All required features are present" -ForegroundColor Green
} else {
    Write-Host "`nFAIL: Missing $($missingRequired.Count) required features" -ForegroundColor Red
    foreach ($missing in $missingRequired) {
        Write-Host "  - $missing" -ForegroundColor Red
    }
}