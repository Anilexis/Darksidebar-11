# first-run.ps1
# Initial setup on first skin launch
param()

$scriptsDir = $PSScriptRoot
$resourcesDir = Split-Path $scriptsDir
$settingsPath = Join-Path $resourcesDir "Settings.inc"

if (Test-Path $settingsPath) {
    $cp1251 = [System.Text.Encoding]::GetEncoding(1251)
    $content = [System.IO.File]::ReadAllText($settingsPath, $cp1251)

    # 1. Detect language by Windows Culture
    $isRu = $false
    try {
        if ((Get-Culture).TwoLetterISOLanguageName -eq "ru" -or (Get-UICulture).TwoLetterISOLanguageName -eq "ru") {
            $isRu = $true
        }
    } catch { }

    $lang = if ($isRu) { "Russian" } else { "English" }
    $firstDay = if ($isRu) { "Monday" } else { "Sunday" }

    $content = $content -replace '(?m)^Language=.*$', "Language=$lang"
    $content = $content -replace '(?m)^CalendarFirstDay=.*$', "CalendarFirstDay=$firstDay"
    $content = $content -replace '(?m)^FirstRunDone=.*$', "FirstRunDone=1"
    [System.IO.File]::WriteAllText($settingsPath, $content, $cp1251)
}

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

# 5. Refresh Rainmeter
$rmExe = "C:\Program Files\Rainmeter\Rainmeter.exe"
if (Test-Path $rmExe) {
    & $rmExe !Refresh "Darksidebar-11\Sidebar"
}
