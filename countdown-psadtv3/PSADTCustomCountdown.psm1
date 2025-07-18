<#
.SYNOPSIS
    PSADT Custom Countdown Module
.DESCRIPTION
    Extends PSADT v3 with a pure visual countdown timer that performs no actions.
    Drop-in replacement for scenarios where you need countdown without closing apps or restarting.
.VERSION
    1.0.0
.COMPATIBILITY
    PSADT v3.x
#>

#region Module Functions

function Show-CustomCountdownDialog {
    <#
    .SYNOPSIS
        Displays a visual countdown timer without performing any actions when complete.
    .DESCRIPTION
        Drop-in replacement for PSADT countdown functions when you need visual feedback without actions.
        Integrates with PSADT logging and styling when available.
    .PARAMETER CountdownSeconds
        Number of seconds to count down from (default: 60)
    .PARAMETER Message
        Message to display above the countdown
    .PARAMETER Title
        Window title (default: uses $appName if available)
    .PARAMETER NoAutoClose
        If specified, window stays open after countdown completes
    .EXAMPLE
        Show-CustomCountdownDialog -CountdownSeconds 300 -Message "Please save your work"
    .EXAMPLE
        # Replace PSADT restart countdown with non-action countdown
        # Instead of: Show-InstallationRestartPrompt -CountdownSeconds 300
        Show-CustomCountdownDialog -CountdownSeconds 300 -Message "System maintenance in progress..."
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [ValidateRange(1,86400)]
        [int]$CountdownSeconds = 60,
        
        [Parameter(Mandatory=$false)]
        [string]$Message = "This process will continue automatically when the countdown completes.",
        
        [Parameter(Mandatory=$false)]
        [string]$Title = $null,
        
        [Parameter(Mandatory=$false)]
        [switch]$NoAutoClose
    )
    
    # Load required assemblies
    Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
    Add-Type -AssemblyName System.Drawing -ErrorAction Stop
    
    # Enable visual styles
    [Windows.Forms.Application]::EnableVisualStyles()
    
    # Set title (use PSADT $appName if available)
    if (-not $Title) {
        if (Get-Variable -Name appName -Scope Script -ErrorAction SilentlyContinue) {
            $Title = $script:appName
        } else {
            $Title = "Countdown Timer"
        }
    }
    
    # Create form
    $form = New-Object System.Windows.Forms.Form
    $form.Text = $Title
    $form.Size = New-Object System.Drawing.Size(450, 220)
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = "FixedDialog"
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false
    $form.TopMost = $true
    
    # Try to use PSADT icon if available
    try {
        if (Get-Variable -Name scriptDirectory -Scope Script -ErrorAction SilentlyContinue) {
            $iconPath = Join-Path -Path $script:scriptDirectory -ChildPath "AppDeployToolkit\AppDeployToolkitLogo.ico"
            if (Test-Path $iconPath) {
                $form.Icon = [System.Drawing.Icon]::new($iconPath)
            }
        }
    } catch {
        # Continue without icon
    }
    
    # Message label
    $labelMessage = New-Object System.Windows.Forms.Label
    $labelMessage.Location = New-Object System.Drawing.Point(20, 20)
    $labelMessage.Size = New-Object System.Drawing.Size(410, 50)
    $labelMessage.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $labelMessage.TextAlign = "MiddleCenter"
    $labelMessage.Text = $Message
    
    # Countdown label
    $labelCountdown = New-Object System.Windows.Forms.Label
    $labelCountdown.Location = New-Object System.Drawing.Point(20, 75)
    $labelCountdown.Size = New-Object System.Drawing.Size(410, 50)
    $labelCountdown.Font = New-Object System.Drawing.Font("Segoe UI", 26, [System.Drawing.FontStyle]::Bold)
    $labelCountdown.TextAlign = "MiddleCenter"
    $labelCountdown.Text = "00:00:00"
    $labelCountdown.ForeColor = [System.Drawing.Color]::DarkBlue
    
    # Status label
    $labelStatus = New-Object System.Windows.Forms.Label
    $labelStatus.Location = New-Object System.Drawing.Point(20, 130)
    $labelStatus.Size = New-Object System.Drawing.Size(410, 20)
    $labelStatus.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $labelStatus.TextAlign = "MiddleCenter"
    $labelStatus.Text = "Time remaining..."
    $labelStatus.ForeColor = [System.Drawing.Color]::DimGray
    
    # Close button
    $buttonClose = New-Object System.Windows.Forms.Button
    $buttonClose.Location = New-Object System.Drawing.Point(175, 155)
    $buttonClose.Size = New-Object System.Drawing.Size(100, 28)
    $buttonClose.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $buttonClose.Text = "&Close"
    $buttonClose.Enabled = $false
    $buttonClose.DialogResult = [System.Windows.Forms.DialogResult]::OK
    
    # Add controls
    $form.Controls.AddRange(@($labelMessage, $labelCountdown, $labelStatus, $buttonClose))
    $form.AcceptButton = $buttonClose
    
    # Timer setup (PSADT-style implementation)
    $timer = New-Object System.Windows.Forms.Timer
    $startTime = Get-Date
    $countdownTime = $startTime.AddSeconds($CountdownSeconds)
    $countdownComplete = $false
    
    # Timer tick event
    $timer.Add_Tick({
        $currentTime = Get-Date
        $remainingTime = $countdownTime.Subtract($currentTime)
        
        if ($countdownTime -le $currentTime -and -not $countdownComplete) {
            # Countdown complete
            $timer.Stop()
            $countdownComplete = $true
            
            # Update display
            $labelCountdown.Text = "00:00:00"
            $labelCountdown.ForeColor = [System.Drawing.Color]::Green
            $labelStatus.Text = "Countdown complete"
            $labelStatus.ForeColor = [System.Drawing.Color]::Green
            $buttonClose.Enabled = $true
            $buttonClose.Select()
            
            # Log if PSADT logging is available
            if (Get-Command Write-Log -ErrorAction SilentlyContinue) {
                Write-Log -Message "Custom countdown dialog completed after $CountdownSeconds seconds" -Source ${CmdletName}
            }
            
            # Auto-close if requested
            if (-not $NoAutoClose) {
                Start-Sleep -Seconds 2
                $form.DialogResult = [System.Windows.Forms.DialogResult]::OK
                $form.Close()
            }
        }
        elseif (-not $countdownComplete) {
            # Update countdown display
            $totalHours = $remainingTime.Days * 24 + $remainingTime.Hours
            $labelCountdown.Text = "{0:d2}:{1:d2}:{2:d2}" -f $totalHours, $remainingTime.Minutes, $remainingTime.Seconds
            
            # Color coding
            if ($remainingTime.TotalSeconds -le 10) {
                $labelCountdown.ForeColor = [System.Drawing.Color]::Red
                $labelStatus.Text = "Almost complete..."
            }
            elseif ($remainingTime.TotalSeconds -le 30) {
                $labelCountdown.ForeColor = [System.Drawing.Color]::DarkOrange
            }
        }
    })
    
    # Form load event
    $form.Add_Load({
        # Initialize display
        $remainingTime = $countdownTime.Subtract($startTime)
        $totalHours = $remainingTime.Days * 24 + $remainingTime.Hours
        $labelCountdown.Text = "{0:d2}:{1:d2}:{2:d2}" -f $totalHours, $remainingTime.Minutes, $remainingTime.Seconds
        
        # Start timer
        $timer.Start()
        
        # Log if PSADT logging is available
        if (Get-Command Write-Log -ErrorAction SilentlyContinue) {
            Write-Log -Message "Custom countdown dialog started with $CountdownSeconds seconds" -Source ${CmdletName}
        }
    })
    
    # Form closing event
    $form.Add_FormClosing({
        $timer.Stop()
        $timer.Dispose()
    })
    
    # Show dialog
    $result = $form.ShowDialog()
    
    # Cleanup
    $form.Dispose()
    
    return $result
}

function Show-InstallationCountdown {
    <#
    .SYNOPSIS
        Alias for Show-CustomCountdownDialog with PSADT-like naming
    .DESCRIPTION
        Provides a PSADT-style function name for the custom countdown dialog
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [ValidateRange(1,86400)]
        [int]$CountdownSeconds = 60,
        
        [Parameter(Mandatory=$false)]
        [string]$Message = "This process will continue automatically when the countdown completes.",
        
        [Parameter(Mandatory=$false)]
        [string]$Title = $null,
        
        [Parameter(Mandatory=$false)]
        [switch]$NoAutoClose
    )
    
    Show-CustomCountdownDialog @PSBoundParameters
}

#endregion

#region Module Export

# Export functions
Export-ModuleMember -Function @(
    'Show-CustomCountdownDialog',
    'Show-InstallationCountdown'
)

#endregion