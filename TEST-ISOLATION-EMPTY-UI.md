# Isolated Test Case for Empty UI Issue

## The Exact Problem
When `Execute-ProcessAsUser` runs a PowerShell script from SYSTEM context, the PSADT `Show-InstallationPrompt` dialog appears but with NO TEXT.

## Minimal Reproduction Steps

### 1. Create Simple Test Script
Save as `C:\Temp\TestPrompt.ps1`:
```powershell
# Hardcoded paths to eliminate variables
. 'C:\code\Win11UpgradeScheduler\Win11UpgradeScheduler-FINAL\src\AppDeployToolkit\AppDeployToolkitMain.ps1'

# Simple test message
Show-InstallationPrompt -Message "Test Message" -ButtonRightText 'OK' -Icon Error
```

### 2. Test Direct Execution (Should Work)
```powershell
powershell.exe -ExecutionPolicy Bypass -File "C:\Temp\TestPrompt.ps1"
```
Expected: Dialog shows with "Test Message"

### 3. Test via Execute-ProcessAsUser (Reproduces Issue)
```powershell
# Load toolkit first
. 'C:\code\Win11UpgradeScheduler\Win11UpgradeScheduler-FINAL\src\AppDeployToolkit\AppDeployToolkitMain.ps1'

# Run as user
Execute-ProcessAsUser -Path "$PSHOME\powershell.exe" -Parameters "-ExecutionPolicy Bypass -File `"C:\Temp\TestPrompt.ps1`"" -Wait
```
Expected: Dialog shows but EMPTY

## Key Observations

### Process Tree When Issue Occurs
1. `wscript.exe /e:vbscript RunHidden.vbs powershell.exe -ExecutionPolicy Bypass -File "script.ps1"`
2. `powershell.exe` (child process in user context)
3. PSADT dialog appears but empty

### What We Know
- The script executes (dialog appears)
- PSADT loads (functions are available)
- Show-InstallationPrompt is called (dialog shows)
- But the message parameter is lost/empty

## Focused Investigation Areas

### 1. Check RunHidden.vbs
Path: `C:\Windows\SystemTemp\PSAppDeployToolkit\ExecuteAsUser\RunHidden.vbs`
- How does it pass arguments?
- Is there string escaping issues?

### 2. Check Execute-ProcessAsUser Implementation
In `AppDeployToolkitMain.ps1`, search for:
- How it creates the scheduled task
- How it passes parameters
- Any string manipulation

### 3. Variable Scope in Child Process
When PowerShell runs via wscript/RunHidden.vbs:
- Are global variables preserved?
- Is the PSADT context fully initialized?

## Test Variations to Try

### Test 1: Hardcode Everything
```powershell
# In the temporary script, hardcode the message in Show-InstallationPrompt
Show-InstallationPrompt -Message "Hardcoded message" -ButtonRightText 'OK' -Icon Error
```

### Test 2: Message Via Environment Variable
```powershell
# Set message in env var before Execute-ProcessAsUser
$env:PSADT_MESSAGE = "Test via env var"

# In script:
Show-InstallationPrompt -Message $env:PSADT_MESSAGE -ButtonRightText 'OK' -Icon Error
```

### Test 3: Message Via File
```powershell
# Write message to file
"Test via file" | Set-Content "C:\Temp\message.txt"

# In script:
$msg = Get-Content "C:\Temp\message.txt"
Show-InstallationPrompt -Message $msg -ButtonRightText 'OK' -Icon Error
```

## Critical Question
The issue appears to be that when `Execute-ProcessAsUser` launches the PowerShell process through `RunHidden.vbs`, something in that chain causes the message parameter to be lost or not properly passed to `Show-InstallationPrompt`.

## Next Steps for AI Engineer
1. Run `INVESTIGATION-GUIDE-EMPTY-UI.ps1` to gather diagnostic data
2. Create the minimal test case above
3. Test each variation to isolate where the message gets lost
4. Check if other PSADT parameters are also affected (Icon, ButtonText)
5. Investigate the Execute-ProcessAsUser implementation for string handling issues