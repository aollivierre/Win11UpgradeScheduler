#region Module Header
<#
.SYNOPSIS
    Early OS Compatibility Check Module for Windows 11 Upgrade
.DESCRIPTION
    Performs early OS detection and compatibility validation:
    - Blocks Windows 11 systems (with developer mode bypass)
    - Allows Windows 10 systems to proceed
    - Blocks legacy OS (Windows 7/8/8.1) completely
    
    This check runs before any UI is shown to provide immediate feedback.
    
.NOTES
    Version:        1.0.0
    Created:        2025-01-18
#>
#endregion

#region Module Variables
$script:LogPath = "$env:ProgramData\Win11UpgradeScheduler\Logs"
$script:MinimumWindowsBuild = 10240  # Windows 10 1507 (minimum)
$script:Windows11Build = 22000       # Windows 11 (any version)
#endregion

#region Logging Function
function Write-OSCheckLog {
    <#
    .SYNOPSIS
        Writes a log entry for OS compatibility checks
    .DESCRIPTION
        Creates timestamped log entries for OS check operations
    .PARAMETER Message
        The message to log
    .PARAMETER Severity
        Log severity level
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet('Information','Warning','Error')]
        [string]$Severity = 'Information'
    )
    
    if (-not (Test-Path -Path $script:LogPath)) {
        New-Item -Path $script:LogPath -ItemType Directory -Force | Out-Null
    }
    
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logFile = Join-Path -Path $script:LogPath -ChildPath "OSCompatibilityCheck_$(Get-Date -Format 'yyyyMMdd').log"
    $logEntry = "[$timestamp] [$Severity] $Message"
    
    Add-Content -Path $logFile -Value $logEntry -Force
}
#endregion

#region OS Detection Functions
function Get-OSDetails {
    <#
    .SYNOPSIS
        Gets detailed OS information
    .DESCRIPTION
        Retrieves OS name, version, build number and classification
    .EXAMPLE
        Get-OSDetails
    #>
    [CmdletBinding()]
    param()
    
    Write-OSCheckLog -Message "Retrieving OS details"
    
    try {
        $os = Get-CimInstance -ClassName Win32_OperatingSystem
        $buildNumber = [int]$os.BuildNumber
        
        # Get version info from registry
        $regPath = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
        $displayVersion = (Get-ItemProperty -Path $regPath -Name DisplayVersion -ErrorAction SilentlyContinue).DisplayVersion
        if ($null -eq $displayVersion) {
            $displayVersion = (Get-ItemProperty -Path $regPath -Name ReleaseId -ErrorAction SilentlyContinue).ReleaseId
        }
        
        $productName = (Get-ItemProperty -Path $regPath -Name ProductName -ErrorAction SilentlyContinue).ProductName
        
        # Determine OS type
        $osType = 'Unknown'
        if ($buildNumber -ge $script:Windows11Build) {
            $osType = 'Windows11'
        }
        elseif ($buildNumber -ge $script:MinimumWindowsBuild) {
            $osType = 'Windows10'
        }
        elseif ($buildNumber -ge 9600) {
            $osType = 'Windows8.1'
        }
        elseif ($buildNumber -ge 9200) {
            $osType = 'Windows8'
        }
        elseif ($buildNumber -ge 7600) {
            $osType = 'Windows7'
        }
        else {
            $osType = 'Legacy'
        }
        
        $result = @{
            ProductName = $productName
            DisplayVersion = $displayVersion
            BuildNumber = $buildNumber
            OSType = $osType
            Caption = $os.Caption
            Version = $os.Version
        }
        
        Write-OSCheckLog -Message "OS Details: $productName, Version: $displayVersion, Build: $buildNumber, Type: $osType"
        
        return $result
    }
    catch {
        Write-OSCheckLog -Message "Error retrieving OS details: $_" -Severity Error
        throw
    }
}

function Test-OSCompatibility {
    <#
    .SYNOPSIS
        Tests if OS is compatible for Windows 11 upgrade
    .DESCRIPTION
        Validates OS compatibility based on type and version.
        Returns detailed compatibility status and recommended actions.
    .PARAMETER DeveloperMode
        Bypass Windows 11 check for testing purposes
    .EXAMPLE
        Test-OSCompatibility
        Test-OSCompatibility -DeveloperMode
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [switch]$DeveloperMode
    )
    
    Write-OSCheckLog -Message "Starting OS compatibility check (Developer Mode: $DeveloperMode)"
    
    $osDetails = Get-OSDetails
    
    $result = @{
        IsCompatible = $false
        RequiresUserPrompt = $false
        BlockCompletely = $false
        Message = ""
        OSDetails = $osDetails
        Action = 'Block'
    }
    
    switch ($osDetails.OSType) {
        'Windows11' {
            Write-OSCheckLog -Message "Windows 11 detected - upgrade not needed" -Severity Warning
            $result.Message = "Your system is already running Windows 11 ($($osDetails.DisplayVersion), Build $($osDetails.BuildNumber)). No upgrade is needed."
            
            if ($DeveloperMode) {
                Write-OSCheckLog -Message "Developer mode enabled - allowing Windows 11 bypass" -Severity Warning
                $result.IsCompatible = $true
                $result.RequiresUserPrompt = $true
                $result.Action = 'PromptDeveloper'
                $result.Message += "`n`nDEVELOPER MODE: You can proceed with the upgrade for testing purposes."
            }
            else {
                $result.BlockCompletely = $true
                $result.Action = 'BlockWindows11'
            }
        }
        
        'Windows10' {
            Write-OSCheckLog -Message "Windows 10 detected - compatible for upgrade"
            $result.IsCompatible = $true
            $result.RequiresUserPrompt = $false
            $result.Action = 'Allow'
            $result.Message = "Windows 10 detected. System is eligible for Windows 11 upgrade."
        }
        
        {$_ -in 'Windows8.1', 'Windows8', 'Windows7', 'Legacy'} {
            Write-OSCheckLog -Message "Legacy OS detected ($($osDetails.OSType)) - not compatible" -Severity Error
            $result.BlockCompletely = $true
            $result.Action = 'BlockLegacy'
            $result.Message = "Your system is running $($osDetails.ProductName) (Build $($osDetails.BuildNumber)). This tool only supports upgrading from Windows 10 to Windows 11. Please upgrade to Windows 10 first."
        }
        
        default {
            Write-OSCheckLog -Message "Unknown OS detected - blocking upgrade" -Severity Error
            $result.BlockCompletely = $true
            $result.Action = 'BlockUnknown'
            $result.Message = "Unable to determine Windows version. This tool only supports upgrading from Windows 10 to Windows 11."
        }
    }
    
    Write-OSCheckLog -Message "Compatibility check result: Action=$($result.Action), Compatible=$($result.IsCompatible)"
    
    return $result
}

