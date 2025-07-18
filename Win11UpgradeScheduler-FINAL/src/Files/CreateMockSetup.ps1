# Create a mock setup.exe that simulates Windows 11 upgrade
$mockSetupCode = @'
using System;
using System.Threading;

class Program {
    static void Main(string[] args) {
        Console.WriteLine("=== Mock Windows 11 Setup ===");
        Console.WriteLine("This is a simulation of the Windows 11 upgrade process");
        Console.WriteLine();
        Console.WriteLine("Parameters received:");
        foreach (var arg in args) {
            Console.WriteLine("  " + arg);
        }
        Console.WriteLine();
        
        string[] phases = {
            "Checking system compatibility...",
            "Downloading Windows 11 updates...",
            "Preparing installation files...",
            "Creating recovery environment...",
            "Installing Windows 11 features...",
            "Migrating user settings...",
            "Finalizing installation..."
        };
        
        foreach (var phase in phases) {
            Console.WriteLine(phase);
            Thread.Sleep(2000);
        }
        
        Console.WriteLine();
        Console.WriteLine("Windows 11 upgrade simulation completed successfully!");
        Console.WriteLine("In a real scenario, the system would restart to complete the upgrade.");
        
        // Return success
        Environment.Exit(0);
    }
}
'@

# Compile the C# code to create an executable
Add-Type -TypeDefinition $mockSetupCode -Language CSharp -OutputAssembly ".\setup_mock.exe" -OutputType ConsoleApplication

# Remove old setup.exe and rename the mock
Remove-Item -Path ".\setup.exe" -Force -ErrorAction SilentlyContinue
Move-Item -Path ".\setup_mock.exe" -Destination ".\setup.exe" -Force

Write-Host "Mock setup.exe created successfully!" -ForegroundColor Green