param($PSADTPath, $DeploymentType = 'Install', $DeployMode = 'Interactive')

function Test-UserSession {
    $explorerProcesses = Get-Process -Name explorer -ErrorAction SilentlyContinue
    return ($explorerProcesses.Count -gt 0)
}

# Main logic
$isAttended = Test-UserSession
Write-Output "Session type: $(if ($isAttended) { 'Attended' } else { 'Unattended' })"
exit 0
