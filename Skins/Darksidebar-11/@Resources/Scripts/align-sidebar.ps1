# align-sidebar.ps1
# Интеллектуальное позиционирование Darksidebar-11 по аппаратному PnP ID монитора
# Запускается по событию (запуск, смену мониторов, изменение разрешения) и мгновенно завершается (~0.15с).

$csharp = @'
using System;
using System.Runtime.InteropServices;

public class AlignHelper {
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Auto)]
    public struct MONITORINFOEX {
        public int cbSize;
        public RECT rcMonitor;
        public RECT rcWork;
        public uint dwFlags;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)]
        public string szDevice;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct RECT {
        public int left, top, right, bottom;
    }

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Auto)]
    public struct DISPLAY_DEVICE {
        public int cb;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)] public string DeviceName;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 128)] public string DeviceString;
        public int StateFlags;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 128)] public string DeviceID;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 128)] public string DeviceKey;
    }

    public delegate bool MonitorEnumProc(IntPtr hMonitor, IntPtr hdcMonitor, ref RECT lprcMonitor, IntPtr dwData);

    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern bool EnumDisplayMonitors(IntPtr hdc, IntPtr lprcClip, MonitorEnumProc lpfnEnum, IntPtr dwData);

    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern bool GetMonitorInfo(IntPtr hMonitor, ref MONITORINFOEX lpmi);

    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern bool EnumDisplayDevices(string lpDevice, uint iDevNum, ref DISPLAY_DEVICE lpDisplayDevice, uint dwFlags);

    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern IntPtr FindWindow(string lpClassName, string lpWindowName);

    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern IntPtr SendMessage(IntPtr hWnd, uint Msg, IntPtr wParam, ref COPYDATASTRUCT lParam);

    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern IntPtr OpenDesktop(string lpszDesktop, uint dwFlags, bool fInherit, uint dwDesiredAccess);

    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern bool SetThreadDesktop(IntPtr hDesktop);

    [StructLayout(LayoutKind.Sequential)]
    public struct COPYDATASTRUCT {
        public IntPtr dwData;
        public int cbData;
        public IntPtr lpData;
    }

    public static bool SendBang(string bang) {
        try {
            string rmExe = @"C:\Program Files\Rainmeter\Rainmeter.exe";
            if (!System.IO.File.Exists(rmExe)) {
                rmExe = @"C:\Program Files (x86)\Rainmeter\Rainmeter.exe";
            }
            if (System.IO.File.Exists(rmExe)) {
                System.Diagnostics.Process.Start(new System.Diagnostics.ProcessStartInfo {
                    FileName = rmExe,
                    Arguments = bang,
                    UseShellExecute = false,
                    CreateNoWindow = true
                });
                return true;
            }
        } catch { }
        return false;
    }

    public static void AlignSmart(
        string targetPnpId,
        string targetFriendly,
        string fallbackDev,
        int panelWidth,
        int rightMargin,
        int topMargin,
        string placementEdge,
        bool hideWhenMissing
    ) {
        bool found = false;
        int targetX = 0;
        int targetY = 0;
        int workHeight = 976;

        EnumDisplayMonitors(IntPtr.Zero, IntPtr.Zero, (IntPtr hMon, IntPtr hdcMon, ref RECT rc, IntPtr data) => {
            var mi = new MONITORINFOEX();
            mi.cbSize = Marshal.SizeOf(typeof(MONITORINFOEX));
            if (GetMonitorInfo(hMon, ref mi)) {
                string dev = mi.szDevice.Trim();
                int w = mi.rcMonitor.right - mi.rcMonitor.left;
                int h = mi.rcMonitor.bottom - mi.rcMonitor.top;

                // Получаем аппаратный PnP ID дисплея
                string pnpId = "";
                string friendly = "";
                var monDev = new DISPLAY_DEVICE();
                monDev.cb = Marshal.SizeOf(monDev);
                if (EnumDisplayDevices(dev, 0, ref monDev, 0)) {
                    pnpId = (monDev.DeviceID ?? "").Trim();
                    friendly = (monDev.DeviceString ?? "").Trim();
                }

                bool match = false;

                // 1. Точное совпадение по аппаратному PnP ID (Hardware Device ID)
                if (!string.IsNullOrEmpty(targetPnpId)) {
                    if (pnpId.IndexOf(targetPnpId, StringComparison.OrdinalIgnoreCase) >= 0 ||
                        targetPnpId.IndexOf(pnpId, StringComparison.OrdinalIgnoreCase) >= 0) {
                        match = true;
                    }
                }

                // 2. Совпадение по имени модели
                if (!match && !string.IsNullOrEmpty(targetFriendly)) {
                    if (friendly.IndexOf(targetFriendly, StringComparison.OrdinalIgnoreCase) >= 0 ||
                        targetFriendly.IndexOf(friendly, StringComparison.OrdinalIgnoreCase) >= 0) {
                        match = true;
                    }
                }

                // 3. Fallback по имени адаптера (DISPLAY1, DISPLAY2, DISPLAY3)
                if (!match) {
                    if (!string.IsNullOrEmpty(fallbackDev) && dev.Equals(fallbackDev, StringComparison.OrdinalIgnoreCase)) {
                        match = true;
                    }
                }

                if (match) {
                    workHeight = (mi.rcWork.bottom - mi.rcWork.top) - topMargin;
                    if (workHeight < 600) workHeight = 976;

                    if (string.Equals(placementEdge, "Left", StringComparison.OrdinalIgnoreCase)) {
                        targetX = mi.rcWork.left + rightMargin;
                    } else {
                        targetX = mi.rcWork.right - panelWidth - rightMargin;
                    }
                    targetY = mi.rcWork.top + topMargin;
                    found = true;
                    return false;
                }
            }
            return true;
        }, IntPtr.Zero);

        if (found) {
            string bang = string.Format(
                "[!SetVariable SkinHeight {0} \"Darksidebar-11\\Sidebar\"][!UpdateMeter MeterBackground \"Darksidebar-11\\Sidebar\"][!Move {1} {2} \"Darksidebar-11\\Sidebar\"][!ZPos 0 \"Darksidebar-11\\Sidebar\"][!Show \"Darksidebar-11\\Sidebar\"][!Draggable 0 \"Darksidebar-11\\Sidebar\"][!Redraw \"Darksidebar-11\\Sidebar\"]",
                workHeight, targetX, targetY
            );
            SendBang(bang);
        } else {
            if (hideWhenMissing) {
                SendBang("[!Hide \"Darksidebar-11\\Sidebar\"]");
            }
        }
    }
}
'@

