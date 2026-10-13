# choose-app-exe.ps1
# Интерактивный выбор исполняемого файла (.exe) для клика по календарю или погоде
param(
    [string]$Target = "Calendar"
)

$scriptsDir = $PSScriptRoot
$resourcesDir = Split-Path $scriptsDir
$settingsPath = Join-Path $resourcesDir "Settings.inc"

if (-not (Test-Path $settingsPath)) { exit }

$csharp = @'
using System;
using System.Runtime.InteropServices;

public class NativePicker {
    [DllImport("user32.dll")]
    public static extern IntPtr GetForegroundWindow();

    [DllImport("comdlg32.dll", SetLastError = true, CharSet = CharSet.Auto)]
    public static extern bool GetOpenFileName([In, Out] OPENFILENAME ofn);

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Auto)]
    public class OPENFILENAME {
        public int lStructSize = Marshal.SizeOf(typeof(OPENFILENAME));
        public IntPtr hwndOwner;
        public IntPtr hInstance;
        public string lpstrFilter;
        public string lpstrCustomFilter;
        public int nMaxCustFilter;
        public int nFilterIndex;
        public string lpstrFile;
        public int nMaxFile = 260;
        public string lpstrFileTitle;
        public int nMaxFileTitle = 260;
        public string lpstrInitialDir;
        public string lpstrTitle;
        public int Flags = 0x00080000 | 0x00001000 | 0x00000800 | 0x00000008; // OFN_EXPLORER | OFN_FILEMUSTEXIST | OFN_PATHMUSTEXIST | OFN_NOCHANGEDIR
        public short nFileOffset;
        public short nFileExtension;
        public string lpstrDefExt = "exe";
        public IntPtr lCustData;
        public IntPtr lpfnHook;
        public string lpTemplateName;
        public IntPtr pvReserved;
        public int dwReserved;
        public int FlagsEx;
    }

    public static string Pick(string title) {
        OPENFILENAME ofn = new OPENFILENAME();
        ofn.hwndOwner = GetForegroundWindow();
        ofn.lpstrFilter = "Applications (*.exe)\0*.exe\0All Files (*.*)\0*.*\0";
        ofn.lpstrFile = new string(new char[260]);
        ofn.lpstrFileTitle = new string(new char[260]);
        ofn.lpstrTitle = title;
        ofn.lpstrInitialDir = Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles);
        if (GetOpenFileName(ofn)) {
            return ofn.lpstrFile;
        }
        return null;
    }
}
'@

if (-not ([System.Management.Automation.PSTypeName]'NativePicker').Type) {
    Add-Type -TypeDefinition $csharp
}

$title = if ($Target -eq "Calendar") {
    "Выберите приложение календаря (.exe) / Select Calendar App"
} else {
    "Выберите приложение погоды (.exe) / Select Weather App"
}

$selectedPath = [NativePicker]::Pick($title)

if ($selectedPath) {
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

    # Refresh skins to reflect changes
    $rmExe = @"C:\Program Files\Rainmeter\Rainmeter.exe"
    if (-not (Test-Path $rmExe)) { $rmExe = @"C:\Program Files (x86)\Rainmeter\Rainmeter.exe" }
    if (Test-Path $rmExe) {
        Start-Process $rmExe "!Refresh Darksidebar-11\Sidebar"
        Start-Process $rmExe "!Refresh Darksidebar-11\Settings"
    }
}
