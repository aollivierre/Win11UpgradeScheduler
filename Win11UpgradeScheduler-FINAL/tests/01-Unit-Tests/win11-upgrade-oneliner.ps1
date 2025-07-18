#region One-Liner Windows 11 Upgrade Commands

<#
.SYNOPSIS
    Quick one-liner commands to upgrade Windows 10 to Windows 11
.DESCRIPTION
    These one-liners replicate your successful upgrade method using scheduled tasks
#>

#region Option 1: Direct Download and Run (Simplest)
# Run this in an elevated PowerShell prompt:
# powershell -Command "irm https://go.microsoft.com/fwlink/?linkid=2171764 -OutFile C:\Win11.exe; Start-Process C:\Win11.exe -ArgumentList '/QuietInstall','/SkipEULA' -Wait"

#endregion

#region Option 2: Scheduled Task Method (What worked for you)
# This replicates your successful SYSTEM-level upgrade:
# powershell -Command "$a=New-ScheduledTaskAction -Execute 'C:\Win11.exe' -Argument '/QuietInstall /SkipEULA';$p=New-ScheduledTaskPrincipal -UserId SYSTEM -RunLevel Highest;irm https://go.microsoft.com/fwlink/?linkid=2171764 -OutFile C:\Win11.exe;Register-ScheduledTask -TaskName Win11Up -Action $a -Principal $p -Force;Start-ScheduledTask -TaskName Win11Up"

#endregion

#region Option 3: Full One-Liner with Download and Task Creation
# Complete one-liner that downloads and runs via scheduled task:
powershell -Command "irm https://go.microsoft.com/fwlink/?linkid=2171764 -OutFile C:\Win11.exe; schtasks /create /f /tn Win11Up /tr 'C:\Win11.exe /QuietInstall /SkipEULA' /sc once /st 00:00 /ru SYSTEM; schtasks /run /tn Win11Up"

#endregion

#region Testing Instructions
<#
To test on a Windows 10 machine:

1. Open Command Prompt as Administrator
2. Copy and paste one of the one-liners above
3. Press Enter and wait

What happens:
- Downloads Windows 11 Installation Assistant to C:\Win11.exe
- Creates a scheduled task running as SYSTEM
- Starts the upgrade immediately
- EULA might be auto-accepted when running as SYSTEM

Requirements:
- Windows 10 (any recent version)
- Administrator privileges  
- Internet connection
- ~50GB free disk space (based on your successful test)

To monitor progress:
- Check for Installation Assistant window
- Run: schtasks /query /tn Win11Up /v
- Look for "Working on updates" screen
- System will reboot automatically

To clean up after testing:
- schtasks /delete /tn Win11Up /f
- del C:\Win11.exe
#>
#endregion