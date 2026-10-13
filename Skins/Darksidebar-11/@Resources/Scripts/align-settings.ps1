# align-settings.ps1
# Позиционирование окна настроек Darksidebar-11 строго поверх панели на целевом мониторе
param(
    [int]$SettingsWidth = 380,
    [int]$SettingsHeight = 600
)

$csharp = @'
using System;
using System.Runtime.InteropServices;

public class AlignSettingsHelper {
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

    public static void AlignSettings(
        string targetPnpId,
        string targetFriendly,
        string fallbackDev,
        int settingsWidth,
        int settingsHeight,
        int rightMargin,
        int topMargin,
        string placementEdge
    ) {
        int targetX = 0;
        int targetY = 0;
        bool found = false;

        EnumDisplayMonitors(IntPtr.Zero, IntPtr.Zero, (IntPtr hMon, IntPtr hdcMon, ref RECT rc, IntPtr data) => {
            var mi = new MONITORINFOEX();
            mi.cbSize = Marshal.SizeOf(typeof(MONITORINFOEX));
            if (GetMonitorInfo(hMon, ref mi)) {
                string dev = mi.szDevice.Trim();
                int w = mi.rcMonitor.right - mi.rcMonitor.left;
                int h = mi.rcMonitor.bottom - mi.rcMonitor.top;

                string pnpId = "";
                string friendly = "";
                var monDev = new DISPLAY_DEVICE();
                monDev.cb = Marshal.SizeOf(monDev);
                if (EnumDisplayDevices(dev, 0, ref monDev, 0)) {
                    pnpId = (monDev.DeviceID ?? "").Trim();
                    friendly = (monDev.DeviceString ?? "").Trim();
                }

                bool match = false;
                if (!string.IsNullOrEmpty(targetPnpId)) {
                    if (pnpId.IndexOf(targetPnpId, StringComparison.OrdinalIgnoreCase) >= 0 ||
                        targetPnpId.IndexOf(pnpId, StringComparison.OrdinalIgnoreCase) >= 0) {
                        match = true;
                    }
                }
                if (!match && !string.IsNullOrEmpty(targetFriendly)) {
                    if (friendly.IndexOf(targetFriendly, StringComparison.OrdinalIgnoreCase) >= 0 ||
                        targetFriendly.IndexOf(friendly, StringComparison.OrdinalIgnoreCase) >= 0) {
                        match = true;
                    }
                }
                if (!match) {
                    if (!string.IsNullOrEmpty(fallbackDev) && dev.Equals(fallbackDev, StringComparison.OrdinalIgnoreCase)) {
                        match = true;
                    } else if (w == 1280 && h == 1024) {
                        match = true;
                    }
                }

                if (match) {
                    if (string.Equals(placementEdge, "Left", StringComparison.OrdinalIgnoreCase)) {
                        targetX = mi.rcWork.left + rightMargin;
                    } else {
                        targetX = mi.rcWork.right - settingsWidth - rightMargin;
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
                "[!Move {0} {1} \"Darksidebar-11\\Settings\"][!ZPos 1 \"Darksidebar-11\\Settings\"][!Show \"Darksidebar-11\\Settings\"][!Redraw \"Darksidebar-11\\Settings\"]",
                targetX, targetY
            );
            SendBang(bang);
        }
    }
}
'@

if (-not ([System.Management.Automation.PSTypeName]'AlignSettingsHelper').Type) {
    Add-Type -TypeDefinition $csharp
}

$resourcesDir = Split-Path $PSScriptRoot
$settingsPath = Join-Path $resourcesDir "Settings.inc"

$rightMargin = 0
$topMargin = 0
$placementEdge = "Right"
$targetPnpId = "MONITOR\SAM0247"
$targetFriendly = "SyncMaster"
$fallbackDev = "\\.\DISPLAY2"

if (Test-Path $settingsPath) {
    try {
        $lines = Get-Content $settingsPath -Encoding UTF8 -ErrorAction SilentlyContinue
        foreach ($line in $lines) {
            if ($line -match '^\s*([^=;]+?)\s*=\s*(.*?)\s*$') {
                $k = $Matches[1].Trim()
                $v = $Matches[2].Trim()
                switch ($k) {
                    "RightMargin"           { $rightMargin = [int]$v }
                    "TopMargin"             { $topMargin = [int]$v }
                    "PlacementEdge"         { $placementEdge = $v }
                    "MonitorTargetId"       { if ($v) { $targetPnpId = $v } }
                    "MonitorFriendlyName"   { if ($v) { $targetFriendly = $v } }
                    "MonitorFallbackDev"    { if ($v) { $fallbackDev = $v } }
                }
            }
        }
    } catch { }
}

[AlignSettingsHelper]::AlignSettings(
    $targetPnpId,
    $targetFriendly,
    $fallbackDev,
    $SettingsWidth,
    $SettingsHeight,
    $rightMargin,
    $topMargin,
    $placementEdge
)
