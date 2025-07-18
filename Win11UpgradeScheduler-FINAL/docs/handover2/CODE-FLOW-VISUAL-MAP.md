# 🗺️ VISUAL CODE FLOW MAP - Script Execution Path

## 📍 CURRENT PROBLEMATIC FLOW

```
START
  ↓
Line 125: Write-Log "Starting deployment"
  ↓
Line 128: $script:SchedulingComplete = $false
  ↓
Line 134: If ($DeployMode -ne 'Silent')
  ↓
Line 188: $existingSchedule = Get-UpgradeSchedule
  ↓
Line 217: Show-UpgradeInformationDialog
  ↓
User clicks "Schedule"
  ↓
Line 232: Show-CalendarPicker
  ↓
User selects "Tomorrow - Afternoon (2 PM)"
  ↓
Line 269: New-QuickUpgradeSchedule
  ↓
Line 295: Write-Log "Successfully scheduled upgrade"
Line 297: $script:SchedulingComplete = $true  ← FLAG SET HERE!
Line 299: $configShowBalloonNotifications = $false
  ↓
[PROBLEM: Code continues instead of exiting!]
  ↓
Line 478: If (-not $script:SchedulingComplete) {  ← STILL EXECUTES!
  ↓
Line 629: ERROR: Installation region reached  ← SAFETY CHECK CATCHES IT
```

## 🎯 DESIRED FLOW

```
START
  ↓
Line 125: Write-Log "Starting deployment"
  ↓
Line 128: $script:SchedulingComplete = $false
  ↓
[... same as above until ...]
  ↓
Line 295: Write-Log "Successfully scheduled upgrade"
Line 297: $script:SchedulingComplete = $true
Line 299: $configShowBalloonNotifications = $false
  ↓
Line 300: Exit-Script -ExitCode 3010  ← ADD THIS!
  ↓
END (Clean exit with code 3010)
```

## 🔍 KEY DECISION POINTS

### 1. After Scheduling (Multiple Locations!)

**Location 1 - Line 297** (Info Dialog → Schedule → Calendar)
```powershell
Write-Log "Successfully scheduled upgrade"
$script:SchedulingComplete = $true
$configShowBalloonNotifications = $false
# MISSING: Exit-Script -ExitCode 3010
```

**Location 2 - Line 332** (Custom DateTime)
```powershell
Write-Log "Successfully scheduled upgrade for $scheduleDate"
$script:SchedulingComplete = $true
$configShowBalloonNotifications = $false
# MISSING: Exit-Script -ExitCode 3010
```

**Location 3 - Line 200** (Keep Existing Schedule)
```powershell
Write-Log "User kept existing schedule"
$script:SchedulingComplete = $true
$configShowBalloonNotifications = $false
# MISSING: Exit-Script -ExitCode 3010
```

**Location 4 - Line 211** (Cancel Schedule)
```powershell
Write-Log "User cancelled schedule"
Remove-UpgradeSchedule -Force
$script:SchedulingComplete = $true
$configShowBalloonNotifications = $false
# MISSING: Exit-Script -ExitCode 3010
```

### 2. The Problematic Check (Line 478)

```powershell
# This is where the Installation region starts
If (-not $script:SchedulingComplete) {
    # ALL THE INSTALLATION CODE
    # Including the safety check at line 629
}
```

## 📊 SCOPE ANALYSIS

### Current Nesting Level at Key Points:

```
Line 297 (Setting flag): 
Try {                           # Level 1
  If ($deploymentType -ieq)     # Level 2
    If ($DeployMode -ne)        # Level 3
      If (Show-UpgradeInfo)     # Level 4
        ElseIf ($result -eq)    # Level 5
          If (Show-Calendar)    # Level 6
            If ($date -match)   # Level 7
              Try {             # Level 8
                ← WE ARE HERE (8 levels deep!)

Line 478 (Problem check):
Try {                           # Level 1
  If ($deploymentType -ieq)     # Level 2
    ← WE ARE HERE (only 2 levels deep!)
```

## 🛠️ FIX STRATEGIES

### Strategy 1: Exit at Each Scheduling Point
Add `Exit-Script -ExitCode 3010` after EACH location where `$script:SchedulingComplete = $true`

### Strategy 2: Central Exit Check
Add this before line 478:
```powershell
# Central scheduling check
If ($script:SchedulingComplete) {
    Write-Log "Installation skipped - upgrade was scheduled"
    Exit-Script -ExitCode 3010
}
```

### Strategy 3: Restructure the Flow
Move the entire Installation region into an Else block:
```powershell
If ($script:SchedulingComplete) {
    Write-Log "Scheduling complete, exiting"
    Exit-Script -ExitCode 3010
}
Else {
    # All installation code here
}
```

## 🎪 THE BIG PICTURE

The script is like a waterfall - once it starts flowing, it continues until it hits an exit. Currently, after scheduling, there's no dam (Exit-Script) to stop the flow, so it continues all the way to the Installation region check at line 478.

The safety check at line 629 is like a safety net, but we shouldn't need it if we properly exit after scheduling!