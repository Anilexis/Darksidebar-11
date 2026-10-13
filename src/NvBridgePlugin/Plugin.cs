using System;
using System.Diagnostics;
using System.IO;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;

namespace NvBridgePlugin {
    // --- Shared Hardware Monitor Engine (Singleton) ---
    public static class HardwareEngine {
        // --- Win32 API ---
        [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Auto)]
        static extern IntPtr LoadLibrary(string lpFileName);

        [DllImport("kernel32.dll", SetLastError = true)]
        static extern IntPtr GetProcAddress(IntPtr hModule, string lpProcName);

        [DllImport("user32.dll")]
        static extern IntPtr GetForegroundWindow();

        [DllImport("user32.dll")]
        static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);

        // --- NVML ---
        [DllImport("nvml.dll", EntryPoint = "nvmlInit_v2")]
        static extern int NvmlInit();

        [DllImport("nvml.dll", EntryPoint = "nvmlShutdown")]
        static extern int NvmlShutdown();

        [DllImport("nvml.dll", EntryPoint = "nvmlDeviceGetHandleByIndex_v2")]
        static extern int NvmlGetHandle(uint index, out IntPtr handle);

        [DllImport("nvml.dll", EntryPoint = "nvmlDeviceGetTemperature")]
        static extern int NvmlGetTemp(IntPtr handle, uint sensorType, out uint temp);

        [DllImport("nvml.dll", EntryPoint = "nvmlDeviceGetName")]
        static extern int NvmlGetName(IntPtr handle, byte[] name, uint length);

        [DllImport("advapi32.dll", CharSet = CharSet.Unicode, EntryPoint = "RegOpenKeyExW")]
        static extern int RegOpenKeyEx(IntPtr hKey, string lpSubKey, uint ulOptions, int samDesired, out IntPtr phkResult);

        [DllImport("advapi32.dll", CharSet = CharSet.Unicode, EntryPoint = "RegQueryValueExW")]
        static extern int RegQueryValueEx(IntPtr hKey, string lpValueName, IntPtr lpReserved, out uint lpType, StringBuilder lpData, ref uint lpcbData);

        [DllImport("advapi32.dll", EntryPoint = "RegCloseKey")]
        static extern int RegCloseKey(IntPtr hKey);

        [StructLayout(LayoutKind.Sequential)]
        struct NvmlMemory {
            public ulong total;
            public ulong free;
            public ulong used;
        }

        [DllImport("nvml.dll", EntryPoint = "nvmlDeviceGetMemoryInfo")]
        static extern int NvmlGetMemory(IntPtr handle, out NvmlMemory mem);

        [StructLayout(LayoutKind.Sequential)]
        struct NvmlUtilization {
            public uint gpu;
            public uint memory;
        }

        [DllImport("nvml.dll", EntryPoint = "nvmlDeviceGetUtilizationRates")]
        static extern int NvmlGetUtilization(IntPtr handle, out NvmlUtilization util);

        // --- FrameView SDK ---
        [UnmanagedFunctionPointer(CallingConvention.Cdecl)]
        delegate IntPtr FvQueryInterfaceDelegate(uint index);

        [UnmanagedFunctionPointer(CallingConvention.Cdecl)]
        delegate int FvInitDelegate();

        [UnmanagedFunctionPointer(CallingConvention.Cdecl)]
        delegate int FvCreateSessionDelegate(out IntPtr session);

        [UnmanagedFunctionPointer(CallingConvention.Cdecl)]
        delegate int FvStartSessionDelegate(IntPtr session);

        [UnmanagedFunctionPointer(CallingConvention.Cdecl)]
        delegate int FvEnableMetricsDelegate(IntPtr session, uint[] metrics, uint count);

        [UnmanagedFunctionPointer(CallingConvention.Cdecl)]
        delegate int FvSampleDataDelegate(IntPtr session, int flags);

        [UnmanagedFunctionPointer(CallingConvention.Cdecl)]
        delegate int FvReadDataDelegate(IntPtr session, ref Samples samples, uint count);

        [UnmanagedFunctionPointer(CallingConvention.Cdecl)]
        delegate int FvStopSessionDelegate(IntPtr session);

        [UnmanagedFunctionPointer(CallingConvention.Cdecl)]
        delegate int FvDestroySessionDelegate(IntPtr session);

        [StructLayout(LayoutKind.Sequential)]
        struct Samples {
            public uint version;
            public uint type;
            public IntPtr mNumSamples;
            public IntPtr mData;
        }

        [StructLayout(LayoutKind.Sequential)]
        struct BaseMetric_v1 {
            public uint baseversion;
            public uint pad1;
            public ulong mTimestamp;
        }

        [StructLayout(LayoutKind.Sequential)]
        struct CPUPkgTemp_v1 {
            public BaseMetric_v1 baseMetric;
            public uint version;
            public uint pad2;
            public double mCPUPkgTemp;
        }

        [StructLayout(LayoutKind.Sequential)]
        struct FPS_v1 {
            public uint version;
            public uint pad1;
            public ulong PID;
            public ulong SwapChain;
            public double AvgFPS;
        }

        [StructLayout(LayoutKind.Sequential)]
        struct AvgFPS_v1 {
            public BaseMetric_v1 baseMetric;
            public uint version;
            public uint pad2;
            public FPS_v1 mFPS;
        }

        const uint eAvgFPS = 0x6C4B1348;
        const uint eCPUPkgTemp = 0xB0CCC37A;

        static bool nvmlInitialized = false;
        static IntPtr nvmlDevice = IntPtr.Zero;

        static bool fvInitialized = false;
        static IntPtr fvSession = IntPtr.Zero;
        static FvSampleDataDelegate? fvSampleData;
        static FvReadDataDelegate? fvReadData;
        static FvStopSessionDelegate? fvStopSession;
        static FvDestroySessionDelegate? fvDestroySession;

        static Thread? workerThread;
        static volatile bool isRunning = false;
        static int refCount = 0;
        static readonly object lockObj = new object();

        static string QueryProcessorName() {
            try {
                IntPtr HKEY_LOCAL_MACHINE = unchecked((IntPtr)(int)0x80000002);
                if (RegOpenKeyEx(HKEY_LOCAL_MACHINE, @"HARDWARE\DESCRIPTION\System\CentralProcessor\0", 0, 0x20019 /* KEY_READ */, out IntPtr hKey) == 0) {
                    try {
                        StringBuilder sb = new StringBuilder(256);
                        uint cbData = (uint)(sb.Capacity * 2);
                        if (RegQueryValueEx(hKey, "ProcessorNameString", IntPtr.Zero, out _, sb, ref cbData) == 0) {
                            string val = sb.ToString();
                            string clean = System.Text.RegularExpressions.Regex.Replace(val, @"\s+", " ").Trim();
                            clean = clean.Replace("(R)", "").Replace("(TM)", "").Trim();
                            clean = System.Text.RegularExpressions.Regex.Replace(clean, @"\s+", " ");
                            if (clean.StartsWith("Intel ")) clean = clean.Substring(6).Trim();
                            if (!string.IsNullOrEmpty(clean)) return clean;
                        }
                    } finally {
                        RegCloseKey(hKey);
                    }
                }
            } catch { }
            return "CPU";
        }

        // Cached telemetry (dynamic detection with zero hardcode)
        public static string CpuModel = QueryProcessorName();
        public static double CpuTemp = 0;
        public static string GpuModel = "NVIDIA GPU";
        public static double GpuTemp = 0;
        public static double GpuLoad = 0;
        public static double VramUsed = 0;
        public static double VramTotal = 0;
        public static double Fps = 0;

        public static void Retain() {
            lock (lockObj) {
                refCount++;
                if (workerThread == null || !workerThread.IsAlive) {
                    isRunning = true;
                    workerThread = new Thread(WorkerLoop) {
                        IsBackground = true,
                        Name = "NvBridgePlugin_Worker"
                    };
                    workerThread.Start();
                }
            }
        }

        public static void Release() {
            lock (lockObj) {
                refCount--;
                if (refCount < 0) refCount = 0;
            }
        }

        static void InitNvml() {
            try {
                if (NvmlInit() == 0) {
                    if (NvmlGetHandle(0, out nvmlDevice) == 0 && nvmlDevice != IntPtr.Zero) {
                        nvmlInitialized = true;
                        try {
                            byte[] buf = new byte[96];
                            if (NvmlGetName(nvmlDevice, buf, (uint)buf.Length) == 0) {
                                string name = Encoding.ASCII.GetString(buf).TrimEnd('\0').Trim();
                                if (name.StartsWith("NVIDIA ")) name = name.Substring(7).Trim();
                                if (!string.IsNullOrEmpty(name)) GpuModel = name;
                            }
                        } catch { }
                    }
                }
            } catch {
                nvmlInitialized = false;
            }
        }

        static void InitFrameView() {
            try {
                string dllPath = @"C:\Program Files\NVIDIA Corporation\FrameViewSDK\bin\FvSDK_x64.dll";
                if (!File.Exists(dllPath)) return;

                IntPtr hModule = LoadLibrary(dllPath);
                if (hModule == IntPtr.Zero) return;

                IntPtr pQi = GetProcAddress(hModule, "fv_QueryInterface");
                if (pQi == IntPtr.Zero) return;

                var fvQi = Marshal.GetDelegateForFunctionPointer<FvQueryInterfaceDelegate>(pQi);
                var fvInit = Marshal.GetDelegateForFunctionPointer<FvInitDelegate>(fvQi(7));
                var fvCreateSession = Marshal.GetDelegateForFunctionPointer<FvCreateSessionDelegate>(fvQi(0));
                fvDestroySession = Marshal.GetDelegateForFunctionPointer<FvDestroySessionDelegate>(fvQi(1));
                var fvEnableMetrics = Marshal.GetDelegateForFunctionPointer<FvEnableMetricsDelegate>(fvQi(2));
                fvSampleData = Marshal.GetDelegateForFunctionPointer<FvSampleDataDelegate>(fvQi(3));
                fvReadData = Marshal.GetDelegateForFunctionPointer<FvReadDataDelegate>(fvQi(4));
                var fvStartSession = Marshal.GetDelegateForFunctionPointer<FvStartSessionDelegate>(fvQi(5));
                fvStopSession = Marshal.GetDelegateForFunctionPointer<FvStopSessionDelegate>(fvQi(6));

                fvInit();
                int rCreate = fvCreateSession(out fvSession);
                if (rCreate == 0 && fvSession != IntPtr.Zero) {
                    fvEnableMetrics(fvSession, new uint[] { eAvgFPS, eCPUPkgTemp }, 2);
                    fvStartSession(fvSession);
                    fvInitialized = true;
                }
            } catch {
                fvInitialized = false;
            }
        }

        static string GetProcessBaseName(int pid) {
            try {
                using Process p = Process.GetProcessById(pid);
                return p.ProcessName.ToLowerInvariant();
            } catch {
                return "";
            }
        }

        static bool IsNonGameProcess(string name) {
            if (string.IsNullOrEmpty(name)) return true;
            if (name == "dwm" || name == "explorer" || name == "rainmeter" || name == "applicationframehost" ||
                name == "taskmgr" || name == "cmd" || name == "powershell" || name == "pwsh" ||
                name == "conhost" || name == "windowsterminal" || name == "system" || name == "idle" ||
                name == "chrome" || name == "msedge" || name == "firefox" || name == "opera" ||
                name == "brave" || name == "vivaldi" || name == "tor" ||
                name == "code" || name == "antigravity" || name == "devenv" || name == "rider64" ||
                name == "idea64" || name == "clion64" || name == "pycharm64" ||
                name == "notepad" || name == "notepad++" || name == "discord" || name == "telegram" ||
                name == "spotify" || name == "steam" || name == "steamwebhelper" ||
                name == "epicgameslauncher" || name == "galaxyclient" || name == "battlenet" ||
                name == "origin" || name == "ea" || name == "nvcontainer" || name == "nvidia share" ||
                name == "geforce_now" || name == "librehardwaremonitor" || name == "nvbridge" || name == "lhmbridge") {
                return true;
            }
            if (name.StartsWith("chrome") || name.StartsWith("msedge") || name.StartsWith("antigravity")) {
                return true;
            }
            return false;
        }

        static void WorkerLoop() {
            try {
                InitNvml();
                InitFrameView();
            } catch { }

            while (isRunning) {
                if (refCount <= 0) {
                    Thread.Sleep(500);
                    continue;
                }

                try {
                    // 1. NVML
                    if (!nvmlInitialized) InitNvml();
                    if (nvmlInitialized && nvmlDevice != IntPtr.Zero) {
                        uint gTemp;
                        if (NvmlGetTemp(nvmlDevice, 0, out gTemp) == 0) {
                            GpuTemp = gTemp;
                        }

                        NvmlUtilization util;
                        if (NvmlGetUtilization(nvmlDevice, out util) == 0) {
                            GpuLoad = util.gpu;
                        }

                        NvmlMemory mem;
                        if (NvmlGetMemory(nvmlDevice, out mem) == 0) {
                            VramUsed = mem.used / (1024.0 * 1024.0 * 1024.0);
                            VramTotal = mem.total / (1024.0 * 1024.0 * 1024.0);
                        }
                    }

                    // 2. FrameView SDK
                    if (!fvInitialized) InitFrameView();
                    if (fvInitialized && fvSession != IntPtr.Zero && fvSampleData != null && fvReadData != null) {
                        try {
                            fvSampleData(fvSession, 0);

                            // CPU Package Temp
                            Samples sTemp = new Samples {
                                version = (uint)(Marshal.SizeOf<Samples>() | (1 << 16)),
                                type = eCPUPkgTemp,
                                mNumSamples = IntPtr.Zero,
                                mData = IntPtr.Zero
                            };

                            if (fvReadData(fvSession, ref sTemp, 1) == 0) {
                                long numTemp = sTemp.mNumSamples.ToInt64();
                                if (numTemp > 0) {
                                    int sz = Marshal.SizeOf<CPUPkgTemp_v1>();
                                    sTemp.mData = Marshal.AllocHGlobal((int)(numTemp * sz));
                                    try {
                                        for (int i = 0; i < numTemp; i++) {
                                            IntPtr ptr = new IntPtr(sTemp.mData.ToInt64() + i * sz);
                                            CPUPkgTemp_v1 initItem = new CPUPkgTemp_v1();
                                            initItem.baseMetric.baseversion = (uint)(Marshal.SizeOf<BaseMetric_v1>() | (1 << 16));
                                            initItem.version = (uint)(Marshal.SizeOf<CPUPkgTemp_v1>() | (1 << 16));
                                            Marshal.StructureToPtr(initItem, ptr, false);
                                        }

                                        if (fvReadData(fvSession, ref sTemp, 1) == 0) {
                                            for (int i = 0; i < numTemp; i++) {
                                                IntPtr ptr = new IntPtr(sTemp.mData.ToInt64() + i * sz);
                                                CPUPkgTemp_v1 item = Marshal.PtrToStructure<CPUPkgTemp_v1>(ptr);
                                                if (item.mCPUPkgTemp > 0) {
                                                    CpuTemp = Math.Round(item.mCPUPkgTemp);
                                                }
                                            }
                                        }
                                    } finally {
                                        Marshal.FreeHGlobal(sTemp.mData);
                                    }
                                }
                            }
                        } catch { }

                        // FPS активной игры
                        try {
                            uint fgPid = 0;
                            IntPtr fgWnd = GetForegroundWindow();
                            if (fgWnd != IntPtr.Zero) {
                                GetWindowThreadProcessId(fgWnd, out fgPid);
                            }

                            double detectedFps = 0;
                            if (fgPid > 0) {
                                string fgName = GetProcessBaseName((int)fgPid);
                                if (!IsNonGameProcess(fgName)) {
                                    Samples sFps = new Samples {
                                        version = (uint)(Marshal.SizeOf<Samples>() | (1 << 16)),
                                        type = eAvgFPS,
                                        mNumSamples = IntPtr.Zero,
                                        mData = IntPtr.Zero
                                    };

                                    if (fvReadData(fvSession, ref sFps, 1) == 0) {
                                        long numFps = sFps.mNumSamples.ToInt64();
                                        if (numFps > 0) {
                                            int sz = Marshal.SizeOf<AvgFPS_v1>();
                                            sFps.mData = Marshal.AllocHGlobal((int)(numFps * sz));
                                            try {
                                                for (int i = 0; i < numFps; i++) {
                                                    IntPtr ptr = new IntPtr(sFps.mData.ToInt64() + i * sz);
                                                    AvgFPS_v1 initItem = new AvgFPS_v1();
                                                    initItem.baseMetric.baseversion = (uint)(Marshal.SizeOf<BaseMetric_v1>() | (1 << 16));
                                                    initItem.version = (uint)(Marshal.SizeOf<AvgFPS_v1>() | (1 << 16));
                                                    initItem.mFPS.version = (uint)(Marshal.SizeOf<FPS_v1>() | (1 << 16));
                                                    Marshal.StructureToPtr(initItem, ptr, false);
                                                }

                                                if (fvReadData(fvSession, ref sFps, 1) == 0) {
                                                    for (int i = 0; i < numFps; i++) {
                                                        IntPtr ptr = new IntPtr(sFps.mData.ToInt64() + i * sz);
                                                        AvgFPS_v1 item = Marshal.PtrToStructure<AvgFPS_v1>(ptr);
                                                        if ((int)item.mFPS.PID == (int)fgPid && item.mFPS.AvgFPS > 0) {
                                                            detectedFps = Math.Round(item.mFPS.AvgFPS);
                                                        }
                                                    }
                                                }
                                            } finally {
                                                Marshal.FreeHGlobal(sFps.mData);
                                            }
                                        }
                                    }
                                }
                            }
                            Fps = detectedFps;
                        } catch { }
                    }
                } catch { }

                Thread.Sleep(2000);
            }

            // Cleanup on shutdown
            if (fvInitialized && fvSession != IntPtr.Zero) {
                try {
                    fvStopSession?.Invoke(fvSession);
                    fvDestroySession?.Invoke(fvSession);
                } catch { }
            }
            if (nvmlInitialized) {
                try { NvmlShutdown(); } catch { }
            }
        }
    }

    // --- Rainmeter Measure Instance ---
    public class MeasureInstance {
        public string Metric = "";
        IntPtr stringBuffer = IntPtr.Zero;

        [DllImport("Rainmeter.dll", EntryPoint = "RmReadString", CharSet = CharSet.Unicode)]
        static extern IntPtr RmReadString(IntPtr rm, string option, string defValue, bool replaceVariables = true);

        public unsafe void Reload(IntPtr rm, double* maxValue) {
            try {
                IntPtr p = RmReadString(rm, "Metric", "");
                if (p != IntPtr.Zero) {
                    Metric = Marshal.PtrToStringUni(p) ?? "";
                }
            } catch { }
        }

        public double Update() {
            string m = Metric.ToLowerInvariant();
            if (m == "cputemp") return HardwareEngine.CpuTemp;
            if (m == "gputemp") return HardwareEngine.GpuTemp;
            if (m == "gpuload") return HardwareEngine.GpuLoad;
            if (m == "vramused") return HardwareEngine.VramUsed;
            if (m == "vramtotal") return HardwareEngine.VramTotal;
            if (m == "fps") return HardwareEngine.Fps;
            return 0.0;
        }

        public IntPtr GetString() {
            string val = "";
            string m = Metric.ToLowerInvariant();
            if (m == "cpumodel") {
                val = HardwareEngine.CpuModel;
            } else if (m == "cputemp") {
                val = HardwareEngine.CpuTemp > 0 ? HardwareEngine.CpuTemp.ToString("0") : "--";
            } else if (m == "gpumodel") {
                val = HardwareEngine.GpuModel;
            } else if (m == "gputemp") {
                val = HardwareEngine.GpuTemp > 0 ? HardwareEngine.GpuTemp.ToString("0") : "--";
            } else if (m == "gpuload") {
                val = HardwareEngine.GpuLoad.ToString("0");
            } else if (m == "gpusummary") {
                string temp = HardwareEngine.GpuTemp > 0 ? HardwareEngine.GpuTemp.ToString("0") + "°C" : "--°C";
                val = $"{HardwareEngine.GpuLoad:0}% | {temp}";
            } else if (m == "vramsummary") {
                string used = HardwareEngine.VramUsed > 0 ? HardwareEngine.VramUsed.ToString("0.0", System.Globalization.CultureInfo.InvariantCulture) : "--";
                string tot = HardwareEngine.VramTotal > 0 ? HardwareEngine.VramTotal.ToString("0.0", System.Globalization.CultureInfo.InvariantCulture) : "--";
                val = $"VRAM: {used} / {tot} GiB";
            } else if (m == "fps") {
                val = HardwareEngine.Fps > 0 ? $"FPS: {HardwareEngine.Fps:0}" : "FPS: —";
            }

            if (stringBuffer != IntPtr.Zero) {
                Marshal.FreeHGlobal(stringBuffer);
                stringBuffer = IntPtr.Zero;
            }
            stringBuffer = Marshal.StringToHGlobalUni(val);
            return stringBuffer;
        }

        public void Dispose() {
            if (stringBuffer != IntPtr.Zero) {
                Marshal.FreeHGlobal(stringBuffer);
                stringBuffer = IntPtr.Zero;
            }
        }
    }

    // --- Rainmeter Native C API Exports ---
    public static unsafe class PluginExports {
        [UnmanagedCallersOnly(EntryPoint = "Initialize")]
        public static void Initialize(IntPtr* data, IntPtr rm) {
            HardwareEngine.Retain();
            var instance = new MeasureInstance();
            instance.Reload(rm, null);
            GCHandle handle = GCHandle.Alloc(instance);
            *data = (IntPtr)handle;
        }

        [UnmanagedCallersOnly(EntryPoint = "Reload")]
        public static void Reload(IntPtr data, IntPtr rm, double* maxValue) {
            if (data != IntPtr.Zero) {
                GCHandle handle = (GCHandle)data;
                if (handle.Target is MeasureInstance instance) {
                    instance.Reload(rm, maxValue);
                }
            }
        }

        [UnmanagedCallersOnly(EntryPoint = "Update")]
        public static double Update(IntPtr data) {
            if (data != IntPtr.Zero) {
                GCHandle handle = (GCHandle)data;
                if (handle.Target is MeasureInstance instance) {
                    return instance.Update();
                }
            }
            return 0.0;
        }

        [UnmanagedCallersOnly(EntryPoint = "GetString")]
        public static IntPtr GetString(IntPtr data) {
            if (data != IntPtr.Zero) {
                GCHandle handle = (GCHandle)data;
                if (handle.Target is MeasureInstance instance) {
                    return instance.GetString();
                }
            }
            return IntPtr.Zero;
        }

        [UnmanagedCallersOnly(EntryPoint = "ExecuteBang")]
        public static void ExecuteBang(IntPtr data, IntPtr args) { }

        [UnmanagedCallersOnly(EntryPoint = "Finalize")]
        public static void Finalize(IntPtr data) {
            if (data != IntPtr.Zero) {
                GCHandle handle = (GCHandle)data;
                if (handle.Target is MeasureInstance instance) {
                    instance.Dispose();
                }
                if (handle.IsAllocated) {
                    handle.Free();
                }
            }
            HardwareEngine.Release();
        }
    }
}
