# Debug script to trace conditional flow issue
param(
    [string]$ScriptPath = ".\src\Deploy-Application-InstallationAssistant-Version.ps1"
)

Write-Host "`n=== Debugging Conditional Flow Issue ===" -ForegroundColor Cyan

# Insert debug logging to trace execution
$scriptContent = Get-Content $ScriptPath -Raw

# Create a backup
$backupPath = $ScriptPath -replace '\.ps1$', '_BACKUP.ps1'
$scriptContent | Set-Content $backupPath -Force
Write-Host "Created backup at: $backupPath" -ForegroundColor Green

# Insert debug logs at critical points
$debugPoints = @(
    @{
        After = '\$script:SchedulingComplete = \$true'
        Insert = 'Write-Log -Message "[DEBUG] SchedulingComplete set to TRUE at line $($MyInvocation.ScriptLineNumber)" -Source $deployAppScriptFriendlyName'
    },
    @{
        After = '\$script:SchedulingComplete = \$false'
        Insert = 'Write-Log -Message "[DEBUG] SchedulingComplete set to FALSE at line $($MyInvocation.ScriptLineNumber)" -Source $deployAppScriptFriendlyName'
    },
    @{
        Before = 'If \(-not \$script:SchedulingComplete\) \{'
        Insert = 'Write-Log -Message "[DEBUG] About to check SchedulingComplete flag. Current value: $($script:SchedulingComplete)" -Source $deployAppScriptFriendlyName'
    },
    @{
        After = '#region Installation'
        Insert = 'Write-Log -Message "[DEBUG] Entering Installation region. SchedulingComplete = $($script:SchedulingComplete)" -Source $deployAppScriptFriendlyName'
    }
)

Write-Host "`nInserting debug points..." -ForegroundColor Yellow

$modifiedContent = $scriptContent
foreach ($point in $debugPoints) {
    if ($point.After) {
        $pattern = $point.After
        $replacement = "$pattern`n        $($point.Insert)"
        $modifiedContent = $modifiedContent -replace $pattern, $replacement
        Write-Host "  Added debug after: $($point.After.Substring(0, [Math]::Min(50, $point.After.Length)))..." -ForegroundColor Gray
    }
    elseif ($point.Before) {
        $pattern = $point.Before
        $replacement = "$($point.Insert)`n        $pattern"
        $modifiedContent = $modifiedContent -replace $pattern, $replacement
        Write-Host "  Added debug before: $($point.Before.Substring(0, [Math]::Min(50, $point.Before.Length)))..." -ForegroundColor Gray
    }
}

# Save debug version
$debugPath = $ScriptPath -replace '\.ps1$', '_DEBUG.ps1'
$modifiedContent | Set-Content $debugPath -Force

Write-Host "`n=== Debug Script Created ===" -ForegroundColor Green
Write-Host "Debug version saved to: $debugPath" -ForegroundColor White
Write-Host "`nTo test:" -ForegroundColor Yellow
Write-Host "1. Run the debug version instead of the original" -ForegroundColor White
Write-Host "2. Choose 'Schedule' and pick a time" -ForegroundColor White
Write-Host "3. Check the log for [DEBUG] entries" -ForegroundColor White
Write-Host "`nExpected debug output:" -ForegroundColor Cyan
Write-Host "  [DEBUG] SchedulingComplete set to FALSE at line 128" -ForegroundColor Gray
Write-Host "  [DEBUG] SchedulingComplete set to TRUE at line 294" -ForegroundColor Gray
Write-Host "  [DEBUG] About to check SchedulingComplete flag. Current value: True" -ForegroundColor Gray
Write-Host "  [DEBUG] Entering Installation region. SchedulingComplete = True" -ForegroundColor Gray
Write-Host "`nIf the installation still runs, check:" -ForegroundColor Red
Write-Host "- Is the 'About to check' debug message missing? (If block not reached)" -ForegroundColor White
Write-Host "- Is the 'Entering Installation' showing False? (Flag not set properly)" -ForegroundColor White
Write-Host "- Are there multiple 'set to TRUE/FALSE' messages? (Flag being reset)" -ForegroundColor White