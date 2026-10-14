# Copilot / AI Assistant Instructions for Darksidebar-11

Always follow the instructions defined in `PROJECT_RULES.md`:
1. Use Semantic Versioning on any changes.
2. Build rmskin release package via `build-package.ps1`.
3. Compute SHA256 of the generated `.rmskin` and update `bucket/darksidebar-11.json` (version, URL, hash).
4. Commit, tag with `v<VERSION>`, push to git and GitHub (`main` + tag), and verify GitHub release.
5. Strict Depersonalization: The repository and distribution .rmskin must NEVER contain personal developer data (no personal disks D/E/G/T/W, no SyncMaster/DISPLAY2 monitor, no Tyumen city). They must contain clean distribution defaults (Primary display, single disk C:, London default, FirstRunDone=0).
6. Local developer settings live in `%USERPROFILE%\Documents\Rainmeter\Skins\Darksidebar-11\` and must NOT be overwritten by repo sync or committed.
7. Skin and include files (.ini, .inc) containing Cyrillic must be encoded in Windows-1251 (CP1251). Never use UTF-8.
8. User Settings & Disk Preservation: Updates (Scoop and .rmskin) must NEVER overwrite user Settings.inc or disks. All settings mirror to persistent external storage %APPDATA%\Rainmeter\Darksidebar11-Config. Scoop uninstaller must NEVER delete user skin folder. first-run.ps1 restores from persistent backup if available.


