# Test script to verify Windows 11 Installation Assistant integration
# Run this from an elevated PowerShell prompt

$ErrorActionPreference = 'Stop'

Write-Host "=== Windows 11 Installation Assistant Test ===" -ForegroundColor Cyan
Write-Host ""

# Check if running as admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-not $isAdmin) {
    Write-Host "ERROR: This script must be run as Administrator!" -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator and try again." -ForegroundColor Yellow
    exit 1
}

# Navigate to source directory
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$srcPath = Join-Path $scriptPath "src"

if (-not (Test-Path $srcPath)) {
    Write-Host "ERROR: Source directory not found at: $srcPath" -ForegroundColor Red
    exit 1
}

Set-Location $srcPath
Write-Host "Working directory: $PWD" -ForegroundColor Green
Write-Host ""

# Check if Installation Assistant exists
$assistantPath = Join-Path $srcPath "Files\Windows11InstallationAssistant.exe"
if (Test-Path $assistantPath) {
    Write-Host "✓ Windows 11 Installation Assistant found" -ForegroundColor Green
    $fileInfo = Get-Item $assistantPath
    Write-Host "  Size: $([math]::Round($fileInfo.Length / 1MB, 2)) MB" -ForegroundColor Gray
    Write-Host "  Path: $assistantPath" -ForegroundColor Gray
} else {
    Write-Host "✗ Windows 11 Installation Assistant NOT found!" -ForegroundColor Red
    Write-Host "  Expected at: $assistantPath" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "=== Testing Deployment Script ===" -ForegroundColor Cyan
Write-Host ""

# Test parameters
Write-Host "Test Options:" -ForegroundColor Yellow
Write-Host "1. Interactive mode (full UI experience)"
Write-Host "2. Silent mode (minimal UI, auto-proceed)"
Write-Host "3. Check scheduled tasks"
Write-Host "4. Exit"
Write-Host ""

$choice = Read-Host "Select test option (1-4)"

switch ($choice) {
    "1" {
        Write-Host ""
        Write-Host "Starting deployment in Interactive mode..." -ForegroundColor Green
        Write-Host "The Installation Assistant will show its own progress window." -ForegroundColor Yellow
        Write-Host ""
        & ".\Deploy-Application.ps1" -DeployMode "Interactive"
    }
    "2" {
        Write-Host ""
        Write-Host "Starting deployment in Silent mode..." -ForegroundColor Green
        Write-Host "The Installation Assistant will still show progress but won't require interaction." -ForegroundColor Yellow
        Write-Host ""
        & ".\Deploy-Application.ps1" -DeployMode "Silent"
    }
    "3" {
        Write-Host ""
        Write-Host "Checking for scheduled Windows 11 upgrade tasks..." -ForegroundColor Green
        $task = Get-ScheduledTask -TaskName "Windows11Upgrade_*" -ErrorAction SilentlyContinue
        if ($task) {
            Write-Host "Found scheduled task:" -ForegroundColor Green
            $task | Format-List TaskName, State, NextRunTime
        } else {
            Write-Host "No scheduled tasks found." -ForegroundColor Yellow
        }
    }
    "4" {
        Write-Host "Exiting test script." -ForegroundColor Gray
        exit 0
    }
    default {
        Write-Host "Invalid option selected." -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "=== Test Complete ===" -ForegroundColor Cyan
Write-Host "Check the log file for details:" -ForegroundColor Gray
Write-Host "C:\Windows\Logs\Software\Windows11_PSAppDeployToolkit_*.log" -ForegroundColor Gray