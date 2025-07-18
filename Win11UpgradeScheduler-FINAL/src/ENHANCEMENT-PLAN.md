# Windows 11 Upgrade Scheduler Enhancement Plan

## Overview
This document outlines the planned enhancements to the Windows 11 Upgrade Scheduler, focusing on improving pre-flight checks and handling edge cases.

## Current State
- **Branch**: `feature/visual-countdown-integration`
- **Status**: Visual countdown timer successfully integrated and working
- **Key Achievement**: Fixed Execute-ProcessAsUser hanging issue with inline countdown code

## Enhancement Phases

### Phase 1: Windows Version Check (Branch: `feature/windows-version-check`)
**Objective**: Add detection for Windows 10 minimum version requirement

**Requirements**:
- Windows 11 requires Windows 10 version 2004 (build 19041) or later
- Current Windows 10 version 22H2 is build 19045

**Implementation**:
1. Add version check to pre-flight checks module
2. Detect if running Windows 10 build < 19041
3. Log as WARNING (not error) in logs and console
4. Allow process to continue - let Windows 11 Installation Assistant make final decision
5. No attempt to update Windows 10 (out of scope - handled by patch policies)

**Code Location**: `SupportFiles\Modules\02-PreFlightChecks.psm1`

---

### Phase 2: Existing Upgrade Detection (Branch: `feature/existing-upgrade-detection`)
**Objective**: Detect and handle existing Windows upgrade processes

**Processes to Check**:
- `Windows11InstallationAssistant.exe` (transient, spawns child then exits)
- `Windows10Upgrade.exe` (persistent during upgrade, child of above)
- `SetupHost.exe` (Windows setup process)
- `Setup.exe` (generic setup process)

**Implementation**:
1. Add process check to pre-flight checks
2. If found, use Execute-ProcessAsUser to show prompt (SYSTEM context consideration)
3. Offer options:
   - Kill existing and restart fresh
   - Cancel current operation
4. Log decision and proceed accordingly

**Code Location**: `SupportFiles\Modules\02-PreFlightChecks.psm1`

---

### Phase 3: Code Optimization (Branch: `feature/code-cleanup`) - LATER
**Objective**: Remove redundant code and optimize flow

**Areas to Address**:
- Duplicate scheduling checks in Deploy-Application.ps1
- Calendar picker wrapper redundancy (lines 115-120)
- Simplify parameter passing between wrapper and main script
- Remove dead code blocks

**Note**: This is lower priority and can be done after core functionality is stable

---

## Implementation Guidelines

### Branch Management
1. Each phase gets its own feature branch
2. Branch from current `feature/visual-countdown-integration`
3. Test thoroughly before merging
4. Document changes in commit messages

### Testing Requirements
1. Test on systems with various Windows 10 versions
2. Test with existing upgrade processes running
3. Test in both user and SYSTEM contexts
4. Verify Execute-ProcessAsUser prompts work correctly

### Key Constraints
- Must work in SYSTEM context (scheduled task)
- Must use Execute-ProcessAsUser for any UI elements
- Soft warnings only - don't block on version checks
- Let Windows 11 Installation Assistant be the final arbiter

---

## Version Reference

| Windows 10 Version | Build Number | Release Date | Status |
|-------------------|--------------|--------------|---------|
| 1909 | 18363 | Nov 2019 | Below minimum |
| 2004 | 19041 | May 2020 | **Minimum required** |
| 20H2 | 19042 | Oct 2020 | Supported |
| 21H1 | 19043 | May 2021 | Supported |
| 21H2 | 19044 | Nov 2021 | Supported |
| 22H2 | 19045 | Oct 2022 | Current |

---

## Decision Log

1. **Windows Version Check**: Soft warning only, proceed anyway
   - Rationale: Let Installation Assistant handle compatibility
   - No auto-update attempts (handled by patch policies)

2. **Process Detection**: Interactive prompt with kill option
   - Rationale: User should decide on existing upgrades
   - Must handle SYSTEM context properly

3. **Code Cleanup**: Deferred to later phase
   - Rationale: Stability first, optimization later

---

## Next Steps

1. Commit current changes on `feature/visual-countdown-integration`
2. Create `feature/windows-version-check` branch
3. Implement Phase 1
4. Test and iterate
5. Repeat for subsequent phases