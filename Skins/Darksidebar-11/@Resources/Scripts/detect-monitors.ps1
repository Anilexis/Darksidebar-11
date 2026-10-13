# detect-monitors.ps1
# Обнаружение активных мониторов, их PnP ID, дружественных имен и геометрии
param(
    [switch]$AsJson = $false
)

$csharp = @'
using System;
using System.Runtime.InteropServices;
using System.Collections.Generic;

public class MonitorDetector {
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

    public class MonitorEntry {
        public string DeviceName { get; set; } = "";
        public string PnpId { get; set; } = "";
        public string FriendlyName { get; set; } = "";
        public bool IsPrimary { get; set; }
        public int Width { get; set; }
        public int Height { get; set; }
        public int WorkLeft { get; set; }
        public int WorkTop { get; set; }
        public int WorkRight { get; set; }
        public int WorkBottom { get; set; }
        public int WorkWidth { get; set; }
        public int WorkHeight { get; set; }
    }

    public static List<MonitorEntry> DetectAll() {
        var list = new List<MonitorEntry>();

        EnumDisplayMonitors(IntPtr.Zero, IntPtr.Zero, (IntPtr hMon, IntPtr hdcMon, ref RECT rc, IntPtr data) => {
            var mi = new MONITORINFOEX();
            mi.cbSize = Marshal.SizeOf(typeof(MONITORINFOEX));
            if (GetMonitorInfo(hMon, ref mi)) {
                string dev = mi.szDevice.Trim();
                var entry = new MonitorEntry {
                    DeviceName = dev,
                    IsPrimary = (mi.dwFlags & 1) != 0,
                    Width = mi.rcMonitor.right - mi.rcMonitor.left,
                    Height = mi.rcMonitor.bottom - mi.rcMonitor.top,
                    WorkLeft = mi.rcWork.left,
                    WorkTop = mi.rcWork.top,
                    WorkRight = mi.rcWork.right,
                    WorkBottom = mi.rcWork.bottom,
                    WorkWidth = mi.rcWork.right - mi.rcWork.left,
                    WorkHeight = mi.rcWork.bottom - mi.rcWork.top
                };

                // Получаем аппаратный PnP ID через EnumDisplayDevices
                var monDev = new DISPLAY_DEVICE();
                monDev.cb = Marshal.SizeOf(monDev);
                if (EnumDisplayDevices(dev, 0, ref monDev, 0)) {
                    entry.PnpId = (monDev.DeviceID ?? "").Trim();
                    entry.FriendlyName = (monDev.DeviceString ?? "").Trim();
                }

                list.Add(entry);
            }
            return true;
        }, IntPtr.Zero);

        return list;
    }
}
'@

if (-not ([System.Management.Automation.PSTypeName]'MonitorDetector').Type) {
    Add-Type -TypeDefinition $csharp
}

$monitors = [MonitorDetector]::DetectAll()

# Пытаемся улучшить FriendlyName через реестр, если вернулся Generic PnP Monitor
foreach ($m in $monitors) {
    if ($m.FriendlyName -match 'Generic' -or [string]::IsNullOrWhiteSpace($m.FriendlyName)) {
        if ($m.PnpId -match '^MONITOR\\([^\\]+)') {
            $modelCode = $Matches[1]
            try {
                $regPath = "HKLM:\SYSTEM\CurrentControlSet\Enum\DISPLAY"
                $found = Get-ChildItem $regPath -Recurse -ErrorAction SilentlyContinue | Where-Object {
                    $_.PSChildName -like "*$modelCode*" -or $_.Name -like "*$modelCode*"
                }
                foreach ($item in $found) {
                    $p = Get-ItemProperty $item.PSPath -ErrorAction SilentlyContinue
                    if ($p -and $p.FriendlyName -and $p.FriendlyName -notmatch '@System32') {
                        $clean = $p.FriendlyName -replace '^Generic Monitor \((.+)\)$', '$1'
                        if ($clean) { $m.FriendlyName = $clean; break }
                    }
                }
            } catch { }
        }
    }
}

if ($AsJson) {
    $monitors | ConvertTo-Json -Depth 3
} else {
    $monitors
}
