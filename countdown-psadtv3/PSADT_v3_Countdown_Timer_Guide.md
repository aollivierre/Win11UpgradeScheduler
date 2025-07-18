# PowerShell App Deployment Toolkit (PSADT) v3 - Countdown Timer Implementation Guide

## Overview
This comprehensive guide covers all countdown timer functionality in PSADT v3.10.2, including visual countdown timers, timeout-based dialogs, and safe implementation practices.

## Table of Contents
1. [Quick Start](#quick-start)
2. [Visual Countdown Timers](#visual-countdown-timers)
3. [Timeout-Based Dialogs](#timeout-based-dialogs)
4. [Restart Countdown Timers](#restart-countdown-timers)
5. [Working Examples](#working-examples)
6. [Configuration Options](#configuration-options)
7. [AI Agent Guidelines](#ai-agent-guidelines)
8. [Documentation References](#documentation-references)
9. [Best Practices](#best-practices)
10. [Troubleshooting](#troubleshooting)

---

## Quick Start

### Prerequisites
1. **Download PSADT v3.10.2** from the official repository
2. **Import the toolkit** using the correct path structure
3. **Understand the two countdown types**:
   - **Visual Countdown**: Shows moving timer (60, 59, 58...)
   - **Silent Timeout**: Auto-closes after specified time (no visual counter)

### Basic Implementation Template
```powershell
#region Initialize PSADT
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$psadtPath = Join-Path $scriptPath "PSAppDeployToolkit\Toolkit\AppDeployToolkit"
. "$psadtPath\AppDeployToolkitMain.ps1"
#endregion

#region Your Countdown Timer Code
# Your countdown timer implementation here
#endregion
```

---

## Visual Countdown Timers

### 1. Show-InstallationWelcome with ForceCloseAppsCountdown

**Purpose**: Shows a visual countdown timer before closing specified applications.

**Function**: `Show-InstallationWelcome`

**Key Parameters**:
- `CloseApps`: Applications to close (comma-separated)
- `ForceCloseAppsCountdown`: Countdown duration in seconds
- `BlockExecution`: Prevents apps from restarting during installation

**Example**:
```powershell
Show-InstallationWelcome -CloseApps 'notepad,chrome,excel' -ForceCloseAppsCountdown 60 -BlockExecution
```

**Behavior**:
- Displays welcome dialog with application list
- Shows visual countdown timer (60, 59, 58...)
- Automatically closes specified apps when countdown reaches 0
- **NO RESTART** - safe for testing

### 2. Show-InstallationWelcome with CloseAppsCountdown

**Purpose**: Shows countdown only when deferrals are exhausted or not allowed.

**Function**: `Show-InstallationWelcome`

**Key Parameters**:
- `CloseApps`: Applications to close
- `CloseAppsCountdown`: Countdown duration in seconds
- `AllowDefer`: Enable deferral options
- `DeferTimes`: Number of deferrals allowed

**Example**:
```powershell
Show-InstallationWelcome -CloseApps 'winword,excel' -CloseAppsCountdown 300 -AllowDefer -DeferTimes 3
```

**Behavior**:
- Shows deferral options first
- Countdown only appears when deferrals are exhausted
- Visual countdown timer before closing apps

### 3. Show-InstallationWelcome with ForceCountdown

**Purpose**: Shows countdown on deferral dialogs before proceeding automatically.

**Function**: `Show-InstallationWelcome`

**Key Parameters**:
- `AllowDefer`: Must be enabled
- `DeferTimes`: Number of deferrals allowed
- `ForceCountdown`: Countdown duration on deferral dialog

**Example**:
```powershell
Show-InstallationWelcome -AllowDefer -DeferTimes 3 -ForceCountdown 1800
```

**Behavior**:
- Shows deferral dialog with 30-minute countdown
- Automatically proceeds with installation when countdown expires

---

## Timeout-Based Dialogs

### 1. Show-InstallationPrompt with Timeout

**Purpose**: Shows a message dialog that auto-closes after specified time.

**Function**: `Show-InstallationPrompt`

**Key Parameters**:
- `Message`: Dialog message text
- `Timeout`: Auto-close timeout in seconds
- `ButtonRightText`: Button text (default: "OK")

**Example**:
```powershell
Show-InstallationPrompt -Message "This will auto-close in 30 seconds!" -Timeout 30 -ButtonRightText "OK"
```

**Behavior**:
- Shows static message dialog
- **NO VISUAL COUNTDOWN** - just waits and closes
- Good for notifications and simple alerts

### 2. Show-DialogBox with Timeout

**Purpose**: Custom dialog box with timeout functionality.

**Function**: `Show-DialogBox`

**Key Parameters**:
- `Text`: Dialog message
- `Timeout`: Auto-close timeout in seconds
- `Title`: Dialog title

**Example**:
```powershell
Show-DialogBox -Text "Process will continue automatically..." -Timeout 15 -Title "Notice"
```

---

## Restart Countdown Timers

### ⚠️ DANGEROUS - Show-InstallationRestartPrompt

**Purpose**: Shows countdown before system restart.

**Function**: `Show-InstallationRestartPrompt`

**Key Parameters**:
- `CountdownSeconds`: Countdown duration (default: 60)
- `CountdownNoHideSeconds`: Time dialog cannot be hidden (default: 30)

**Example**:
```powershell
Show-InstallationRestartPrompt -CountdownSeconds 600 -CountdownNoHideSeconds 60
```

**⚠️ WARNING**: This function **WILL RESTART YOUR COMPUTER** when countdown reaches 0!

**Behavior**:
- Shows visual countdown timer
- Restarts system when countdown expires
- Use only in production deployments, never for testing

---

## Working Examples

### Example 1: Safe Visual Countdown Test
```powershell
# File: Test-VisualCountdown.ps1
#region Initialize
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$psadtPath = Join-Path $scriptPath "PSAppDeployToolkit\Toolkit\AppDeployToolkit"
. "$psadtPath\AppDeployToolkitMain.ps1"
#endregion

#region Main
try {
    $appName = "Visual Countdown Test"
    $appVersion = "1.0"
    $appVendor = "Test"
    
    # Start notepad first: notepad.exe
    # Then run this script to see visual countdown
    Show-InstallationWelcome -CloseApps 'notepad' -ForceCloseAppsCountdown 60 -BlockExecution
    
    Write-Log "Visual countdown completed successfully!" -Source "Test"
}
catch {
    Write-Log "Error: $($_.Exception.Message)" -Source "Test" -Severity 3
}
#endregion
```

### Example 2: Silent Timeout Dialog
```powershell
# File: Test-SilentTimeout.ps1
#region Initialize
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$psadtPath = Join-Path $scriptPath "PSAppDeployToolkit\Toolkit\AppDeployToolkit"
. "$psadtPath\AppDeployToolkitMain.ps1"
#endregion

#region Main
try {
    $appName = "Silent Timeout Test"
    $appVersion = "1.0"
    $appVendor = "Test"
    
    Show-InstallationPrompt -Message "This dialog will auto-close in 30 seconds!" -Timeout 30 -ButtonRightText "OK"
    
    Write-Log "Silent timeout completed successfully!" -Source "Test"
}
catch {
    Write-Log "Error: $($_.Exception.Message)" -Source "Test" -Severity 3
}
#endregion
```

### Example 3: Complex Deferral with Countdown
```powershell
# File: Test-DeferralCountdown.ps1
#region Initialize
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$psadtPath = Join-Path $scriptPath "PSAppDeployToolkit\Toolkit\AppDeployToolkit"
. "$psadtPath\AppDeployToolkitMain.ps1"
#endregion

#region Main
try {
    $appName = "Deferral Countdown Test"
    $appVersion = "1.0"
    $appVendor = "Test"
    
    Show-InstallationWelcome -CloseApps 'chrome,firefox' -CloseAppsCountdown 120 -AllowDefer -DeferTimes 3 -BlockExecution
    
    Write-Log "Deferral countdown completed successfully!" -Source "Test"
}
catch {
    Write-Log "Error: $($_.Exception.Message)" -Source "Test" -Severity 3
}
#endregion
```

---

## Configuration Options

### AppDeployToolkitConfig.xml Settings

**Timeout Configuration**:
```xml
<Config_Option>
    <Option Name="InstallationUI_Timeout" Value="6900" />
    <Option Name="InstallationUI_ExitCode" Value="1618" />
    <Option Name="InstallationDefer_ExitCode" Value="60012" />
</Config_Option>
```

**Countdown Messages** (English):
```xml
<UI_Messages_EN>
    <ClosePrompt_CountdownMessage>NOTE: The program(s) will be automatically closed in:</ClosePrompt_CountdownMessage>
    <WelcomePrompt_CountdownMessage>The {0} will automatically continue in:</WelcomePrompt_CountdownMessage>
    <RestartPrompt_MessageRestart>Your computer will be automatically restarted at the end of the countdown.</RestartPrompt_MessageRestart>
</UI_Messages_EN>
```

### Default Values
- `CountdownSeconds`: 60 seconds (restart prompt)
- `CountdownNoHideSeconds`: 30 seconds (restart prompt)
- `InstallationUI_Timeout`: 6900 seconds (1 hour 55 minutes)
- `CloseAppsCountdown`: 0 seconds (disabled by default)
- `ForceCloseAppsCountdown`: 0 seconds (disabled by default)

---

## AI Agent Guidelines

### For AI Agents Implementing PSADT v3 Countdown Timers

#### 1. **Safety First**
- **NEVER** use `Show-InstallationRestartPrompt` in test environments
- **ALWAYS** use `Show-InstallationWelcome` with `ForceCloseAppsCountdown` for safe testing
- **WARN** users about restart functions explicitly

#### 2. **Implementation Steps**
1. **Clone the repository**: `git clone https://github.com/PSAppDeployToolkit/PSAppDeployToolkit.git`
2. **Checkout v3.10.2**: `git checkout 3.10.2`
3. **Use correct path**: `PSAppDeployToolkit\Toolkit\AppDeployToolkit\AppDeployToolkitMain.ps1`
4. **Test with safe functions first**

#### 3. **Function Selection Guide**
- **Visual countdown needed**: Use `Show-InstallationWelcome` with `ForceCloseAppsCountdown`
- **Simple timeout needed**: Use `Show-InstallationPrompt` with `Timeout`
- **Deferral + countdown**: Use `Show-InstallationWelcome` with `CloseAppsCountdown` and `AllowDefer`
- **System restart**: Use `Show-InstallationRestartPrompt` (⚠️ DANGEROUS)

#### 4. **Testing Approach**
1. Start with notepad: `notepad.exe`
2. Run countdown script targeting notepad
3. Observe visual countdown behavior
4. Verify applications close properly

#### 5. **Common Parameters**
- `CloseApps`: `'notepad,chrome,excel'` (comma-separated)
- `ForceCloseAppsCountdown`: `60` (seconds)
- `BlockExecution`: Include to prevent app restart
- `Timeout`: `30` (seconds for simple dialogs)

---

## Documentation References

### Official PSADT v3 Documentation
1. **GitHub Repository**: https://github.com/PSAppDeployToolkit/PSAppDeployToolkit
2. **v3.10.2 Documentation**: https://psappdeploytoolkit.com/docs/3.10.2/
3. **Function Reference**: https://psappdeploytoolkit.com/docs/reference

### Specific Function Documentation
1. **Show-InstallationWelcome**: `PSAppDeployToolkit\wiki\Show-InstallationWelcome.md`
2. **Show-InstallationPrompt**: `PSAppDeployToolkit\wiki\Show-InstallationPrompt.md`
3. **Show-InstallationRestartPrompt**: `PSAppDeployToolkit\wiki\Show-InstallationRestartPrompt.md`
4. **Configuration Guide**: `PSAppDeployToolkit\wiki\Toolkit-Configuration.md`

### Code Examples Location
1. **VLC Example**: `PSAppDeployToolkit\Examples\VLC\Deploy-Application.ps1`
2. **WinSCP Example**: `PSAppDeployToolkit\Examples\WinSCP\Deploy-Application.ps1`
3. **Template**: `PSAppDeployToolkit\Toolkit\Deploy-Application.ps1`

### Configuration Files
1. **Main Config**: `PSAppDeployToolkit\Toolkit\AppDeployToolkit\AppDeployToolkitConfig.xml`
2. **Help Reference**: `PSAppDeployToolkit\Toolkit\AppDeployToolkit\AppDeployToolkitHelp.ps1`

### Additional Resources
1. **PowerShell Gallery**: https://www.powershellgallery.com/packages/PSADT/3.9.3
2. **Community Forums**: https://discourse.psappdeploytoolkit.com/
3. **GitHub Issues**: https://github.com/PSAppDeployToolkit/PSAppDeployToolkit/issues

---

## Best Practices

### 1. **Development Environment**
- Use virtual machines for testing
- Always test countdown timers thoroughly
- Keep backups before implementing restart functions

### 2. **Function Selection**
- Use `ForceCloseAppsCountdown` for immediate countdown
- Use `CloseAppsCountdown` with deferrals for user-friendly experience
- Use `Timeout` for simple notifications

### 3. **User Experience**
- Provide adequate countdown time (minimum 60 seconds)
- Use clear, informative messages
- Allow deferrals when appropriate

### 4. **Error Handling**
- Wrap countdown functions in try-catch blocks
- Log all countdown events
- Provide fallback options for failed countdowns

### 5. **Production Deployment**
- Test all countdown scenarios thoroughly
- Use appropriate exit codes (1618 for timeouts)
- Monitor deployment success rates

---

## Troubleshooting

### Common Issues

#### 1. **"AppDeployToolkitMain.ps1 not found"**
**Solution**: Verify the correct path structure
```powershell
$psadtPath = Join-Path $scriptPath "PSAppDeployToolkit\Toolkit\AppDeployToolkit"
```

#### 2. **"Write-Log not recognized"**
**Solution**: Ensure PSADT is properly imported before using functions

#### 3. **Countdown not showing**
**Solution**: 
- Verify target applications are running
- Check `ForceCloseAppsCountdown` parameter value
- Ensure user session is active

#### 4. **Applications not closing**
**Solution**:
- Add `BlockExecution` parameter
- Verify application names are correct
- Check process permissions

#### 5. **Timeout behaviors**
**Solution**:
- Default timeout is 6900 seconds (1 hour 55 minutes)
- Adjust `InstallationUI_Timeout` in config if needed
- Monitor exit codes (1618 = timeout, 60012 = deferral)

### Debug Steps
1. **Enable verbose logging**: Set `$VerbosePreference = 'Continue'`
2. **Check log files**: Located in `C:\Windows\Logs\Software`
3. **Test with simple applications**: Use notepad.exe first
4. **Verify user permissions**: Ensure adequate privileges

---

## Summary

This guide provides comprehensive coverage of PSADT v3 countdown timer functionality. Key takeaways:

1. **Two main countdown types**: Visual countdown and silent timeout
2. **Safe testing function**: `Show-InstallationWelcome` with `ForceCloseAppsCountdown`
3. **Dangerous function**: `Show-InstallationRestartPrompt` (avoid in testing)
4. **Configuration options**: Available in `AppDeployToolkitConfig.xml`
5. **Best practices**: Always test thoroughly, use appropriate timeouts, handle errors

For AI agents: Follow the implementation steps, use safe functions for testing, and always warn users about restart functionality.

---

**Document Version**: 1.0  
**PSADT Version**: 3.10.2  
**Last Updated**: 2025-07-17  
**Created By**: AI Assistant for PSADT v3 Countdown Timer Implementation