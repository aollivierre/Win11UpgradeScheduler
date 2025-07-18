# Prepare-Windows11ISO.ps1
# Script to help prepare Windows 11 ISO for deployment
# Must be run as Administrator

#Requires -RunAsAdministrator

param(
    [Parameter(Mandatory=$false)]
    [string]$ISOPath,
    
    [Parameter(Mandatory=$false)]
    [string]$DestinationPath = "$PSScriptRoot\src\Files\ISO",
    
    [switch]$DownloadMediaCreationTool,
    [switch]$ValidateOnly
)

$ErrorActionPreference = 'Stop'

Write-Host "=== Windows 11 ISO Preparation Script ===" -ForegroundColor Cyan
Write-Host ""

# Function to download Media Creation Tool
function Download-MediaCreationTool {
    $url = "https://go.microsoft.com/fwlink/?linkid=2156295"
    $output = "$env:TEMP\MediaCreationToolW11.exe"
    
    Write-Host "Downloading Windows 11 Media Creation Tool..." -ForegroundColor Yellow
    try {
        Invoke-WebRequest -Uri $url -OutFile $output -UseBasicParsing
        Write-Host "Downloaded to: $output" -ForegroundColor Green
        Write-Host ""
        Write-Host "Please run the Media Creation Tool and:" -ForegroundColor Yellow
        Write-Host "1. Select 'Create installation media'" -ForegroundColor White
        Write-Host "2. Choose your language and edition" -ForegroundColor White
        Write-Host "3. Select 'ISO file'" -ForegroundColor White
        Write-Host "4. Save the ISO and note the path" -ForegroundColor White
        Write-Host "5. Re-run this script with -ISOPath parameter" -ForegroundColor White
        
        # Open folder
        explorer.exe "/select,$output"
    }
    catch {
        Write-Host "Error downloading Media Creation Tool: $_" -ForegroundColor Red
        Write-Host "Please download manually from:" -ForegroundColor Yellow
        Write-Host "https://www.microsoft.com/software-download/windows11" -ForegroundColor Cyan
    }
    return
}

