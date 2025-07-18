# 🧪 EMPIRICAL TESTING GUIDE - Windows 11 Scheduler Fix

## QUICK TEST COMMAND
```powershell
# Just copy and paste this to test:
& "C:\Code\Windows\Win11UpgradeScheduler-FINAL\src\Deploy-Application-InstallationAssistant-Version.ps1"
```

## STEP-BY-STEP TESTING

### 1️⃣ Open TWO PowerShell Windows

**Window 1 - For Running Script:**
```powershell
cd C:\Code\Windows\Win11UpgradeScheduler-FINAL
```

**Window 2 - For Watching Logs:**
```powershell
Get-Content "C:\Windows\Logs\Software\PSAppDeployToolkit_Windows11Upgrade.log" -Tail 30 -Wait
```

### 2️⃣ Run the Test

In Window 1:
```powershell
& ".\src\Deploy-Application-InstallationAssistant-Version.ps1"
```

### 3️⃣ User Actions
1. **Info Dialog appears** → Click "Schedule"
2. **Calendar picker appears** → Select "Tomorrow - Afternoon (2 PM)"
3. **Confirmation dialog** → Click "OK"

### 4️⃣ What to Look For

#### ❌ CURRENT BROKEN BEHAVIOR (What you'll see now):
```
[TIME] Successfully scheduled upgrade
[TIME] ERROR: Installation region reached despite scheduling being complete!
[TIME] Skipping installation as scheduling was already done
```

#### ✅ EXPECTED FIXED BEHAVIOR (What you want):
```
[TIME] Successfully scheduled upgrade
[TIME] Windows11Upgrade Installation completed with exit code [3010]
```

## 🔍 QUICK DIAGNOSTICS

### Check If Fixed
```powershell
# Run this after your test:
$log = Get-Content "C:\Windows\Logs\Software\PSAppDeployToolkit_Windows11Upgrade.log" -Tail 100
if ($log -match "ERROR: Installation region reached") {
    Write-Host "❌ NOT FIXED - Installation region still being reached" -ForegroundColor Red
} else {
    Write-Host "✅ MIGHT BE FIXED - Check exit code" -ForegroundColor Green
}
```

### Check Exit Code
```powershell
& ".\src\Deploy-Application-InstallationAssistant-Version.ps1"; Write-Host "Exit Code: $LASTEXITCODE" -ForegroundColor Cyan
```
- Should see: `Exit Code: 3010`
- NOT: `Exit Code: 0`

## 🛠️ QUICK FIX LOCATIONS

### Most Likely Fix Points:

1. **After Line 299** (and similar locations where `$script:SchedulingComplete = $true`):
   ```powershell
   $script:SchedulingComplete = $true
   $configShowBalloonNotifications = $false
   Exit-Script -ExitCode 3010  # ADD THIS LINE
   ```

2. **Before Line 478** (before the If check):
   ```powershell
   # ADD THIS CHECK
   If ($script:SchedulingComplete) {
       Write-Log -Message "Scheduling completed, exiting gracefully"
       Exit-Script -ExitCode 3010
   }
   
   # Existing code
   If (-not $script:SchedulingComplete) {
   ```

## 📊 TEST RESULT TEMPLATE

After each test, record:
```
Test #: ___
Change Made: ________________________________
Schedule Selected: Tomorrow - Afternoon (2 PM)
Installation Region Reached: YES / NO
Exit Code: ___
Time from Schedule to Exit: ___ ms
Success: YES / NO
```

## 🔄 ITERATIVE TESTING PROCESS

1. **Make ONE change**
2. **Save the file**
3. **Run the test** (follow steps above)
4. **Check the results**
5. **If not fixed, try next approach**

## ⚡ QUICK VALIDATION

The fix is successful when:
```powershell
# This returns nothing (no error message found):
Select-String "ERROR: Installation region reached" "C:\Windows\Logs\Software\PSAppDeployToolkit_Windows11Upgrade.log" -Tail 50

# And exit code is 3010:
& ".\src\Deploy-Application-InstallationAssistant-Version.ps1"; $LASTEXITCODE
# Should output: 3010
```

## 💡 PRO TIPS

1. **Clear the log** between tests (optional):
   ```powershell
   Clear-Content "C:\Windows\Logs\Software\PSAppDeployToolkit_Windows11Upgrade.log" -Force
   ```

2. **Search for the flag setting**:
   ```powershell
   Select-String "SchedulingComplete = `$true" ".\src\Deploy-Application-InstallationAssistant-Version.ps1" -Context 0,5
   ```

3. **Find all Exit-Script calls**:
   ```powershell
   Select-String "Exit-Script" ".\src\Deploy-Application-InstallationAssistant-Version.ps1"
   ```

Remember: Test after EVERY change. Don't assume - VERIFY!