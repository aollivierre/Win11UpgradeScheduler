# Quick check of script structure
$script = Get-Content ".\src\Deploy-Application-InstallationAssistant-Version.ps1"

Write-Host "`nSearching for key lines..." -ForegroundColor Cyan

# Find the scheduling complete check
for ($i = 0; $i -lt $script.Count; $i++) {
    if ($script[$i] -match 'If\s*\(\s*-not\s+\$script:SchedulingComplete') {
        Write-Host "`nFound scheduling check at line $($i+1):" -ForegroundColor Yellow
        Write-Host "$($i+1): $($script[$i])" -ForegroundColor White
    }
    
    if ($script[$i] -match '#region\s+Installation') {
        Write-Host "`nFound Installation region at line $($i+1):" -ForegroundColor Yellow
        Write-Host "$($i+1): $($script[$i])" -ForegroundColor White
        
        # Check previous lines for context
        Write-Host "`nContext (5 lines before):" -ForegroundColor Gray
        for ($j = [Math]::Max(0, $i-5); $j -lt $i; $j++) {
            Write-Host "$($j+1): $($script[$j])" -ForegroundColor DarkGray
        }
    }
    
    if ($script[$i] -match 'Starting Windows 11 upgrade process') {
        Write-Host "`nFound upgrade start at line $($i+1):" -ForegroundColor Yellow
        Write-Host "$($i+1): $($script[$i])" -ForegroundColor White
    }
}

Write-Host "`n[IMPORTANT] The Installation region should be INSIDE the If (-not SchedulingComplete) block!" -ForegroundColor Red