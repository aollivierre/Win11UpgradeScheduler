# Project Organization Task - Windows 11 Upgrade Scheduler

## CRITICAL INSTRUCTION
You are tasked with organizing a messy project folder structure. **NEVER DELETE ANY FILES** - only move, rename, and organize them into a clean structure.

## Current Situation
The `C:\code\Windows\` directory contains multiple files and folders related to a Windows 11 Upgrade Scheduler project built with PowerShell App Deployment Toolkit (PSADT) v3. Files are scattered across various locations and need proper organization.

## Project Scope
**ONLY organize files related to:**
- Windows 11 Upgrade Scheduler with PSADT v3
- Enhanced scheduling features (Tonight options, calendar picker)
- Pre-flight checks and validation
- Testing and demonstration scripts
- Related documentation

**DO NOT TOUCH:**
- `Phase1-Detection\` folder (managed by another agent)
- `Phase2-Upgrade\` folder (if exists)
- Any files explicitly marked as "detection phase"

## Target Directory Structure
Create this organized structure under `C:\code\Windows\Win11UpgradeScheduler-FINAL\`:

```
Win11UpgradeScheduler-FINAL/
├── src/                                    # Production-ready code
│   ├── Deploy-Application.ps1              # Main PSADT deployment script
│   ├── AppDeployToolkit/                   # PSADT v3.10.2 framework files
│   │   ├── AppDeployToolkitMain.ps1
│   │   ├── AppDeployToolkitExtensions.ps1
│   │   └── [other PSADT files]
│   ├── SupportFiles/
│   │   ├── Modules/
│   │   │   ├── 01-UpgradeScheduler.psm1    # Core scheduling module
│   │   │   └── 02-PreFlightChecks.psm1     # System validation module
│   │   ├── UI/
│   │   │   ├── 01-Show-EnhancedCalendarPicker.ps1
│   │   │   ├── 02-Show-UpgradeInformationDialog.ps1
│   │   │   └── 03-Show-CalendarPicker-Original.ps1
│   │   └── ScheduledTaskWrapper.ps1
│   └── Files/                              # Windows 11 installation media
├── docs/
│   ├── 01-Requirements/
│   │   └── [requirement documents]
│   ├── 02-Design/
│   │   └── [design documents]
│   ├── 03-Implementation/
│   │   ├── README-Implementation.md
│   │   └── IMPLEMENTATION_SUMMARY.md
│   ├── 04-Testing/
│   │   └── VALIDATION_RESULTS.md
│   └── 05-Deployment/
│       └── DEPLOYMENT-GUIDE.md
├── tests/
│   ├── 01-Unit-Tests/
│   │   └── [individual component tests]
│   ├── 02-Integration-Tests/
│   │   └── [module integration tests]
│   ├── 03-System-Tests/
│   │   └── [full system validation]
│   └── Test-Results/
│       └── [test execution results]
├── demos/
│   ├── 01-Quick-Start/
│   │   └── Demo-QuickStart.ps1
│   ├── 02-Components/
│   │   ├── Demo-CalendarPicker.ps1
│   │   ├── Demo-PreFlightChecks.ps1
│   │   └── Demo-Scheduling.ps1
│   └── 03-Full-Workflow/
│       └── Demo-Complete-Workflow.ps1
├── tools/
│   ├── deployment/
│   │   └── [deployment utilities]
│   └── development/
│       └── [development helpers]
├── archive/
│   ├── iterations/
│   │   ├── v1-initial/
│   │   ├── v2-enhanced/
│   │   └── [version folders]
│   ├── temp-work/
│   │   └── [temporary files]
│   └── reference/
│       └── [reference materials]
├── README.md                               # Main project documentation
├── CHANGELOG.md                            # Version history
├── LICENSE                                 # License file
└── .gitignore                             # Git ignore rules
```

## File Organization Rules

### 1. Source Code (src/)
- **Latest working version only** in main src folder
- Number modules and UI components for load order
- Keep PSADT structure intact
- Preserve all AppDeployToolkit files

### 2. Documentation (docs/)
- Number folders by project phase
- Consolidate duplicate documentation
- Create index files for each section
- Convert any .txt files to .md

### 3. Tests (tests/)
- Separate by test type (unit, integration, system)
- Keep test results in dedicated folder
- Number test files for execution order
- Include test documentation

### 4. Demos (demos/)
- Organize by complexity (quick start → full workflow)
- Ensure all demos are self-contained
- Include demo instructions in each folder

### 5. Archive (archive/)
- Version folders (v1, v2, etc.) for major iterations
- Keep ALL old files - never delete
- Add README in each version folder explaining changes

## Specific Files to Organize

### Production Files (move to src/)
- `Win11UpgradeScheduler/Deploy-Application.ps1`
- `Win11UpgradeScheduler/SupportFiles/Modules/*.psm1`
- `Win11UpgradeScheduler/SupportFiles/Show-EnhancedCalendarPicker.ps1`
- `Win11UpgradeScheduler/SupportFiles/ScheduledTaskWrapper.ps1`
- Any enhanced/final versions of deployment scripts

### Test Files (move to tests/)
- `Test-*.ps1` files
- `Validate-*.ps1` files
- Any files in `/Tests/` folders
- Test result JSON/log files

### Demo Files (move to demos/)
- `Demo-*.ps1` files
- `Show-PreFlightChecks.ps1`
- Individual component demonstrations

### Documentation (move to docs/)
- `*.md` files (except root README.md)
- `IMPLEMENTATION_*.md`
- `VALIDATION_*.md`
- `*_DetailedPrompt.md`

### Archive Files
- Any file with "old", "backup", "temp", or date suffix
- Previous versions of scripts
- Development iterations

## Special Handling Instructions

### 1. Duplicate Files
- Keep the most recent/complete version in src/
- Move older versions to archive/iterations/
- Add version suffix when archiving (e.g., `_v1.ps1`)

### 2. PSADT Files
- Preserve complete PSADT v3.10.2 structure
- Don't modify AppDeployToolkit folder contents
- Keep all PSADT configuration files

### 3. Enhanced vs Original
- Files with "Enhanced" in name go to src/
- Original versions go to archive/reference/
- Maintain clear naming distinction

### 4. Module Dependencies
- Ensure module load order is preserved
- Check `Import-Module` statements
- Update paths if needed after moving

## Validation Checklist
After organization, verify:
- [ ] All files moved, none deleted
- [ ] src/ contains only production-ready code
- [ ] Tests are runnable from new location
- [ ] Documentation is accessible and organized
- [ ] No broken module/script dependencies
- [ ] Archive contains all historical versions
- [ ] Root folder has clear README.md
- [ ] File count before = file count after

## Final Notes
- Create a `MIGRATION_LOG.txt` documenting all moves
- If uncertain about a file's purpose, place in `archive/uncategorized/`
- Maintain PowerShell 5.1 compatibility in all scripts
- Preserve all comments and documentation within files
- Test at least one script from each category after moving

## Example Commands
```powershell
# Create structure
New-Item -ItemType Directory -Path "C:\code\Windows\Win11UpgradeScheduler-FINAL\src\SupportFiles\Modules" -Force

# Move with verification
Move-Item -Path "source\file.ps1" -Destination "dest\file.ps1" -Force -PassThru

# Archive with timestamp
$timestamp = Get-Date -Format "yyyyMMdd"
Copy-Item -Path "file.ps1" -Destination "archive\file_$timestamp.ps1"
```

Remember: The goal is a clean, professional structure that makes the project easy to understand, deploy, and maintain. Every file should have a clear location, and the structure should tell the story of the project.