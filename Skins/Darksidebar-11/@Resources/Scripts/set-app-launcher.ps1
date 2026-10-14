# set-app-launcher.ps1
# Переключение режима запуска приложений (None, System, Custom) без терминала
param(
    [string]$Target = "Calendar", # "Calendar" or "Weather"
    [string]$Type = "None"        # "None", "System"
)

$scriptsDir = $PSScriptRoot
$resourcesDir = Split-Path $scriptsDir
$settingsPath = Join-Path $resourcesDir "Settings.inc"

if (-not (Test-Path $settingsPath)) { exit }

$cp1251 = [System.Text.Encoding]::GetEncoding(1251)
$content = [System.IO.File]::ReadAllText($settingsPath, $cp1251)

if ($Target -eq "Calendar") {
    if ($content -match '(?m)^CalendarAppType=.*$') {
        $content = $content -replace '(?m)^CalendarAppType=.*$', "CalendarAppType=$Type"
    } else {
        $content += "`nCalendarAppType=$Type"
    }

    if ($Type -eq "None") {
        $action = 'CalendarAction='
        $cursor = 'CalendarCursor=0'
        $tip = 'CalendarToolTip='
    } else {
        $action = 'CalendarAction=["outlookcal:"]'
        $cursor = 'CalendarCursor=2'
        $tip = 'CalendarToolTip=#LangOpenCalendar#'
    }

    if ($content -match '(?m)^CalendarAction=.*$') {
        $content = $content -replace '(?m)^CalendarAction=.*$', $action
    } else {
        $content += "`n$action"
    }
    if ($content -match '(?m)^CalendarCursor=.*$') {
        $content = $content -replace '(?m)^CalendarCursor=.*$', $cursor
    } else {
        $content += "`n$cursor"
    }
    if ($content -match '(?m)^CalendarToolTip=.*$') {
        $content = $content -replace '(?m)^CalendarToolTip=.*$', $tip
    } else {
        $content += "`n$tip"
    }
} else {
    if ($content -match '(?m)^WeatherAppType=.*$') {
        $content = $content -replace '(?m)^WeatherAppType=.*$', "WeatherAppType=$Type"
    } else {
        $content += "`nWeatherAppType=$Type"
    }

    if ($Type -eq "None") {
        $action = 'WeatherAction='
        $cursor = 'WeatherCursor=0'
        $tip = 'WeatherToolTip='
    } else {
        $action = 'WeatherAction=["msnweather:"]'
        $cursor = 'WeatherCursor=2'
        $tip = 'WeatherToolTip=#LangOpenWeather#'
    }

    if ($content -match '(?m)^WeatherAction=.*$') {
        $content = $content -replace '(?m)^WeatherAction=.*$', $action
    } else {
        $content += "`n$action"
    }
    if ($content -match '(?m)^WeatherCursor=.*$') {
        $content = $content -replace '(?m)^WeatherCursor=.*$', $cursor
    } else {
        $content += "`n$cursor"
    }
    if ($content -match '(?m)^WeatherToolTip=.*$') {
        $content = $content -replace '(?m)^WeatherToolTip=.*$', $tip
    } else {
        $content += "`n$tip"
    }
}

[System.IO.File]::WriteAllText($settingsPath, $content, $cp1251)

# Mirror to persistent external storage
$persistentDir = "$env:APPDATA\Rainmeter\Darksidebar11-Config"
if (-not (Test-Path $persistentDir)) { New-Item -ItemType Directory -Path $persistentDir -Force | Out-Null }
Copy-Item $settingsPath (Join-Path $persistentDir "Settings.inc") -Force

# Refresh skins
$rainmeterExe = "C:\Program Files\Rainmeter\Rainmeter.exe"
if (Test-Path $rainmeterExe) {
    & $rainmeterExe !Refresh "Darksidebar-11\Sidebar"
    & $rainmeterExe !Refresh "Darksidebar-11\Settings"
}
