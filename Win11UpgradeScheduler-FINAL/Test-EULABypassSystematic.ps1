# Systematic EULA Bypass Testing Script for Windows 11 Installation Assistant
# This script tests various parameter combinations to find a working EULA bypass

param(
    [string]$AssistantPath = ".\src\Files\Windows11InstallationAssistant.exe",
    [string]$LogPath = ".\EULA_Bypass_Test_Results.csv",
    [switch]$AutomatedTesting
)

# Ensure running as administrator
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This script must be run as Administrator!" -ForegroundColor Red
    exit 1
}

# Verify Installation Assistant exists
if (-not (Test-Path $AssistantPath)) {
    Write-Host "Windows 11 Installation Assistant not found at: $AssistantPath" -ForegroundColor Red
    exit 1
}

# Initialize results array
$testResults = @()

# Define test cases - all parameter combinations to test
$testCases = @(
    # Single parameters
    @{Name="SkipEULA Only"; Params=@("/SkipEULA")},
    @{Name="QuietInstall Only"; Params=@("/QuietInstall")},
    @{Name="Silent Only"; Params=@("/Silent")},
    @{Name="S Only"; Params=@("/S")},
    @{Name="Auto Only"; Params=@("/Auto")},
    @{Name="Auto Upgrade"; Params=@("/Auto", "Upgrade")},
    
    # Common combinations
    @{Name="SkipEULA + QuietInstall"; Params=@("/SkipEULA", "/QuietInstall")},
    @{Name="SkipEULA + Silent"; Params=@("/SkipEULA", "/Silent")},
    @{Name="SkipEULA + Auto Upgrade"; Params=@("/SkipEULA", "/Auto", "Upgrade")},
    @{Name="SkipEULA + QuietInstall + Auto"; Params=@("/SkipEULA", "/QuietInstall", "/Auto", "Upgrade")},
    
    # Alternative EULA parameters
    @{Name="AcceptEULA"; Params=@("/AcceptEULA")},
    @{Name="EULA Accept"; Params=@("/EULA", "Accept")},
    @{Name="EulaAccepted"; Params=@("/EulaAccepted")},
    @{Name="SkipEula (lowercase)"; Params=@("/skipeula")},
    @{Name="SKIPEULA (uppercase)"; Params=@("/SKIPEULA")},
    
    # Undocumented possibilities
    @{Name="Unattended"; Params=@("/Unattended")},
    @{Name="NoUI"; Params=@("/NoUI")},
    @{Name="Passive"; Params=@("/Passive")},
    @{Name="Q"; Params=@("/Q")},
    @{Name="QN"; Params=@("/QN")},
    @{Name="QB"; Params=@("/QB")},
    
    # Complex combinations
    @{Name="All Common Params"; Params=@("/SkipEULA", "/QuietInstall", "/Auto", "Upgrade", "/NoRestartUI")},
    @{Name="With Install Flag"; Params=@("/Install", "/SkipEULA", "/QuietInstall")},
    @{Name="MinimizeToTaskBar Combo"; Params=@("/Install", "/MinimizeToTaskBar", "/QuietInstall", "/SkipEULA")},
    
    # Force/Override attempts
    @{Name="Force + SkipEULA"; Params=@("/Force", "/SkipEULA")},
    @{Name="Override + SkipEULA"; Params=@("/Override", "/SkipEULA")},
    @{Name="NoPrompt"; Params=@("/NoPrompt")},
    
    # MSI-style parameters (in case it recognizes them)
    @{Name="MSI Style Quiet"; Params=@("/quiet", "/norestart")},
    @{Name="MSI Style AcceptEULA"; Params=@("/quiet", "/AcceptEula", "1")},
    @{Name="MSI Style IAccept"; Params=@("/quiet", "IACCEPTWINDOWSLICENSETERMS=1")}
)

