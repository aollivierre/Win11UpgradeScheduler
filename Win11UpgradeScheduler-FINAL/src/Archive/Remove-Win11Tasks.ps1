Get-ScheduledTask | Where-Object {$_.TaskName -like "*Win11*"} | ForEach-Object {
    Write-Host "Removing task: $($_.TaskName)" -ForegroundColor Yellow
    $_ | Unregister-ScheduledTask -Confirm:$false
}