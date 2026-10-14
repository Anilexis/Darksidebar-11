# Copilot / AI Assistant Instructions for Darksidebar-11

Always follow the instructions defined in `PROJECT_RULES.md`:
1. Use Semantic Versioning on any changes.
2. Build rmskin release package via `build-package.ps1`.
3. Compute SHA256 of the generated `.rmskin` and update `bucket/darksidebar-11.json` (version, URL, hash).
4. Commit, tag with `v<VERSION>`, push to git and GitHub (`main` + tag), and create GitHub release.
5. Rainmeter skin and include files must be saved with UTF-8 BOM (`utf-8-sig` / `UTF8Encoding($true)`). Never use CP1251 or UTF-8 without BOM.
6. Weather location default is Tyumen (RU) and must not be overwritten by IP geolocation unexpectedly.