# Function to test a parameter combination
function Test-ParameterCombination {
    param(
        [string]$TestName,
        [array]$Parameters
    )
    
    Write-Host "`n=== Testing: $TestName ===" -ForegroundColor Cyan
    Write-Host "Parameters: $($Parameters -join ' ')" -ForegroundColor Gray
    
    $result = @{
        TestName = $TestName
        Parameters = $Parameters -join ' '
        StartTime = Get-Date
        EULAAppeared = $false
        ProcessExitCode = $null
        ErrorMessage = ""
        Notes = ""
    }
    
    try {
        # Start the process
        $process = Start-Process -FilePath $AssistantPath `
            -ArgumentList $Parameters `
            -PassThru `
            -NoNewWindow:$false
        
        # Monitor for EULA window (give it 10 seconds to appear)
        $eulaTitlePatterns = @("License", "EULA", "Agreement", "Terms", "Windows 11 Installation Assistant")
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        
        while ($stopwatch.Elapsed.TotalSeconds -lt 10 -and -not $process.HasExited) {
            Start-Sleep -Milliseconds 500
            
            # Check for EULA window
            $windows = Get-Process | Where-Object {$_.MainWindowTitle -ne ""} | Select-Object MainWindowTitle
            foreach ($window in $windows) {
                foreach ($pattern in $eulaTitlePatterns) {
                    if ($window.MainWindowTitle -like "*$pattern*") {
                        $result.EULAAppeared = $true
                        $result.Notes = "EULA window detected: $($window.MainWindowTitle)"
                        Write-Host "EULA APPEARED! Window: $($window.MainWindowTitle)" -ForegroundColor Red
                        break
                    }
                }
                if ($result.EULAAppeared) { break }
            }
        }
        
        # Kill the process if still running
        if (-not $process.HasExited) {
            $process.Kill()
            Start-Sleep -Seconds 1
        }
        
        $result.ProcessExitCode = $process.ExitCode
        
    } catch {
        $result.ErrorMessage = $_.Exception.Message
        Write-Host "ERROR: $_" -ForegroundColor Red
    }
    
    $result.EndTime = Get-Date
    $result.Duration = ($result.EndTime - $result.StartTime).TotalSeconds
    
    # Display result
    if ($result.EULAAppeared) {
        Write-Host "Result: EULA APPEARED - Parameters did NOT bypass EULA" -ForegroundColor Red
    } else {
        Write-Host "Result: No EULA detected (may need manual verification)" -ForegroundColor Green
    }
    
    return $result
}

# Function to test execution contexts
function Test-ExecutionContext {
    Write-Host "`n`n=== TESTING EXECUTION CONTEXTS ===" -ForegroundColor Yellow
    
    $contexts = @(
        @{Name="Direct PowerShell"; Method="Direct"},
        @{Name="CMD Shell"; Method="CMD"},
        @{Name="Start-Process Hidden"; Method="Hidden"},
        @{Name="Scheduled Task SYSTEM"; Method="System"}
    )
    
    foreach ($context in $contexts) {
        Write-Host "`nTesting in context: $($context.Name)" -ForegroundColor Magenta
        
        switch ($context.Method) {
            "Direct" {
                # Already tested above
            }
            "CMD" {
                $cmdLine = "cmd /c `"$AssistantPath`" /SkipEULA /QuietInstall /Auto Upgrade"
                Write-Host "CMD: $cmdLine" -ForegroundColor Gray
                $result = Invoke-Expression $cmdLine 2>&1
            }
            "Hidden" {
                Start-Process -FilePath $AssistantPath `
                    -ArgumentList "/SkipEULA", "/QuietInstall", "/Auto", "Upgrade" `
                    -WindowStyle Hidden `
                    -Wait
            }
            "System" {
                Write-Host "Creating scheduled task for SYSTEM context..." -ForegroundColor Gray
                # This would create and run a scheduled task as SYSTEM
                # Implementation depends on specific requirements
            }
        }
    }
}

# Main testing flow
Write-Host "=== Windows 11 Installation Assistant EULA Bypass Testing ===" -ForegroundColor Green
Write-Host "Testing $($testCases.Count) parameter combinations..." -ForegroundColor Green
Write-Host "Assistant Path: $AssistantPath" -ForegroundColor Gray
Write-Host "Results will be saved to: $LogPath" -ForegroundColor Gray

if (-not $AutomatedTesting) {
    Write-Host "`nWARNING: This will launch the Installation Assistant multiple times!" -ForegroundColor Yellow
    Write-Host "Each test will run for up to 10 seconds to detect EULA appearance." -ForegroundColor Yellow
    $confirm = Read-Host "Continue? (Y/N)"
    if ($confirm -ne 'Y') { exit }
}

# Run all test cases
foreach ($test in $testCases) {
    $result = Test-ParameterCombination -TestName $test.Name -Parameters $test.Params
    $testResults += $result
    
    # Brief pause between tests
    Start-Sleep -Seconds 2
}

# Test execution contexts
Test-ExecutionContext

# Generate summary report
Write-Host "`n`n=== TESTING COMPLETE ===" -ForegroundColor Green
Write-Host "Total tests run: $($testResults.Count)" -ForegroundColor Cyan

$successfulTests = $testResults | Where-Object { -not $_.EULAAppeared }
$failedTests = $testResults | Where-Object { $_.EULAAppeared }

Write-Host "`nTests where EULA did NOT appear: $($successfulTests.Count)" -ForegroundColor Green
if ($successfulTests.Count -gt 0) {
    Write-Host "Potential EULA bypass parameters found:" -ForegroundColor Green
    foreach ($success in $successfulTests) {
        Write-Host "  - $($success.TestName): $($success.Parameters)" -ForegroundColor Green
    }
}

Write-Host "`nTests where EULA appeared: $($failedTests.Count)" -ForegroundColor Red

# Export results to CSV
$testResults | Select-Object TestName, Parameters, EULAAppeared, ProcessExitCode, Duration, Notes, ErrorMessage |
    Export-Csv -Path $LogPath -NoTypeInformation

Write-Host "`nDetailed results saved to: $LogPath" -ForegroundColor Cyan

# Additional recommendations
Write-Host "`n=== RECOMMENDATIONS ===" -ForegroundColor Yellow
Write-Host "1. For any 'successful' tests, manually verify the installer behavior" -ForegroundColor White
Write-Host "2. Test successful combinations with full upgrade process" -ForegroundColor White
Write-Host "3. Monitor with Process Monitor for registry/file access patterns" -ForegroundColor White
Write-Host "4. Consider testing with different Windows 10 versions" -ForegroundColor White
Write-Host "5. Check Event Viewer for any relevant logs" -ForegroundColor White

# Create process monitor filter file
$procmonFilter = @"
<ProcessMonitorFilter>
    <FilterRules>
        <FilterRule>
            <Column>Process Name</Column>
            <Relation>is</Relation>
            <Value>Windows11InstallationAssistant.exe</Value>
            <Action>Include</Action>
        </FilterRule>
        <FilterRule>
            <Column>Path</Column>
            <Relation>contains</Relation>
            <Value>EULA</Value>
            <Action>Include</Action>
        </FilterRule>
        <FilterRule>
            <Column>Path</Column>
            <Relation>contains</Relation>
            <Value>License</Value>
            <Action>Include</Action>
        </FilterRule>
    </FilterRules>
</ProcessMonitorFilter>
"@

$procmonFilter | Out-File -FilePath ".\ProcMon_EULA_Filter.pmc" -Encoding UTF8
Write-Host "`nProcess Monitor filter created: .\ProcMon_EULA_Filter.pmc" -ForegroundColor Cyan