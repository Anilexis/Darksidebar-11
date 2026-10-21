using System;
using System.Runtime.InteropServices;
using Xunit;

namespace NvBridgePlugin.Tests {
    public class MeasureInstanceTests {
        [Fact]
        public void GetString_CpuModel_ReturnsConfiguredModel() {
            HardwareEngine.CpuModel = "AMD Ryzen 7 7800X3D";
            var measure = new MeasureInstance { Metric = "cpumodel" };

            IntPtr ptr = measure.GetString();
            string? result = Marshal.PtrToStringUni(ptr);
            measure.Dispose();

            Assert.Equal("AMD Ryzen 7 7800X3D", result);
        }

        [Theory]
        [InlineData(72.4, "72")]
        [InlineData(45.0, "45")]
        [InlineData(0.0, "--")]
        [InlineData(-5.0, "--")]
        public void GetString_CpuTemp_FormatsCorrectly(double temp, string expected) {
            HardwareEngine.CpuTemp = temp;
            var measure = new MeasureInstance { Metric = "cputemp" };

            IntPtr ptr = measure.GetString();
            string? result = Marshal.PtrToStringUni(ptr);
            measure.Dispose();

            Assert.Equal(expected, result);
        }

        [Fact]
        public void GetString_GpuModel_ReturnsConfiguredModel() {
            HardwareEngine.GpuModel = "GeForce RTX 4080";
            var measure = new MeasureInstance { Metric = "gpumodel" };

            IntPtr ptr = measure.GetString();
            string? result = Marshal.PtrToStringUni(ptr);
            measure.Dispose();

            Assert.Equal("GeForce RTX 4080", result);
        }

        [Theory]
        [InlineData(65.0, "65")]
        [InlineData(0.0, "--")]
        public void GetString_GpuTemp_FormatsCorrectly(double temp, string expected) {
            HardwareEngine.GpuTemp = temp;
            var measure = new MeasureInstance { Metric = "gputemp" };

            IntPtr ptr = measure.GetString();
            string? result = Marshal.PtrToStringUni(ptr);
            measure.Dispose();

            Assert.Equal(expected, result);
        }

        [Fact]
        public void GetString_GpuLoad_FormatsCorrectly() {
            HardwareEngine.GpuLoad = 87.6;
            var measure = new MeasureInstance { Metric = "gpuload" };

            IntPtr ptr = measure.GetString();
            string? result = Marshal.PtrToStringUni(ptr);
            measure.Dispose();

            Assert.Equal("88", result);
        }

        [Theory]
        [InlineData(92.0, 68.0, "92% | 68°C")]
        [InlineData(50.0, 0.0, "50% | --°C")]
        public void GetString_GpuSummary_FormatsCorrectly(double load, double temp, string expected) {
            HardwareEngine.GpuLoad = load;
            HardwareEngine.GpuTemp = temp;
            var measure = new MeasureInstance { Metric = "gpusummary" };

            IntPtr ptr = measure.GetString();
            string? result = Marshal.PtrToStringUni(ptr);
            measure.Dispose();

            Assert.Equal(expected, result);
        }

        [Theory]
        [InlineData(8.5, 16.0, "VRAM: 8.5 / 16.0 GiB")]
        [InlineData(0.0, 0.0, "VRAM: -- / -- GiB")]
        public void GetString_VramSummary_FormatsWithInvariantDot(double used, double total, string expected) {
            HardwareEngine.VramUsed = used;
            HardwareEngine.VramTotal = total;
            var measure = new MeasureInstance { Metric = "vramsummary" };

            IntPtr ptr = measure.GetString();
            string? result = Marshal.PtrToStringUni(ptr);
            measure.Dispose();

            Assert.Equal(expected, result);
        }

        [Theory]
        [InlineData(144.0, "FPS: 144")]
        [InlineData(0.0, "FPS: —")]
        [InlineData(-1.0, "FPS: —")]
        public void GetString_Fps_FormatsCorrectly(double fps, string expected) {
            HardwareEngine.Fps = fps;
            var measure = new MeasureInstance { Metric = "fps" };

            IntPtr ptr = measure.GetString();
            string? result = Marshal.PtrToStringUni(ptr);
            measure.Dispose();

            Assert.Equal(expected, result);
        }

        [Fact]
        public void GetString_UnknownMetric_ReturnsEmpty() {
            var measure = new MeasureInstance { Metric = "unknown_xyz" };

            IntPtr ptr = measure.GetString();
            string? result = Marshal.PtrToStringUni(ptr);
            measure.Dispose();

            Assert.Equal("", result);
        }

        [Fact]
        public void Update_ReturnsNumericValuesMatchingHardwareEngine() {
            HardwareEngine.CpuTemp = 55;
            HardwareEngine.GpuTemp = 60;
            HardwareEngine.GpuLoad = 40;
            HardwareEngine.VramUsed = 4.2;
            HardwareEngine.VramTotal = 16.0;
            HardwareEngine.Fps = 120;

            Assert.Equal(55, new MeasureInstance { Metric = "cputemp" }.Update());
            Assert.Equal(60, new MeasureInstance { Metric = "gputemp" }.Update());
            Assert.Equal(40, new MeasureInstance { Metric = "gpuload" }.Update());
            Assert.Equal(4.2, new MeasureInstance { Metric = "vramused" }.Update());
            Assert.Equal(16.0, new MeasureInstance { Metric = "vramtotal" }.Update());
            Assert.Equal(120, new MeasureInstance { Metric = "fps" }.Update());
            Assert.Equal(0.0, new MeasureInstance { Metric = "unknown" }.Update());
        }

        [Fact]
        public void Dispose_CanBeCalledMultipleTimesSafely() {
            var measure = new MeasureInstance { Metric = "cputemp" };
            HardwareEngine.CpuTemp = 50;
            measure.GetString();
            measure.Dispose();
            measure.Dispose(); // second call should not throw
        }
    }
}