if (-not ([System.Management.Automation.PSTypeName]'AlignHelper').Type) {
    Add-Type -TypeDefinition $csharp
}

# Считываем конфигурацию из Settings.inc внутри @Resources
$resourcesDir = Split-Path $PSScriptRoot
$settingsPath = Join-Path $resourcesDir "Settings.inc"

$panelWidth = 240
$rightMargin = 0
$topMargin = 0
$placementEdge = "Right"
$targetPnpId = "MONITOR\SAM0247"
$targetFriendly = "SyncMaster"
$fallbackDev = "\\.\DISPLAY2"
$hideWhenMissing = $true

if (Test-Path $settingsPath) {
    try {
        $lines = Get-Content $settingsPath -Encoding UTF8 -ErrorAction SilentlyContinue
        foreach ($line in $lines) {
            if ($line -match '^\s*([^=;]+?)\s*=\s*(.*?)\s*$') {
                $k = $Matches[1].Trim()
                $v = $Matches[2].Trim()
                switch ($k) {
                    "SkinWidth"             { $panelWidth = [int]$v }
                    "RightMargin"           { $rightMargin = [int]$v }
                    "TopMargin"             { $topMargin = [int]$v }
                    "PlacementEdge"         { $placementEdge = $v }
                    "MonitorTargetId"       { if ($v) { $targetPnpId = $v } }
                    "MonitorFriendlyName"   { if ($v) { $targetFriendly = $v } }
                    "MonitorFallbackDev"    { if ($v) { $fallbackDev = $v } }
                    "HideWhenTargetMissing" { $hideWhenMissing = ($v -ne "0") }
                }
            }
        }
    } catch { }
}

# First-run auto-detection of language (Requirement 6)
if (Test-Path $settingsPath) {
    try {
        $cp1251 = [System.Text.Encoding]::GetEncoding(1251)
        $rawSettings = [System.IO.File]::ReadAllText($settingsPath, $cp1251)
        if ($rawSettings -notmatch '(?m)^FirstRunDone=1') {
            $isRussian = $false
            try {
                if ((Get-Culture).TwoLetterISOLanguageName -eq "ru" -or [System.Globalization.CultureInfo]::InstalledUICulture.TwoLetterISOLanguageName -eq "ru") {
                    $isRussian = $true
                }
            } catch { }

            $rainmeterIni = "$env:APPDATA\Rainmeter\Rainmeter.ini"
            if (Test-Path $rainmeterIni) {
                try {
                    $rmText = Get-Content $rainmeterIni -Raw -ErrorAction SilentlyContinue
                    if ($rmText -match '(?i)Language=(1049|Russian)') {
                        $isRussian = $true
                    }
                } catch { }
            }

            $detectedLang = if ($isRussian) { "Russian" } else { "English" }
            $detectedFirstDay = if ($isRussian) { "Monday" } else { "Sunday" }
            $detectedCity = if ($isRussian) { "Москва" } else { "London" }
            $detectedLat = if ($isRussian) { "55.7558" } else { "51.5074" }
            $detectedLon = if ($isRussian) { "37.6176" } else { "-0.1278" }

            $rawSettings = $rawSettings -replace '(?m)^Language=.*$', "Language=$detectedLang"
            $rawSettings = $rawSettings -replace '(?m)^CalendarFirstDay=.*$', "CalendarFirstDay=$detectedFirstDay"
            $rawSettings = $rawSettings -replace '(?m)^WeatherCity=.*$', "WeatherCity=$detectedCity"
            $rawSettings = $rawSettings -replace '(?m)^WeatherLat=.*$', "WeatherLat=$detectedLat"
            $rawSettings = $rawSettings -replace '(?m)^WeatherLon=.*$', "WeatherLon=$detectedLon"
            if ($rawSettings -match '(?m)^FirstRunDone=.*$') {
                $rawSettings = $rawSettings -replace '(?m)^FirstRunDone=.*$', "FirstRunDone=1"
            } else {
                $rawSettings += "`nFirstRunDone=1`n"
            }
            [System.IO.File]::WriteAllText($settingsPath, $rawSettings, $cp1251)
        }
    } catch { }
}

[AlignHelper]::AlignSmart(
    $targetPnpId,
    $targetFriendly,
    $fallbackDev,
    $panelWidth,
    $rightMargin,
    $topMargin,
    $placementEdge,
    $hideWhenMissing
)
