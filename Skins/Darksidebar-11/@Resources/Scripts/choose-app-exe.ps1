# choose-app-exe.ps1
# Интерактивный выбор исполняемого файла (.exe) для клика по календарю или погоде
param(
    [string]$Target = "Calendar"
)

$scriptsDir = $PSScriptRoot
$resourcesDir = Split-Path $scriptsDir
$settingsPath = Join-Path $resourcesDir "Settings.inc"

if (-not (Test-Path $settingsPath)) { exit }

Add-Type -AssemblyName System.Windows.Forms

$dialog = New-Object System.Windows.Forms.OpenFileDialog
if ($Target -eq "Calendar") {
    $dialog.Title = "Выберите приложение календаря (.exe) / Select Calendar App"
} else {
    $dialog.Title = "Выберите приложение погоды (.exe) / Select Weather App"
}
$dialog.Filter = "Исполняемые файлы (*.exe)|*.exe|Все файлы (*.*)|*.*"
$dialog.InitialDirectory = [Environment]::GetFolderPath("ProgramFiles")
$dialog.CheckFileExists = $true

# Ensure file picker window appears in front
$form = New-Object System.Windows.Forms.Form
$form.TopMost = $true
$form.WindowState = [System.Windows.Forms.FormWindowState]::Minimized
$form.Show()
$form.Visible = $false

$result = $dialog.ShowDialog($form)
$form.Dispose()

if ($result -eq [System.Windows.Forms.DialogResult]::OK -and $dialog.FileName) {
    $selectedPath = $dialog.FileName
    $cp1251 = [System.Text.Encoding]::GetEncoding(1251)
    $content = [System.IO.File]::ReadAllText($settingsPath, $cp1251)

    if ($Target -eq "Calendar") {
        if ($content -match '(?m)^CalendarAppType=.*$') {
            $content = $content -replace '(?m)^CalendarAppType=.*$', "CalendarAppType=Custom"
        } else {
            $content += "`nCalendarAppType=Custom"
        }
        if ($content -match '(?m)^CalendarAppPath=.*$') {
            $content = $content -replace '(?m)^CalendarAppPath=.*$', "CalendarAppPath=$selectedPath"
        } else {
            $content += "`nCalendarAppPath=$selectedPath"
        }
        if ($content -match '(?m)^CalendarAction=.*$') {
            $content = $content -replace '(?m)^CalendarAction=.*$', "CalendarAction=[`"$selectedPath`"]"
        } else {
            $content += "`nCalendarAction=[`"$selectedPath`"]"
        }
        if ($content -match '(?m)^CalendarCursor=.*$') {
            $content = $content -replace '(?m)^CalendarCursor=.*$', "CalendarCursor=2"
        } else {
            $content += "`nCalendarCursor=2"
        }
        if ($content -match '(?m)^CalendarToolTip=.*$') {
            $content = $content -replace '(?m)^CalendarToolTip=.*$', 'CalendarToolTip=#LangOpenCalendar#'
        } else {
            $content += "`nCalendarToolTip=#LangOpenCalendar#"
        }
    } else {
        if ($content -match '(?m)^WeatherAppType=.*$') {
            $content = $content -replace '(?m)^WeatherAppType=.*$', "WeatherAppType=Custom"
        } else {
            $content += "`nWeatherAppType=Custom"
        }
        if ($content -match '(?m)^WeatherAppPath=.*$') {
            $content = $content -replace '(?m)^WeatherAppPath=.*$', "WeatherAppPath=$selectedPath"
        } else {
            $content += "`nWeatherAppPath=$selectedPath"
        }
        if ($content -match '(?m)^WeatherAction=.*$') {
            $content = $content -replace '(?m)^WeatherAction=.*$', "WeatherAction=[`"$selectedPath`"]"
        } else {
            $content += "`nWeatherAction=[`"$selectedPath`"]"
        }
        if ($content -match '(?m)^WeatherCursor=.*$') {
            $content = $content -replace '(?m)^WeatherCursor=.*$', "WeatherCursor=2"
        } else {
            $content += "`nWeatherCursor=2"
        }
        if ($content -match '(?m)^WeatherToolTip=.*$') {
            $content = $content -replace '(?m)^WeatherToolTip=.*$', 'WeatherToolTip=#LangOpenWeather#'
        } else {
            $content += "`nWeatherToolTip=#LangOpenWeather#"
        }
    }

    [System.IO.File]::WriteAllText($settingsPath, $content, $cp1251)

    # Refresh skins
    $rainmeterExe = "C:\Program Files\Rainmeter\Rainmeter.exe"
    if (Test-Path $rainmeterExe) {
        & $rainmeterExe !Refresh "Darksidebar-11\Sidebar"
        & $rainmeterExe !Refresh "Darksidebar-11\Settings"
    }
}
