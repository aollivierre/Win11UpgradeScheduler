# Test the scheduled task wrapper directly
$PSADTPath = "C:\code\Win11UpgradeScheduler\Win11UpgradeScheduler-FINAL\src"

# Test the wrapper
& "$PSADTPath\SupportFiles\ScheduledTaskWrapper.ps1" -PSADTPath $PSADTPath -DeploymentType Install -DeployMode Interactive