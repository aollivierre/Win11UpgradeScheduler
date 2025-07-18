# Create mock Windows 11 ISO setup.exe for testing
# This simulates the behavior of the real Windows 11 setup.exe with /eula accept support

$mockSetupCode = @'
using System;
using System.Threading;
using System.IO;
using System.Linq;

class MockWin11Setup {
    static int Main(string[] args) {
        Console.WriteLine("=====================================");
        Console.WriteLine("Windows 11 Setup (Mock ISO Version)");
        Console.WriteLine("=====================================");
        Console.WriteLine();
        
        // Parse command line arguments
        var argsList = args.Select(a => a.ToLower()).ToList();
        bool eulaAccepted = false;
        bool quietMode = false;
        bool autoUpgrade = false;
        bool noReboot = false;
        string logPath = null;
        
        // Display received arguments
        Console.WriteLine("Arguments received:");
        foreach (var arg in args) {
            Console.WriteLine($"  {arg}");
            
            // Check for EULA acceptance
            if (arg.ToLower() == "/eula" && args.Length > Array.IndexOf(args, arg) + 1) {
                var nextArg = args[Array.IndexOf(args, arg) + 1];
                if (nextArg.ToLower() == "accept") {
                    eulaAccepted = true;
                }
            }
            
            // Check other parameters
            if (arg.ToLower() == "/quiet") quietMode = true;
            if (arg.ToLower() == "/auto" && args.Length > Array.IndexOf(args, arg) + 1) {
                var nextArg = args[Array.IndexOf(args, arg) + 1];
                if (nextArg.ToLower() == "upgrade") autoUpgrade = true;
            }
            if (arg.ToLower() == "/noreboot") noReboot = true;
            if (arg.ToLower() == "/copylogs" && args.Length > Array.IndexOf(args, arg) + 1) {
                logPath = args[Array.IndexOf(args, arg) + 1];
            }
        }
        
        Console.WriteLine();
        Console.WriteLine($"EULA Accepted: {eulaAccepted}");
        Console.WriteLine($"Quiet Mode: {quietMode}");
        Console.WriteLine($"Auto Upgrade: {autoUpgrade}");
        Console.WriteLine($"No Reboot: {noReboot}");
        if (logPath != null) Console.WriteLine($"Log Path: {logPath}");
        Console.WriteLine();
        
        // Simulate EULA requirement
        if (!eulaAccepted) {
            if (quietMode) {
                Console.WriteLine("ERROR: EULA must be accepted for quiet installation!");
                Console.WriteLine("Use: /eula accept");
                return 0xC190010E; // MOSETUP_E_EULA_ACCEPT_REQUIRED
            } else {
                Console.WriteLine("=== END USER LICENSE AGREEMENT ===");
                Console.WriteLine("This is where the EULA would be displayed.");
                Console.WriteLine("User interaction would be required here.");
                Console.WriteLine("Mock: Simulating user did NOT accept EULA");
                Thread.Sleep(2000);
                return 1602; // User cancelled
            }
        }
        
        // If we get here, EULA was accepted via command line
        Console.WriteLine("EULA has been accepted via command line!");
        Console.WriteLine("Proceeding with Windows 11 upgrade...");
        Console.WriteLine();
        
        if (!quietMode) {
            // Simulate upgrade phases
            string[] phases = {
                "Checking system requirements...",
                "Downloading Windows 11 updates...",
                "Preparing installation files...",
                "Creating recovery point...",
                "Installing Windows 11...",
                "Migrating user settings...",
                "Configuring Windows 11 features...",
                "Finalizing installation..."
            };
            
            foreach (var phase in phases) {
                Console.WriteLine($"[{DateTime.Now:HH:mm:ss}] {phase}");
                Thread.Sleep(1000);
            }
        } else {
            Console.WriteLine("Running in quiet mode - minimal output");
            Thread.Sleep(3000);
        }
        
        // Create log file if requested
        if (!string.IsNullOrEmpty(logPath)) {
            try {
                Directory.CreateDirectory(logPath);
                var logFile = Path.Combine(logPath, $"Win11Setup_{DateTime.Now:yyyyMMdd_HHmmss}.log");
                File.WriteAllText(logFile, $"Windows 11 Setup Log\nStarted: {DateTime.Now}\nEULA Accepted: {eulaAccepted}\nCompleted successfully\n");
                Console.WriteLine($"Log file created: {logFile}");
            } catch (Exception ex) {
                Console.WriteLine($"Warning: Could not create log file: {ex.Message}");
            }
        }
        
        Console.WriteLine();
        Console.WriteLine("Windows 11 upgrade simulation completed successfully!");
        
        if (!noReboot && !quietMode) {
            Console.WriteLine("System would normally restart here to complete the upgrade.");
        }
        
        // Return success
        return 0;
    }
}
'@

# Compile the mock setup
Write-Host "Creating mock Windows 11 ISO setup.exe..." -ForegroundColor Yellow
Add-Type -TypeDefinition $mockSetupCode -Language CSharp -OutputAssembly ".\setup.exe" -OutputType ConsoleApplication

# Create minimal ISO structure
$folders = @("sources", "boot", "efi", "support")
foreach ($folder in $folders) {
    New-Item -ItemType Directory -Path ".\$folder" -Force | Out-Null
}

# Create some dummy files to make it look like a real ISO
"Windows 11 Installation Media" | Out-File ".\sources\install.wim"
"Boot files" | Out-File ".\boot\boot.wim"
"<?xml version='1.0'?><media>Win11</media>" | Out-File ".\MediaMeta.xml"

Write-Host "Mock ISO structure created successfully!" -ForegroundColor Green
Write-Host "Files created:" -ForegroundColor Cyan
Get-ChildItem -Path . -Recurse | Select-Object FullName