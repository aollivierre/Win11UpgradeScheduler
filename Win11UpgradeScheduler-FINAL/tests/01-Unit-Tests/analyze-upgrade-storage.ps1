# Analyze actual storage used during Windows 11 upgrade
Write-Host "ANALYZING STORAGE REQUIREMENTS FROM UPGRADE" -ForegroundColor Cyan
Write-Host ("=" * 50) -ForegroundColor Cyan

# Current free space
$currentDisk = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='C:'"
$currentFreeGB = [math]::Round($currentDisk.FreeSpace / 1GB, 2)
Write-Host "`nCurrent free space: $currentFreeGB GB" -ForegroundColor Yellow

# Check Windows.old size (this is what the upgrade used)
if (Test-Path "C:\Windows.old") {
    $windowsOldSize = (Get-ChildItem "C:\Windows.old" -Recurse -Force -ErrorAction SilentlyContinue | 
                       Measure-Object -Property Length -Sum).Sum / 1GB
    Write-Host "Windows.old folder size: $([math]::Round($windowsOldSize, 2)) GB" -ForegroundColor Green
    Write-Host "This represents the old Windows 10 installation backup" -ForegroundColor Gray
}

# Before upgrade we had ~76GB free
# After upgrade we have current free space
# The difference plus Windows.old size = approximate space used

Write-Host "`nSTORAGE ANALYSIS:" -ForegroundColor Cyan
Write-Host "Free space before upgrade: ~76 GB" -ForegroundColor Yellow
Write-Host "Free space after upgrade: $currentFreeGB GB" -ForegroundColor Yellow
$spaceUsed = 76 - $currentFreeGB
Write-Host "Net space consumed: ~$([math]::Round($spaceUsed, 2)) GB" -ForegroundColor Green

# Check for other upgrade artifacts
$tempFolders = @(
    "C:\`$WINDOWS.~BT",
    "C:\`$WINDOWS.~WS",
    "C:\Windows\SoftwareDistribution\Download"
)

$tempSizeTotal = 0
foreach ($folder in $tempFolders) {
    if (Test-Path $folder) {
        $size = (Get-ChildItem $folder -Recurse -Force -ErrorAction SilentlyContinue | 
                 Measure-Object -Property Length -Sum).Sum / 1GB
        Write-Host "$folder`: $([math]::Round($size, 2)) GB" -ForegroundColor Gray
        $tempSizeTotal += $size
    }
}

Write-Host "`nRECOMMENDATIONS:" -ForegroundColor Green
Write-Host "Based on this upgrade:" -ForegroundColor Yellow
$actualSpaceNeeded = $windowsOldSize + $spaceUsed + 5  # 5GB buffer
Write-Host "- Actual space needed: ~$([math]::Round($actualSpaceNeeded, 2)) GB" -ForegroundColor Green
Write-Host "- Safe minimum: $([math]::Round($actualSpaceNeeded * 1.2, 2)) GB (20% buffer)" -ForegroundColor Yellow
Write-Host "- Conservative minimum: 35 GB" -ForegroundColor Cyan
Write-Host "- Official requirement: 64 GB" -ForegroundColor Gray