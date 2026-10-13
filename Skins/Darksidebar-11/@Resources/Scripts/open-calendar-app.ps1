# open-calendar-app.ps1
$scriptsDir = $PSScriptRoot
$resourcesDir = Split-Path $scriptsDir
$settingsPath = Join-Path $resourcesDir "Settings.inc"

$appType = "System"
$appPath = ""

if (Test-Path $settingsPath) {
    try {
        $cp1251 = [System.Text.Encoding]::GetEncoding(1251)
        $lines = [System.IO.File]::ReadAllLines($settingsPath, $cp1251)
        foreach ($line in $lines) {
            if ($line -match '^\s*CalendarAppType\s*=\s*(.*?)\s*$') { $appType = $Matches[1].Trim() }
            if ($line -match '^\s*CalendarAppPath\s*=\s*(.*?)\s*$') { $appPath = $Matches[1].Trim() }
            if ($line -match '^\s*CalendarApp\s*=\s*(.*?)\s*$') {
                if ($Matches[1].Trim() -match 'Any\.do') {
                    $appType = "Custom"
                    $appPath = "Any.do"
                }
            }
        }
    } catch { }
}

if ($appType -eq "None") {
    # Disabled, do nothing
    exit
} elseif ($appType -eq "System") {
    try {
        Start-Process "outlookcal:" -ErrorAction Stop
    } catch {
        try {
            Start-Process "ms-clock:" -ErrorAction Stop
        } catch {
            Start-Process "control.exe" "timedate.cpl"
        }
    }
} elseif ($appType -eq "Custom") {
    if ($appPath -and (Test-Path $appPath)) {
        Start-Process $appPath
    } elseif ($appPath -match "Any\.do") {
        $anydoScript = Join-Path $scriptsDir "open-anydo.ps1"
        if (Test-Path $anydoScript) {
            & pwsh -File $anydoScript -ErrorAction SilentlyContinue
            if ($LASTEXITCODE -ne 0) {
                & powershell -NoProfile -File $anydoScript -ErrorAction SilentlyContinue
            }
        } else {
            Start-Process "https://app.any.do/calendar"
        }
    } else {
        try { Start-Process "outlookcal:" } catch { }
    }
}
