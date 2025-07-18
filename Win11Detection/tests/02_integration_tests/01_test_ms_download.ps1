Write-Host "=== TEST CASE 6: Microsoft Script Download ===" -ForegroundColor Yellow

# Test proxy and download functionality
$testPath = "$env:TEMP\HWReadinessTest.ps1"
$downloadUrl = "https://aka.ms/HWReadinessScript"

Write-Host "`nTesting download configuration..." -ForegroundColor Cyan

try {
    # Create web client with proxy settings (as in the script)
    $webClient = New-Object System.Net.WebClient
    
    # Configure proxy
    $proxy = [System.Net.WebRequest]::GetSystemWebProxy()
    $proxy.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials
    $webClient.Proxy = $proxy
    
    Write-Host "  [OK] Proxy configured with system settings" -ForegroundColor Green
    
    # Add TLS 1.2 support
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Write-Host "  [OK] TLS 1.2 enabled" -ForegroundColor Green
    
    # Test download
    Write-Host "`nAttempting download from $downloadUrl..." -ForegroundColor Cyan
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    $webClient.DownloadFile($downloadUrl, $testPath)
    
    $stopwatch.Stop()
    
    if (Test-Path $testPath) {
        $fileInfo = Get-Item $testPath
        Write-Host "SUCCESS: Download completed" -ForegroundColor Green
        Write-Host "  File size: $($fileInfo.Length) bytes" -ForegroundColor Cyan
        Write-Host "  Download time: $([Math]::Round($stopwatch.Elapsed.TotalSeconds, 2)) seconds" -ForegroundColor Cyan
        
        # Verify it's a PowerShell script
        $firstLine = Get-Content $testPath -First 1
        if ($firstLine -match "powershell|param|function|#") {
            Write-Host "  [OK] Downloaded file appears to be a PowerShell script" -ForegroundColor Green
        } else {
            Write-Host "  [WARNING] Downloaded file may not be a PowerShell script" -ForegroundColor Yellow
        }
        
        # Check if it's the HardwareReadiness script
        $content = Get-Content $testPath -Raw
        if ($content -match "HardwareReadiness|Windows.*11|TPM|SecureBoot") {
            Write-Host "  [OK] Downloaded script contains expected Windows 11 content" -ForegroundColor Green
        } else {
            Write-Host "  [WARNING] Script content doesn't match expected pattern" -ForegroundColor Yellow
        }
        
        # Cleanup
        Remove-Item $testPath -Force
        Write-Host "`n[CLEANUP] Test file removed" -ForegroundColor Gray
    } else {
        Write-Host "FAIL: Download failed - file not created" -ForegroundColor Red
    }
    
} catch {
    Write-Host "FAIL: Download failed with error" -ForegroundColor Red
    Write-Host "  Error: $_" -ForegroundColor Red
    
    # Test network connectivity
    Write-Host "`nTesting network connectivity..." -ForegroundColor Yellow
    try {
        $pingResult = Test-Connection "aka.ms" -Count 1 -Quiet
        if ($pingResult) {
            Write-Host "  [OK] Network connectivity confirmed" -ForegroundColor Green
        } else {
            Write-Host "  [FAIL] Cannot reach aka.ms" -ForegroundColor Red
        }
    } catch {
        Write-Host "  [FAIL] Network test failed" -ForegroundColor Red
    }
} finally {
    if ($webClient) {
        $webClient.Dispose()
    }
}

Write-Host "`nProxy Detection Details:" -ForegroundColor Cyan
$systemProxy = [System.Net.WebRequest]::GetSystemWebProxy()
$testUri = [Uri]"https://aka.ms"
$proxyUri = $systemProxy.GetProxy($testUri)

if ($proxyUri.ToString() -eq $testUri.ToString()) {
    Write-Host "  No proxy configured for HTTPS" -ForegroundColor Green
} else {
    Write-Host "  Proxy detected: $proxyUri" -ForegroundColor Yellow
}