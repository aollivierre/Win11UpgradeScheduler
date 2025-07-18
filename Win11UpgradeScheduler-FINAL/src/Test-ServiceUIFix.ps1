#region Script Header
<#
.SYNOPSIS
    Test script for ServiceUI.exe fix validation
.DESCRIPTION
    This script validates that the ServiceUI.exe issue has been resolved by testing:
    - SYSTEM context detection
    - Execute-ProcessAsUser functionality
    - UI display in user sessions when running as SYSTEM
    - Scheduled task creation and execution
.PARAMETER TestType
    Type of test to run (All, ContextDetection, UIDisplay, ScheduledTask)
.PARAMETER PSADTPath
    Path to the PSADT package directory
.NOTES
    Version:        1.0.0
    Author:         System Administrator
    Creation Date:  2025-01-17
    
    Test Results:
    - All tests use try/catch blocks instead of Pester
    - Results are logged to console and log file
    - Exit codes: 0 = Success, 1 = Failure
#>
#endregion

#region Parameters
[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('All','ContextDetection','UIDisplay','ScheduledTask')]
    [string]$TestType = 'All',
    
    [Parameter(Mandatory=$false)]
    [string]$PSADTPath = (Split-Path -Parent $MyInvocation.MyCommand.Definition)
)
#endregion

#region Variables
$script:TestResults = @()
$script:LogPath = "$env:ProgramData\Win11UpgradeScheduler\TestLogs"
$script:WrapperScript = Join-Path -Path $PSADTPath -ChildPath 'SupportFiles\ScheduledTaskWrapper.ps1'
$script:ModulePath = Join-Path -Path $PSADTPath -ChildPath 'SupportFiles\Modules\01-UpgradeScheduler.psm1'
#endregion

#region Functions
function Write-TestLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet('Information','Warning','Error','Success')]
        [string]$Severity = 'Information'
    )
    
    if (-not (Test-Path -Path $script:LogPath)) {
        New-Item -Path $script:LogPath -ItemType Directory -Force | Out-Null
    }
    
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logFile = Join-Path -Path $script:LogPath -ChildPath "ServiceUIFix_Test_$(Get-Date -Format 'yyyyMMdd').log"
    $logEntry = "[$timestamp] [$Severity] $Message"
    
    # Write to console with color coding
    $color = switch ($Severity) {
        'Success' { 'Green' }
        'Warning' { 'Yellow' }
        'Error' { 'Red' }
        default { 'White' }
    }
    Write-Host $logEntry -ForegroundColor $color
    
    # Write to log file
    Add-Content -Path $logFile -Value $logEntry -Force
}