function Show-OSCompatibilityPrompt {
    <#
    .SYNOPSIS
        Shows OS compatibility prompt using PSADT
    .DESCRIPTION
        Displays appropriate message based on OS compatibility check
    .PARAMETER CompatibilityResult
        Result from Test-OSCompatibility
    .PARAMETER AppDeployToolkitMain
        Reference to PSADT main module for UI functions
    .EXAMPLE
        Show-OSCompatibilityPrompt -CompatibilityResult $result
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$CompatibilityResult,
        
        [Parameter(Mandatory=$false)]
        [scriptblock]$ShowInstallationPrompt,
        
        [Parameter(Mandatory=$false)]
        [scriptblock]$ShowInstallationWelcome
    )
    
    Write-OSCheckLog -Message "Showing OS compatibility prompt for action: $($CompatibilityResult.Action)"
    
    switch ($CompatibilityResult.Action) {
        'BlockWindows11' {
            # Windows 11 already installed - block completely
            if ($ShowInstallationPrompt) {
                & $ShowInstallationPrompt -Message $CompatibilityResult.Message `
                    -ButtonRightText 'OK' `
                    -Icon Information `
                    -NoWait
            }
            return $false
        }
        
        'PromptDeveloper' {
            # Developer mode - prompt to continue
            if ($ShowInstallationPrompt) {
                $response = & $ShowInstallationPrompt -Message $CompatibilityResult.Message `
                    -ButtonRightText 'Continue (Dev)' `
                    -ButtonLeftText 'Cancel' `
                    -Icon Warning
                
                return ($response -eq 'Continue (Dev)')
            }
            return $true
        }
        
        {$_ -in 'BlockLegacy', 'BlockUnknown'} {
            # Legacy OS - block completely
            if ($ShowInstallationPrompt) {
                & $ShowInstallationPrompt -Message $CompatibilityResult.Message `
                    -ButtonRightText 'OK' `
                    -Icon Error `
                    -NoWait
            }
            return $false
        }
        
        'Allow' {
            # Windows 10 - proceed normally
            Write-OSCheckLog -Message "Windows 10 detected - proceeding with normal flow"
            return $true
        }
        
        default {
            Write-OSCheckLog -Message "Unknown action - blocking by default" -Severity Warning
            return $false
        }
    }
}

function Invoke-EarlyOSCheck {
    <#
    .SYNOPSIS
        Main function to perform early OS compatibility check
    .DESCRIPTION
        Performs OS check and shows appropriate prompts.
        Returns $true if upgrade should proceed, $false otherwise.
    .PARAMETER DeveloperMode
        Enable developer mode bypass
    .PARAMETER ShowInstallationPrompt
        PSADT prompt function reference
    .EXAMPLE
        Invoke-EarlyOSCheck -DeveloperMode:$false
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [switch]$DeveloperMode,
        
        [Parameter(Mandatory=$false)]
        [scriptblock]$ShowInstallationPrompt
    )
    
    Write-OSCheckLog -Message ("=" * 60)
    Write-OSCheckLog -Message "Starting early OS compatibility check"
    
    try {
        # Run compatibility check
        $compatibilityResult = Test-OSCompatibility -DeveloperMode:$DeveloperMode
        
        # Show prompt if needed
        if ($compatibilityResult.RequiresUserPrompt -or $compatibilityResult.BlockCompletely) {
            $shouldProceed = Show-OSCompatibilityPrompt -CompatibilityResult $compatibilityResult -ShowInstallationPrompt $ShowInstallationPrompt
            
            Write-OSCheckLog -Message "User prompt result: $shouldProceed"
            Write-OSCheckLog -Message ("=" * 60)
            
            return $shouldProceed
        }
        
        # Windows 10 - proceed without prompt
        Write-OSCheckLog -Message "OS check passed - proceeding with upgrade"
        Write-OSCheckLog -Message ("=" * 60)
        
        return $true
    }
    catch {
        Write-OSCheckLog -Message "Error during OS check: $_" -Severity Error
        Write-OSCheckLog -Message ("=" * 60)
        
        # On error, block by default
        return $false
    }
}
#endregion

#region Module Export
Export-ModuleMember -Function @(
    'Invoke-EarlyOSCheck'
    'Test-OSCompatibility'
    'Get-OSDetails'
    'Show-OSCompatibilityPrompt'
    'Write-OSCheckLog'
)
#endregion