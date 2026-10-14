# first-run.ps1
# Initial setup on first skin launch
param()

$scriptsDir = $PSScriptRoot
$resourcesDir = Split-Path $scriptsDir
$settingsPath = Join-Path $resourcesDir "Settings.inc"
$defaultSettingsPath = Join-Path $resourcesDir "Settings.default.inc"
$persistentDir = "$env:APPDATA\Rainmeter\Darksidebar11-Config"
$persistentSettings = Join-Path $persistentDir "Settings.inc"

# 0. Check persistent external backup first (preserves user settings across any uninstall/reinstall/update)
if (Test-Path $persistentSettings) {
    try {
        $cp1251 = [System.Text.Encoding]::GetEncoding(1251)
        $persText = [System.IO.File]::ReadAllText($persistentSettings, $cp1251)
        if ($persText -match '(?m)^\s*FirstRunDone\s*=\s*1') {
            # Restore user customized Settings.inc
            Copy-Item $persistentSettings $settingsPath -Force

            # Restore user disk topology caches if present
            $persDisks = Join-Path $persistentDir "disks-generated.inc"
            if (Test-Path $persDisks) {
                Copy-Item $persDisks (Join-Path $resourcesDir "Cache\disks-generated.inc") -Force
            }
            $persVars = Join-Path $persistentDir "disks-vars.inc"
            if (Test-Path $persVars) {
                Copy-Item $persVars (Join-Path $resourcesDir "Cache\disks-vars.inc") -Force
            }

            # Align sidebar to user restored monitor immediately
            $alignSidebar = Join-Path $scriptsDir "align-sidebar.ps1"
            if (Test-Path $alignSidebar) {
                & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $alignSidebar
            }
            return
        }
    } catch { }
}

# If Settings.inc does not exist, copy from default template
if (-not (Test-Path $settingsPath) -and (Test-Path $defaultSettingsPath)) {
    Copy-Item $defaultSettingsPath $settingsPath -Force
}

if (-not (Test-Path $settingsPath)) {
    return
}

$cp1251 = [System.Text.Encoding]::GetEncoding(1251)
$content = [System.IO.File]::ReadAllText($settingsPath, $cp1251)

# CRITICAL GUARD: If FirstRunDone is already 1, user has already configured the skin!
# DO NOT reset user location, city, language, coordinates or disks!
if ($content -match "(?m)^\s*FirstRunDone\s*=\s*1") {
    if (-not (Test-Path $persistentDir)) { New-Item -ItemType Directory -Path $persistentDir -Force | Out-Null }
    Copy-Item $settingsPath $persistentSettings -Force

    $disksInc = Join-Path $resourcesDir "Cache\disks-generated.inc"
    if (-not (Test-Path $disksInc)) {
        $updateDisks = Join-Path $scriptsDir "update-disks.ps1"
        if (Test-Path $updateDisks) {
            & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $updateDisks
        }
    }
    return
}

# 1. Detect language by Windows Culture
$isRu = $false
try {
    if ((Get-Culture).TwoLetterISOLanguageName -eq "ru" -or (Get-UICulture).TwoLetterISOLanguageName -eq "ru") {
        $isRu = $true
    }
} catch { }

$lang = if ($isRu) { "Russian" } else { "English" }
$firstDay = if ($isRu) { "Monday" } else { "Sunday" }

$content = $content -replace "(?m)^Language=.*$", "Language=$lang"
$content = $content -replace "(?m)^CalendarFirstDay=.*$", "CalendarFirstDay=$firstDay"
$content = $content -replace "(?m)^FirstRunDone=.*$", "FirstRunDone=1"
[System.IO.File]::WriteAllText($settingsPath, $content, $cp1251)

# 2. Update storage disks topology
$updateDisks = Join-Path $scriptsDir "update-disks.ps1"
if (Test-Path $updateDisks) {
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $updateDisks
}

# 3. Detect IP & weather coordinates
$detectIp = Join-Path $scriptsDir "detect-weather-ip.ps1"
if (Test-Path $detectIp) {
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $detectIp
}

# 4. Align sidebar
$alignSidebar = Join-Path $scriptsDir "align-sidebar.ps1"
if (Test-Path $alignSidebar) {
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $alignSidebar
}

# 5. Mirror to persistent external backup
if (-not (Test-Path $persistentDir)) { New-Item -ItemType Directory -Path $persistentDir -Force | Out-Null }
Copy-Item $settingsPath $persistentSettings -Force
$curDisks = Join-Path $resourcesDir "Cache\disks-generated.inc"
if (Test-Path $curDisks) { Copy-Item $curDisks (Join-Path $persistentDir "disks-generated.inc") -Force }
$curVars = Join-Path $resourcesDir "Cache\disks-vars.inc"
if (Test-Path $curVars) { Copy-Item $curVars (Join-Path $persistentDir "disks-vars.inc") -Force }