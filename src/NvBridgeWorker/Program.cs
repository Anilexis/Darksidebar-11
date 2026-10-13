using System;
using System.IO;
using System.Runtime.InteropServices;
using System.Threading;

class Program {
    [DllImport("kernel32.dll", SetLastError = true)] static extern IntPtr LoadLibrary(string s);
    [DllImport("kernel32.dll", SetLastError = true)] static extern IntPtr GetProcAddress(IntPtr m, string s);
    [DllImport("user32.dll")] static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")] static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);

    [UnmanagedFunctionPointer(CallingConvention.Cdecl)] delegate IntPtr FvQI(uint i);
    [UnmanagedFunctionPointer(CallingConvention.Cdecl)] delegate int FvInit();
    [UnmanagedFunctionPointer(CallingConvention.Cdecl)] delegate int FvCS(out IntPtr s);
    [UnmanagedFunctionPointer(CallingConvention.Cdecl)] delegate int FvEM(IntPtr s, uint[] m, uint c);
    [UnmanagedFunctionPointer(CallingConvention.Cdecl)] delegate int FvSD(IntPtr s, int f);
    [UnmanagedFunctionPointer(CallingConvention.Cdecl)] delegate int FvRD(IntPtr s, ref Samples sp, uint c);
    [UnmanagedFunctionPointer(CallingConvention.Cdecl)] delegate int FvSS(IntPtr s);
    [UnmanagedFunctionPointer(CallingConvention.Cdecl)] delegate int FvStopS(IntPtr s);

    [StructLayout(LayoutKind.Sequential)] struct Samples { public uint v, t; public IntPtr n, d; }
    [StructLayout(LayoutKind.Sequential)] struct BaseMetric { public uint v, p1; public ulong ts; }
    [StructLayout(LayoutKind.Sequential)] struct CPUPkgTemp { public BaseMetric b; public uint v, p2; public double temp; }
    [StructLayout(LayoutKind.Sequential)] struct FPS_v1 { public uint v, p1; public ulong pid, sc; public double fps; }
    [StructLayout(LayoutKind.Sequential)] struct AvgFPS { public BaseMetric b; public uint v, p2; public FPS_v1 f; }

    const uint eCPUPkgTemp = 0xB0CCC37A;
    const uint eAvgFPS = 0x6C4B1348;

    static void Main(string[] args) {
        // Mutex to ensure single instance
        bool createdNew;
        using (var mutex = new Mutex(true, "Darksidebar11_NvBridgeWorker_Mutex", out createdNew)) {
            if (!createdNew) return;

            string docCache = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments), @"Rainmeter\Skins\Darksidebar-11\@Resources\Cache");
            string cacheFile = Path.Combine(docCache, "hardware-data.inc");
            if (!Directory.Exists(docCache)) {
                try { Directory.CreateDirectory(docCache); } catch { }
            }

            string dllPath = @"C:\Program Files\NVIDIA Corporation\FrameViewSDK\bin\FvSDK_x64.dll";
            if (!File.Exists(dllPath)) return;

            IntPtr hModule = LoadLibrary(dllPath);
            if (hModule == IntPtr.Zero) return;

            IntPtr pQi = GetProcAddress(hModule, "fv_QueryInterface");
            if (pQi == IntPtr.Zero) return;

            var qi = (FvQI)Marshal.GetDelegateForFunctionPointer(pQi, typeof(FvQI));
            var init = (FvInit)Marshal.GetDelegateForFunctionPointer(qi(7), typeof(FvInit));
            var cs = (FvCS)Marshal.GetDelegateForFunctionPointer(qi(0), typeof(FvCS));
            var em = (FvEM)Marshal.GetDelegateForFunctionPointer(qi(2), typeof(FvEM));
            var sd = (FvSD)Marshal.GetDelegateForFunctionPointer(qi(3), typeof(FvSD));
            var rd = (FvRD)Marshal.GetDelegateForFunctionPointer(qi(4), typeof(FvRD));
            var ss = (FvSS)Marshal.GetDelegateForFunctionPointer(qi(5), typeof(FvSS));
            var stopS = (FvStopS)Marshal.GetDelegateForFunctionPointer(qi(6), typeof(FvStopS));

