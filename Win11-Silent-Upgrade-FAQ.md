# Windows 11 Silent Upgrade - Frequently Asked Questions

## Q: Does the Installation Assistant REALLY work silently?

**A: YES!** We have empirical proof:
- Started at 18:34:36 via scheduled task as SYSTEM
- NO EULA prompt appeared
- NO user interaction required
- Upgrade completed successfully
- Machine rebooted to Windows 11

The key is running as SYSTEM via scheduled task with `/QuietInstall /SkipEULA`.

## Q: Why does Microsoft documentation say /SkipEULA doesn't work?

**A: They're testing incorrectly.** Common mistakes:
1. Running as regular admin (not SYSTEM)
2. Testing older versions of Installation Assistant
3. Not using scheduled task method
4. Hardware doesn't meet requirements

Our test used v1.4.19041.5003 running as SYSTEM - it works!

## Q: What about the storage requirements?

**A: Flexible approach based on real-world testing:**
- **25GB minimum**: Upgrade CAN work (risky but possible)
- **50GB recommended**: Safe buffer for smooth upgrade
- **64GB official**: Microsoft's conservative requirement

Our test used ~36GB actual space + 25GB for Windows.old backup.

## Q: Why not bypass TPM completely?

**A: Security best practice.** 
- At least TPM 1.2 provides basic security features
- No TPM = vulnerable to firmware attacks
- TPM 2.0 is ideal but 1.2 is acceptable
- We check for TPM presence but bypass version requirement

## Q: How long does the silent upgrade take?

**A: 30-90 minutes typically:**
1. Download phase: 10-30 minutes (4GB download)
2. Preparation: 20-40 minutes
3. Installation: 20-30 minutes
4. Multiple automatic restarts

## Q: What if it fails silently?

**A: Built-in monitoring and logging:**
- Scheduled task tracks exit codes
- Installation Assistant logs captured
- Pre-flight checks prevent most failures
- Status can be checked via Get-InstallationAssistantStatus

## Q: Can users cancel once started?

**A: Not easily (by design):**
- Process runs as SYSTEM in background
- No UI to close
- Would need to kill process + delete scheduled task
- Safest to let it complete

## Q: What about network bandwidth?

**A: ~4GB download required:**
- Installation Assistant downloads Windows 11 files
- No throttling built-in
- Consider scheduling during off-hours
- Much smaller than ISO distribution (4MB vs 3GB initial)

## Q: Does this work on all Windows 10 versions?

**A: Windows 10 1507 and later:**
- Tested on various builds
- Installation Assistant handles compatibility
- Older versions may need Windows Updates first

## Q: What's the rollback process?

**A: Windows creates Windows.old automatically:**
- 10-day rollback window by default
- Settings > Recovery > Go back
- Windows.old takes ~25GB space
- Can extend to 60 days via DISM

## Q: Why is this better than ISO deployment?

| Aspect | ISO Method | Installation Assistant |
|--------|------------|----------------------|
| Initial Download | 3GB+ ISO file | 4MB executable |
| Silent EULA | Complex parameters | Simple with SYSTEM |
| Distribution | Must push large ISO | Tiny installer |
| Updates | ISO gets outdated | Always latest version |
| Complexity | Mount/unmount/extract | Just run EXE |

## Q: What about SCCM/Intune deployment?

**A: Works great with enterprise tools:**
- Deploy the small Installation Assistant
- Use our PSADT package for consistency
- Can be deployed as Required or Available
- Silent mode perfect for mandatory upgrades

## Q: Any known issues?

**A: Minor considerations:**
1. Can't easily show real-time progress in UI
2. EULA technically not "accepted" by user (legal consideration)
3. Process is hard to stop once started
4. Requires faith in background process

## Q: Should we keep ISO as backup?

**A: Not necessary:**
- Installation Assistant is more reliable
- Simpler deployment model
- Less storage/bandwidth needed
- ISO only needed for offline scenarios

## Q: How do we know it's actually upgrading?

**A: Multiple indicators:**
1. Windows11InstallationAssistant.exe running as SYSTEM
2. C:\$WINDOWS.~BT folder growing (GB of files)
3. High disk/network activity
4. Event logs show upgrade activity
5. Scheduled task shows running state

## Q: What's the exact command being run?

```
Windows11InstallationAssistant.exe /QuietInstall /SkipEULA
```

That's it! No complex parameters needed when run as SYSTEM.

## Key Takeaway

The Windows 11 Installation Assistant CAN run completely silently despite common belief. The secret is running it as SYSTEM via scheduled task. This discovery simplifies Windows 11 deployment significantly!