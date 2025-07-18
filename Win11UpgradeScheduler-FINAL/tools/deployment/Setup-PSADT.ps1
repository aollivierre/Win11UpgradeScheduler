# Setup PSADT v3.10.2 for Windows 11 Upgrade Scheduler Testing
Write-Host "Setting up PSADT v3.10.2 for full testing..." -ForegroundColor Green

# Create AppDeployToolkit directory
New-Item -ItemType Directory -Path ".\AppDeployToolkit" -Force | Out-Null

# Download PSADT v3.10.2
Write-Host "Downloading PSADT v3.10.2..." -ForegroundColor Yellow
Invoke-WebRequest -Uri "https://github.com/PSAppDeployToolkit/PSAppDeployToolkit/archive/refs/tags/3.10.2.zip" -OutFile "PSAppDeployToolkit_v3.10.2.zip"

# Extract the archive
Write-Host "Extracting PSADT v3.10.2..." -ForegroundColor Yellow
Expand-Archive -Path "PSAppDeployToolkit_v3.10.2.zip" -DestinationPath "." -Force

# Copy the toolkit files
Write-Host "Copying toolkit files..." -ForegroundColor Yellow
Copy-Item "PSAppDeployToolkit-3.10.2\Toolkit\AppDeployToolkit\*" -Destination ".\AppDeployToolkit\" -Recurse -Force

# Create Files directory for Windows 11 setup
New-Item -ItemType Directory -Path ".\Files" -Force | Out-Null

# Create a fake Windows 11 setup for testing
Write-Host "Creating test Windows 11 setup file..." -ForegroundColor Yellow
@"
@echo off
echo Windows 11 In-Place Upgrade Test Setup
echo This is a test file for demonstration purposes
echo In real deployment, this would be Windows11InstallationAssistant.exe
pause
"@ | Out-File -FilePath ".\Files\Windows11-Setup.exe" -Encoding ASCII

# Verify installation
if (Test-Path ".\AppDeployToolkit\AppDeployToolkitMain.ps1") {
    Write-Host "SUCCESS: PSADT v3.10.2 installed successfully!" -ForegroundColor Green
    Write-Host "Files created:" -ForegroundColor Cyan
    Get-ChildItem -Path ".\AppDeployToolkit" -Name | Select-Object -First 10 | ForEach-Object { Write-Host "  - $_" -ForegroundColor Gray }
} else {
    Write-Host "ERROR: PSADT installation failed!" -ForegroundColor Red
}

Write-Host "Setup complete! Ready to test full PSADT v3 flow." -ForegroundColor Green