            try { init(); } catch { return; }

            IntPtr session;
            if (cs(out session) != 0 || session == IntPtr.Zero) return;

            em(session, new uint[] { eCPUPkgTemp, eAvgFPS }, 2);
            ss(session);

            // Pre-allocate pinned sample buffer for CPU temp
            CPUPkgTemp tempBuf = new CPUPkgTemp();
            tempBuf.b.v = (uint)(Marshal.SizeOf(typeof(BaseMetric)) | (1 << 16));
            tempBuf.v = (uint)(Marshal.SizeOf(typeof(CPUPkgTemp)) | (1 << 16));
            GCHandle hTemp = GCHandle.Alloc(tempBuf, GCHandleType.Pinned);
            IntPtr pTemp = hTemp.AddrOfPinnedObject();

            // Pre-allocate pinned sample buffer for FPS
            AvgFPS[] fpsBuf = new AvgFPS[8];
            for (int i = 0; i < fpsBuf.Length; i++) {
                fpsBuf[i].b.v = (uint)(Marshal.SizeOf(typeof(BaseMetric)) | (1 << 16));
                fpsBuf[i].v = (uint)(Marshal.SizeOf(typeof(AvgFPS)) | (1 << 16));
                fpsBuf[i].f.v = (uint)(Marshal.SizeOf(typeof(FPS_v1)) | (1 << 16));
            }
            GCHandle hFps = GCHandle.Alloc(fpsBuf, GCHandleType.Pinned);
            IntPtr pFps = hFps.AddrOfPinnedObject();

            while (true) {
                try {
                    sd(session, 0);

                    // 1. Read CPU Temp
                    Samples sTemp = new Samples();
                    sTemp.v = (uint)(Marshal.SizeOf(typeof(Samples)) | (1 << 16));
                    sTemp.t = eCPUPkgTemp;
                    sTemp.n = (IntPtr)1;
                    sTemp.d = pTemp;

                    double cpuTemp = 0;
                    if (rd(session, ref sTemp, 1) == 0) {
                        CPUPkgTemp res = (CPUPkgTemp)Marshal.PtrToStructure(pTemp, typeof(CPUPkgTemp));
                        if (res.temp > 0) cpuTemp = Math.Round(res.temp);
                    }

                    // 2. Read Game FPS
                    uint fgPid = 0;
                    IntPtr fgWnd = GetForegroundWindow();
                    if (fgWnd != IntPtr.Zero) GetWindowThreadProcessId(fgWnd, out fgPid);

                    double fps = 0;
                    if (fgPid > 0) {
                        Samples sFps = new Samples();
                        sFps.v = (uint)(Marshal.SizeOf(typeof(Samples)) | (1 << 16));
                        sFps.t = eAvgFPS;
                        sFps.n = (IntPtr)fpsBuf.Length;
                        sFps.d = pFps;

                        if (rd(session, ref sFps, 1) == 0) {
                            int count = (int)sFps.n.ToInt64();
                            if (count > fpsBuf.Length) count = fpsBuf.Length;
                            for (int i = 0; i < count; i++) {
                                if (fpsBuf[i].f.pid == fgPid && fpsBuf[i].f.fps > 0) {
                                    fps = Math.Round(fpsBuf[i].f.fps);
                                    break;
                                }
                            }
                        }
                    }

                    // 3. Write cache file
                    string content = "[Variables]\r\nHardwareCpuTemp=" + (cpuTemp > 0 ? cpuTemp.ToString("0") : "--") + "\r\nHardwareFps=" + (fps > 0 ? fps.ToString("0") : "0") + "\r\n";
                    File.WriteAllText(cacheFile, content, System.Text.Encoding.ASCII);
                } catch { }

                Thread.Sleep(2000);
            }
        }
    }
}