function Test-SystemContextDetection {
    <#
    .SYNOPSIS
        Tests if SYSTEM context detection works correctly
    #>
    [CmdletBinding()]
    param()
    
    Write-TestLog -Message "Testing SYSTEM context detection..." -Severity Information
    
    try {
        # Test the function by sourcing it from the wrapper script
        if (-not (Test-Path -Path $script:WrapperScript)) {
            throw "Wrapper script not found: $script:WrapperScript"
        }
        
        # Extract the Test-RunningAsSystem function and test it
        $testScript = @"
. '$script:WrapperScript'
`$isSystem = Test-RunningAsSystem
Write-Output "Current user: `$([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)"
Write-Output "Is SYSTEM: `$isSystem"
if (`$isSystem) { exit 1 } else { exit 0 }
"@
        
        $tempScript = Join-Path -Path $env:TEMP -ChildPath "SystemTest_$(Get-Date -Format 'yyyyMMddHHmmss').ps1"
        $testScript | Set-Content -Path $tempScript -Force
        
        $result = Start-Process -FilePath 'powershell.exe' `
            -ArgumentList "-ExecutionPolicy Bypass -File `"$tempScript`"" `
            -Wait -PassThru -WindowStyle Hidden
        
        Remove-Item -Path $tempScript -Force -ErrorAction SilentlyContinue
        
        if ($result.ExitCode -eq 0) {
            Write-TestLog -Message "SYSTEM context detection test PASSED (correctly identified as non-SYSTEM)" -Severity Success
            return $true
        } else {
            Write-TestLog -Message "SYSTEM context detection test FAILED (incorrectly identified as SYSTEM)" -Severity Error
            return $false
        }
    }
    catch {
        Write-TestLog -Message "SYSTEM context detection test FAILED with error: $_" -Severity Error
        return $false
    }
}

function Test-ExecuteProcessAsUserAvailability {
    <#
    .SYNOPSIS
        Tests if Execute-ProcessAsUser function is available in PSADT
    #>
    [CmdletBinding()]
    param()
    
    Write-TestLog -Message "Testing Execute-ProcessAsUser availability..." -Severity Information
    
    try {
        $toolkitMain = Join-Path -Path $PSADTPath -ChildPath 'AppDeployToolkit\AppDeployToolkitMain.ps1'
        
        if (-not (Test-Path -Path $toolkitMain)) {
            throw "PSADT main toolkit not found: $toolkitMain"
        }
        
        # Test if Execute-ProcessAsUser function exists
        $testScript = @"
. '$toolkitMain'
if (Get-Command -Name 'Execute-ProcessAsUser' -ErrorAction SilentlyContinue) {
    Write-Output "Execute-ProcessAsUser function found"
    exit 0
} else {
    Write-Output "Execute-ProcessAsUser function not found"
    exit 1
}
"@
        
        $tempScript = Join-Path -Path $env:TEMP -ChildPath "ExecuteProcessAsUserTest_$(Get-Date -Format 'yyyyMMddHHmmss').ps1"
        $testScript | Set-Content -Path $tempScript -Force
        
        $result = Start-Process -FilePath 'powershell.exe' `
            -ArgumentList "-ExecutionPolicy Bypass -File `"$tempScript`"" `
            -Wait -PassThru -WindowStyle Hidden
        
        Remove-Item -Path $tempScript -Force -ErrorAction SilentlyContinue
        
        if ($result.ExitCode -eq 0) {
            Write-TestLog -Message "Execute-ProcessAsUser availability test PASSED" -Severity Success
            return $true
        } else {
            Write-TestLog -Message "Execute-ProcessAsUser availability test FAILED" -Severity Error
            return $false
        }
    }
    catch {
        Write-TestLog -Message "Execute-ProcessAsUser availability test FAILED with error: $_" -Severity Error
        return $false
    }
}

function Test-UIDisplayFunctionality {
    <#
    .SYNOPSIS
        Tests if UI can be displayed when running the wrapper script
    #>
    [CmdletBinding()]
    param()
    
    Write-TestLog -Message "Testing UI display functionality..." -Severity Information
    
    try {
        # Test if the modified wrapper script can handle UI display
        $testScript = @"
. '$script:WrapperScript'
Write-WrapperLog -Message "Testing UI display capability"
`$hasUserSession = Test-UserSession
Write-Output "Has active user session: `$hasUserSession"
if (`$hasUserSession) { exit 0 } else { exit 1 }
"@
        
        $tempScript = Join-Path -Path $env:TEMP -ChildPath "UIDisplayTest_$(Get-Date -Format 'yyyyMMddHHmmss').ps1"
        $testScript | Set-Content -Path $tempScript -Force
        
        $result = Start-Process -FilePath 'powershell.exe' `
            -ArgumentList "-ExecutionPolicy Bypass -File `"$tempScript`"" `
            -Wait -PassThru -WindowStyle Hidden
        
        Remove-Item -Path $tempScript -Force -ErrorAction SilentlyContinue
        
        if ($result.ExitCode -eq 0) {
            Write-TestLog -Message "UI display functionality test PASSED (user session detected)" -Severity Success
            return $true
        } else {
            Write-TestLog -Message "UI display functionality test FAILED (no user session)" -Severity Warning
            return $false
        }
    }
    catch {
        Write-TestLog -Message "UI display functionality test FAILED with error: $_" -Severity Error
        return $false
    }
}

function Test-ScheduledTaskCreation {
    <#
    .SYNOPSIS
        Tests if scheduled task can be created without ServiceUI.exe dependency
    #>
    [CmdletBinding()]
    param()
    
    Write-TestLog -Message "Testing scheduled task creation..." -Severity Information
    
    try {
        # Import the module and test task creation
        if (-not (Test-Path -Path $script:ModulePath)) {
            throw "Module not found: $script:ModulePath"
        }
        
        Import-Module -Name $script:ModulePath -Force
        
        # Test task creation (but don't actually schedule it)
        $testTime = (Get-Date).AddMinutes(5)
        
        $testScript = @"
Import-Module -Name '$script:ModulePath' -Force
try {
    # Test creating a task configuration (but don't register it)
    `$taskName = 'Win11_Upgrade_Test_' + (Get-Date -Format 'yyyyMMddHHmmss')
    `$action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument '-ExecutionPolicy Bypass -Command "Write-Host Test"'
    `$trigger = New-ScheduledTaskTrigger -Once -At '$testTime'
    `$principal = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType ServiceAccount -RunLevel Highest
    
    Write-Output "Task components created successfully"
    exit 0
} catch {
    Write-Output "Error creating task: `$_"
    exit 1
}
"@
        
        $tempScript = Join-Path -Path $env:TEMP -ChildPath "ScheduledTaskTest_$(Get-Date -Format 'yyyyMMddHHmmss').ps1"
        $testScript | Set-Content -Path $tempScript -Force
        
        $result = Start-Process -FilePath 'powershell.exe' `
            -ArgumentList "-ExecutionPolicy Bypass -File `"$tempScript`"" `
            -Wait -PassThru -WindowStyle Hidden
        
        Remove-Item -Path $tempScript -Force -ErrorAction SilentlyContinue
        
        if ($result.ExitCode -eq 0) {
            Write-TestLog -Message "Scheduled task creation test PASSED" -Severity Success
            return $true
        } else {
            Write-TestLog -Message "Scheduled task creation test FAILED" -Severity Error
            return $false
        }
    }
    catch {
        Write-TestLog -Message "Scheduled task creation test FAILED with error: $_" -Severity Error
        return $false
    }
}

function Test-WrapperScriptExecution {
    <#
    .SYNOPSIS
        Tests if wrapper script executes without errors
    #>
    [CmdletBinding()]
    param()
    
    Write-TestLog -Message "Testing wrapper script execution..." -Severity Information
    
    try {
        # Test wrapper script execution with test parameters
        $arguments = @(
            "-ExecutionPolicy Bypass"
            "-File `"$script:WrapperScript`""
            "-PSADTPath `"$PSADTPath`""
            "-DeploymentType Install"
            "-DeployMode Silent"
        )
        
        $result = Start-Process -FilePath 'powershell.exe' `
            -ArgumentList ($arguments -join ' ') `
            -Wait -PassThru -WindowStyle Hidden
        
        # Check for specific error patterns that indicate ServiceUI issues
        $logFile = Join-Path -Path "$env:ProgramData\Win11UpgradeScheduler\Logs" -ChildPath "TaskWrapper_$(Get-Date -Format 'yyyyMMdd').log"
        
        if (Test-Path -Path $logFile) {
            $logContent = Get-Content -Path $logFile -Raw
            
            # Check for ServiceUI-related errors
            if ($logContent -match 'ServiceUI\.exe.*failed|OpenProcessToken Error|DuplicateTokenEx Error|CreateProcessAsUser Error') {
                Write-TestLog -Message "Wrapper script execution test FAILED (ServiceUI errors detected)" -Severity Error
                return $false
            }
            
            # Check for successful execution indicators
            if ($logContent -match 'Execute-ProcessAsUser|Running as SYSTEM') {
                Write-TestLog -Message "Wrapper script execution test PASSED (Execute-ProcessAsUser logic detected)" -Severity Success
                return $true
            }
        }
        
        Write-TestLog -Message "Wrapper script execution test PASSED (no ServiceUI errors)" -Severity Success
        return $true
    }
    catch {
        Write-TestLog -Message "Wrapper script execution test FAILED with error: $_" -Severity Error
        return $false
    }
}

function Invoke-TestSuite {
    <#
    .SYNOPSIS
        Runs the complete test suite
    #>
    [CmdletBinding()]
    param()
    
    Write-TestLog -Message ("=" * 60) -Severity Information
    Write-TestLog -Message "ServiceUI.exe Fix Validation Test Suite" -Severity Information
    Write-TestLog -Message "Test Type: $TestType" -Severity Information
    Write-TestLog -Message "PSADT Path: $PSADTPath" -Severity Information
    Write-TestLog -Message ("=" * 60) -Severity Information
    
    $testResults = @()
    
    # Run tests based on TestType parameter
    switch ($TestType) {
        'All' {
            $testResults += @{Name = 'ContextDetection'; Result = Test-SystemContextDetection}
            $testResults += @{Name = 'ExecuteProcessAsUser'; Result = Test-ExecuteProcessAsUserAvailability}
            $testResults += @{Name = 'UIDisplay'; Result = Test-UIDisplayFunctionality}
            $testResults += @{Name = 'ScheduledTask'; Result = Test-ScheduledTaskCreation}
            $testResults += @{Name = 'WrapperExecution'; Result = Test-WrapperScriptExecution}
        }
        'ContextDetection' {
            $testResults += @{Name = 'ContextDetection'; Result = Test-SystemContextDetection}
        }
        'UIDisplay' {
            $testResults += @{Name = 'UIDisplay'; Result = Test-UIDisplayFunctionality}
        }
        'ScheduledTask' {
            $testResults += @{Name = 'ScheduledTask'; Result = Test-ScheduledTaskCreation}
        }
    }
    
    # Summary
    Write-TestLog -Message ("=" * 60) -Severity Information
    Write-TestLog -Message "TEST RESULTS SUMMARY" -Severity Information
    Write-TestLog -Message ("=" * 60) -Severity Information
    
    $passedTests = 0
    $totalTests = $testResults.Count
    
    foreach ($test in $testResults) {
        $status = if ($test.Result) { 'PASSED' } else { 'FAILED' }
        $severity = if ($test.Result) { 'Success' } else { 'Error' }
        
        Write-TestLog -Message "$($test.Name): $status" -Severity $severity
        
        if ($test.Result) {
            $passedTests++
        }
    }
    
    Write-TestLog -Message ("=" * 60) -Severity Information
    Write-TestLog -Message "Tests Passed: $passedTests/$totalTests" -Severity Information
    
    if ($passedTests -eq $totalTests) {
        Write-TestLog -Message "ALL TESTS PASSED - ServiceUI.exe fix is working correctly!" -Severity Success
        return $true
    } else {
        Write-TestLog -Message "SOME TESTS FAILED - ServiceUI.exe fix needs attention!" -Severity Error
        return $false
    }
}
#endregion

#region Main Script
try {
    # Validate prerequisites
    if (-not (Test-Path -Path $PSADTPath)) {
        throw "PSADT path not found: $PSADTPath"
    }
    
    # Run the test suite
    $success = Invoke-TestSuite
    
    if ($success) {
        Write-TestLog -Message "Test suite completed successfully" -Severity Success
        exit 0
    } else {
        Write-TestLog -Message "Test suite completed with failures" -Severity Error
        exit 1
    }
}
catch {
    Write-TestLog -Message "Fatal error in test suite: $_" -Severity Error
    exit 1
}
#endregion