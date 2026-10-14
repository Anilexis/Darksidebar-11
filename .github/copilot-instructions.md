# Copilot / AI Assistant Instructions for Darksidebar-11

Always follow the instructions defined in `PROJECT_RULES.md`:
1. Use Semantic Versioning on any changes.
2. Build rmskin release package via `build-package.ps1`.
3. Compute SHA256 of the generated `.rmskin` and update `bucket/darksidebar-11.json` (version, URL, hash).
4. Commit, tag with `v<VERSION>`, push to git and GitHub (`main` + tag), and verify GitHub release.
5. All Rainmeter skin and include files (.ini, .inc) containing Cyrillic must be encoded in Windows-1251 (CP1251). Never use UTF-8 as it causes mojibake (e.g. РўСЋРјРµРЅСЊ instead of Тюмень) in Rainmeter's ANSI engine.
6. Weather location default is Tyumen (RU) and must not be overwritten by IP geolocation unexpectedly.
