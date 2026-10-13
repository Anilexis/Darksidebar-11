# detect-monitors.ps1
# Обнаружение активных мониторов, их PnP ID, дружественных имен и циклическое переключение (prev / next)
param(
    [string]$Direction = "",
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
        public string DeviceName;
        public string PnpId;
        public string FriendlyName;
        public bool IsPrimary;
        public int Width;
        public int Height;
        public int WorkLeft;
        public int WorkTop;
        public int WorkRight;
        public int WorkBottom;
        public int WorkWidth;
        public int WorkHeight;
    }

    public static List<MonitorEntry> DetectAll() {
        var list = new List<MonitorEntry>();

        EnumDisplayMonitors(IntPtr.Zero, IntPtr.Zero, (IntPtr hMon, IntPtr hdcMon, ref RECT rc, IntPtr data) => {
            var mi = new MONITORINFOEX();
            mi.cbSize = Marshal.SizeOf(typeof(MONITORINFOEX));
            if (GetMonitorInfo(hMon, ref mi)) {
                string dev = mi.szDevice.Trim();
                var entry = new MonitorEntry();
                entry.DeviceName = dev;
                entry.IsPrimary = (mi.dwFlags & 1) != 0;
                entry.Width = mi.rcMonitor.right - mi.rcMonitor.left;
                entry.Height = mi.rcMonitor.bottom - mi.rcMonitor.top;
                entry.WorkLeft = mi.rcWork.left;
                entry.WorkTop = mi.rcWork.top;
                entry.WorkRight = mi.rcWork.right;
                entry.WorkBottom = mi.rcWork.bottom;
                entry.WorkWidth = mi.rcWork.right - mi.rcWork.left;
                entry.WorkHeight = mi.rcWork.bottom - mi.rcWork.top;
                entry.PnpId = "";
                entry.FriendlyName = "";

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

# Улучшаем FriendlyName через реестр, если вернулся Generic PnP Monitor
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
    if ([string]::IsNullOrWhiteSpace($m.FriendlyName)) {
        $m.FriendlyName = if ($m.IsPrimary) { "Primary" } else { "Display $($m.DeviceName)" }
    }
}

$scriptsDir = $PSScriptRoot
$resourcesDir = Split-Path $scriptsDir
$settingsPath = Join-Path $resourcesDir "Settings.inc"

if ($Direction -and $monitors.Count -gt 0) {
    $curDev = "\\.\DISPLAY1"
    $curPnp = ""
    $cp1251 = [System.Text.Encoding]::GetEncoding(1251)

    if (Test-Path $settingsPath) {
        $lines = [System.IO.File]::ReadAllLines($settingsPath, $cp1251)
        foreach ($line in $lines) {
            if ($line -match '^\s*MonitorFallbackDev\s*=\s*(.*?)\s*$') { $curDev = $Matches[1].Trim() }
            if ($line -match '^\s*MonitorTargetId\s*=\s*(.*?)\s*$') { $curPnp = $Matches[1].Trim() }
        }
    }

    $idx = 0
    for ($i = 0; $i -lt $monitors.Count; $i++) {
        if ($monitors[$i].DeviceName -eq $curDev -or ($curPnp -and $monitors[$i].PnpId -eq $curPnp)) {
            $idx = $i
            break
        }
    }

    if ($Direction.ToLowerInvariant() -eq "next") {
        $nextIdx = ($idx + 1) % $monitors.Count
    } else {
        $nextIdx = ($idx - 1 + $monitors.Count) % $monitors.Count
    }

    $chosen = $monitors[$nextIdx]

    if (Test-Path $settingsPath) {
        $content = [System.IO.File]::ReadAllText($settingsPath, $cp1251)
        $content = $content -replace '(?m)^MonitorFallbackDev=.*$', "MonitorFallbackDev=$($chosen.DeviceName)"
        $content = $content -replace '(?m)^MonitorFriendlyName=.*$', "MonitorFriendlyName=$($chosen.FriendlyName)"
        $content = $content -replace '(?m)^MonitorTargetId=.*$', "MonitorTargetId=$($chosen.PnpId)"
        [System.IO.File]::WriteAllText($settingsPath, $content, $cp1251)
    }

    Write-Host "Cycled to monitor: $($chosen.FriendlyName) ($($chosen.DeviceName))"
} elseif ($AsJson) {
    $monitors | ConvertTo-Json -Depth 3
} else {
    $monitors
}
