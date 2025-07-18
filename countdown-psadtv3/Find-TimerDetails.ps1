# Script to find timer implementation details
$content = Get-Content 'PSAppDeployToolkit\Toolkit\AppDeployToolkit\AppDeployToolkitMain.ps1'
$lineNum = 0
$inCountdownSection = $false
$countdownLines = @()

foreach ($line in $content) {
    $lineNum++
    
    if ($line -match '\$showCountdown') {
        $inCountdownSection = $true
        Write-Host "Found showCountdown at line $lineNum"
    }
    
    if ($inCountdownSection -and $line -match '(Interval|welcomeTimer|timerCountdown)') {
        $countdownLines += "${lineNum}: $line"
    }
    
    if ($inCountdownSection -and $line -match '^\s*\}') {
        if ($line -notmatch 'Else') {
            $inCountdownSection = $false
        }
    }
}

Write-Host "`nTimer-related lines in countdown sections:"
$countdownLines | ForEach-Object { Write-Host $_ }