# Function to mount and extract ISO
function Extract-ISO {
    param([string]$ISO, [string]$Destination)
    
    Write-Host "Mounting ISO: $ISO" -ForegroundColor Yellow
    
    try {
        # Mount the ISO
        $mount = Mount-DiskImage -ImagePath $ISO -PassThru
        $driveLetter = ($mount | Get-Volume).DriveLetter
        
        if (-not $driveLetter) {
            throw "Failed to get drive letter for mounted ISO"
        }
        
        $sourcePath = "${driveLetter}:\"
        Write-Host "ISO mounted at: $sourcePath" -ForegroundColor Green
        
        # Create destination directory
        if (-not (Test-Path $Destination)) {
            New-Item -ItemType Directory -Path $Destination -Force | Out-Null
        }
        
        # Count files for progress
        Write-Host "Counting files..." -ForegroundColor Gray
        $totalFiles = (Get-ChildItem -Path $sourcePath -Recurse -File).Count
        Write-Host "Total files to copy: $totalFiles" -ForegroundColor Gray
        
        # Copy with progress
        Write-Host "Copying ISO contents to: $Destination" -ForegroundColor Yellow
        Write-Host "This may take several minutes..." -ForegroundColor Gray
        
        $copied = 0
        Get-ChildItem -Path $sourcePath -Recurse | ForEach-Object {
            $targetPath = $_.FullName.Replace($sourcePath, $Destination + '\')
            
            if ($_.PSIsContainer) {
                New-Item -ItemType Directory -Path $targetPath -Force -ErrorAction SilentlyContinue | Out-Null
            }
            else {
                Copy-Item -Path $_.FullName -Destination $targetPath -Force
                $copied++
                if ($copied % 100 -eq 0) {
                    $percent = [math]::Round(($copied / $totalFiles) * 100, 2)
                    Write-Progress -Activity "Copying ISO files" -Status "$copied of $totalFiles files" -PercentComplete $percent
                }
            }
        }
        
        Write-Progress -Activity "Copying ISO files" -Completed
        Write-Host "Successfully copied all files!" -ForegroundColor Green
        
        # Verify critical files
        $criticalFiles = @(
            "setup.exe",
            "sources\install.wim",
            "sources\boot.wim"
        )
        
        Write-Host "`nVerifying critical files..." -ForegroundColor Yellow
        $allValid = $true
        foreach ($file in $criticalFiles) {
            $filePath = Join-Path $Destination $file
            if (Test-Path $filePath) {
                $size = [math]::Round((Get-Item $filePath).Length / 1MB, 2)
                Write-Host "  ✓ $file (${size}MB)" -ForegroundColor Green
            }
            else {
                Write-Host "  ✗ $file - MISSING!" -ForegroundColor Red
                $allValid = $false
            }
        }
        
        if ($allValid) {
            Write-Host "`nAll critical files verified!" -ForegroundColor Green
        }
        else {
            Write-Host "`nSome critical files are missing!" -ForegroundColor Red
        }
        
        return $allValid
    }
    finally {
        # Always unmount
        if ($mount) {
            Write-Host "`nUnmounting ISO..." -ForegroundColor Yellow
            Dismount-DiskImage -ImagePath $ISO
            Write-Host "ISO unmounted" -ForegroundColor Green
        }
    }
}

# Function to validate existing setup
function Validate-Setup {
    param([string]$Path)
    
    Write-Host "Validating Windows 11 setup files at: $Path" -ForegroundColor Yellow
    
    if (-not (Test-Path $Path)) {
        Write-Host "  ✗ Directory does not exist!" -ForegroundColor Red
        return $false
    }
    
    $setupExe = Join-Path $Path "setup.exe"
    if (-not (Test-Path $setupExe)) {
        Write-Host "  ✗ setup.exe not found!" -ForegroundColor Red
        return $false
    }
    
    # Test if setup.exe supports /eula accept
    Write-Host "`nTesting setup.exe parameters..." -ForegroundColor Yellow
    $helpOutput = & $setupExe /? 2>&1 | Out-String
    
    if ($helpOutput -match "eula") {
        Write-Host "  ✓ setup.exe supports /eula parameter" -ForegroundColor Green
        
        # Show the eula-related help
        $eulaHelp = $helpOutput -split "`n" | Where-Object { $_ -match "eula" }
        if ($eulaHelp) {
            Write-Host "`nEULA parameter documentation:" -ForegroundColor Cyan
            $eulaHelp | ForEach-Object { Write-Host "    $_" -ForegroundColor Gray }
        }
    }
    else {
        Write-Host "  ⚠ Could not verify /eula parameter support" -ForegroundColor Yellow
    }
    
    # Calculate total size
    Write-Host "`nCalculating total size..." -ForegroundColor Yellow
    $totalSize = (Get-ChildItem -Path $Path -Recurse | Measure-Object -Property Length -Sum).Sum / 1GB
    Write-Host "  Total size: $([math]::Round($totalSize, 2)) GB" -ForegroundColor Cyan
    
    Write-Host "`nSetup validation complete!" -ForegroundColor Green
    return $true
}

# Main script logic
if ($DownloadMediaCreationTool) {
    Download-MediaCreationTool
    return
}

if ($ValidateOnly) {
    $valid = Validate-Setup -Path $DestinationPath
    if ($valid) {
        Write-Host "`nWindows 11 setup files are ready for deployment!" -ForegroundColor Green
    }
    else {
        Write-Host "`nWindows 11 setup files need to be prepared!" -ForegroundColor Red
        Write-Host "Run this script with -ISOPath parameter to extract ISO files" -ForegroundColor Yellow
    }
    return
}

if (-not $ISOPath) {
    Write-Host "No ISO path provided!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Usage examples:" -ForegroundColor Yellow
    Write-Host "  .\Prepare-Windows11ISO.ps1 -DownloadMediaCreationTool" -ForegroundColor White
    Write-Host "  .\Prepare-Windows11ISO.ps1 -ISOPath 'C:\Downloads\Win11_23H2.iso'" -ForegroundColor White
    Write-Host "  .\Prepare-Windows11ISO.ps1 -ValidateOnly" -ForegroundColor White
    Write-Host ""
    
    # Check if ISO already extracted
    if (Test-Path $DestinationPath) {
        Write-Host "Checking existing setup files..." -ForegroundColor Yellow
        Validate-Setup -Path $DestinationPath
    }
    else {
        Write-Host "Destination path does not exist: $DestinationPath" -ForegroundColor Red
        Write-Host "Please provide an ISO path to extract Windows 11 setup files" -ForegroundColor Yellow
    }
    return
}

# Validate ISO exists
if (-not (Test-Path $ISOPath)) {
    Write-Host "ISO file not found: $ISOPath" -ForegroundColor Red
    return
}

# Extract ISO
Write-Host "Starting ISO extraction process..." -ForegroundColor Green
Write-Host "ISO Path: $ISOPath" -ForegroundColor Gray
Write-Host "Destination: $DestinationPath" -ForegroundColor Gray
Write-Host ""

$success = Extract-ISO -ISO $ISOPath -Destination $DestinationPath

if ($success) {
    Write-Host "`n=== Setup Complete ===" -ForegroundColor Green
    Write-Host "Windows 11 setup files are ready at:" -ForegroundColor Cyan
    Write-Host $DestinationPath -ForegroundColor White
    Write-Host ""
    Write-Host "The deployment script will now use setup.exe for silent installation" -ForegroundColor Green
    Write-Host "EULA will be automatically accepted with no user interaction required!" -ForegroundColor Green
}
else {
    Write-Host "`n=== Setup Failed ===" -ForegroundColor Red
    Write-Host "Please check the errors above and try again" -ForegroundColor Yellow
}