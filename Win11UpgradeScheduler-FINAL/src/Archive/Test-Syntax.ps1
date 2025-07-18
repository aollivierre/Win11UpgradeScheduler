# Syntax check script
$ErrorActionPreference = 'Stop'

$files = @(
    'Deploy-Application-InstallationAssistant-Version.ps1',
    'SupportFiles\Modules\02-PreFlightChecks.psm1'
)

foreach ($file in $files) {
    Write-Host "Checking: $file" -ForegroundColor Cyan
    
    try {
        $errors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseFile($file, [ref]$null, [ref]$errors)
        
        if ($errors) {
            Write-Host "Syntax errors found in $file`:" -ForegroundColor Red
            foreach ($error in $errors) {
                Write-Host "  Line $($error.Extent.StartLineNumber): $($error.Message)" -ForegroundColor Red
            }
        }
        else {
            Write-Host "  No syntax errors found" -ForegroundColor Green
        }
    }
    catch {
        Write-Host "  Failed to parse: $_" -ForegroundColor Red
    }
}