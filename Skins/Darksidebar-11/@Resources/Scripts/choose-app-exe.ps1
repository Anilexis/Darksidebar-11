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
        public IntPtr hwndOwner = IntPtr.Zero;
        public IntPtr hInstance = IntPtr.Zero;
        public string lpstrFilter;
        public string lpstrCustomFilter;
        public int nMaxCustFilter;
        public int nFilterIndex = 1;
        public IntPtr lpstrFile;
        public int nMaxFile = 1024;
        public IntPtr lpstrFileTitle;
        public int nMaxFileTitle = 1024;
        public string lpstrInitialDir;
        public string lpstrTitle;
        public int Flags = 0x00080000 | 0x00001000 | 0x00000800 | 0x00000008; // OFN_EXPLORER | OFN_FILEMUSTEXIST | OFN_PATHMUSTEXIST | OFN_NOCHANGEDIR
        public short nFileOffset;
        public short nFileExtension;
        public string lpstrDefExt = "exe";
        public IntPtr lCustData = IntPtr.Zero;
        public IntPtr lpfnHook = IntPtr.Zero;
        public string lpTemplateName = null;
        public IntPtr pvReserved = IntPtr.Zero;
        public int dwReserved = 0;
        public int FlagsEx = 0;
    }

    public static string Pick(string title) {
        IntPtr pFile = Marshal.AllocHGlobal(2048 * sizeof(char));
        IntPtr pTitle = Marshal.AllocHGlobal(2048 * sizeof(char));
        Marshal.Copy(new char[2048], 0, pFile, 2048);
        Marshal.Copy(new char[2048], 0, pTitle, 2048);
        try {
            OPENFILENAME ofn = new OPENFILENAME();
            ofn.hwndOwner = GetForegroundWindow();
            ofn.lpstrFilter = "Applications (*.exe)\0*.exe\0All Files (*.*)\0*.*\0";
            ofn.lpstrFile = pFile;
            ofn.nMaxFile = 2048;
            ofn.lpstrFileTitle = pTitle;
            ofn.nMaxFileTitle = 2048;
            ofn.lpstrTitle = title;
            ofn.lpstrInitialDir = Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles);
            if (GetOpenFileName(ofn)) {
                return Marshal.PtrToStringAuto(pFile);
            }
            return null;
        } finally {
            Marshal.FreeHGlobal(pFile);
            Marshal.FreeHGlobal(pTitle);
        }
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
    $selectedPath = $selectedPath.Trim()
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

        # Mirror to persistent external storage
        $persistentDir = "$env:APPDATA\Rainmeter\Darksidebar11-Config"
        if (-not (Test-Path $persistentDir)) { New-Item -ItemType Directory -Path $persistentDir -Force | Out-Null }
        Copy-Item $settingsPath (Join-Path $persistentDir "Settings.inc") -Force

        # Refresh skins to reflect changes
        $rmExe = 'C:\Program Files\Rainmeter\Rainmeter.exe'
        if (-not (Test-Path $rmExe)) { $rmExe = 'C:\Program Files (x86)\Rainmeter\Rainmeter.exe' }
        if (Test-Path $rmExe) {
            & $rmExe !Refresh "Darksidebar-11\Sidebar"
            & $rmExe !Refresh "Darksidebar-11\Settings"
        }
    }
}
