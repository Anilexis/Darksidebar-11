# Darksidebar-11

<p align="center">
  <img src="assets/preview.png" alt="Darksidebar-11 Preview" width="240" />
</p>

<p align="center">
  <b>Modern, hardware-accelerated multifunctional desktop sidebar for Rainmeter on Windows 11.</b>
</p>

<p align="center">
  <a href="https://github.com/Anilexis/Darksidebar-11/releases/latest"><img src="https://img.shields.io/github/v/release/Anilexis/Darksidebar-11?style=flat-square&color=00B4FF" alt="GitHub release"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square" alt="License: MIT"></a>
  <a href="https://www.rainmeter.net/"><img src="https://img.shields.io/badge/Rainmeter-4.5.18%2B-informational?style=flat-square" alt="Rainmeter 4.5.18+"></a>
  <img src="https://img.shields.io/badge/Windows-10%20%7C%2011%20x64-blue?style=flat-square" alt="Windows 10/11 x64">
</p>

---

<p align="center">
  <a href="#english">English</a> • <a href="README.ru.md">Русская версия</a>
</p>

---

<a name="english"></a>
## 🚀 Features

- **🎨 Modern Windows 11 Glass Aesthetic:** Designed with a 240px clean dark layout (`#121212` with 86% opacity), subtle 1px border, and crisp typography.
- **🕒 Precision Analog Clock:** High-precision analog clock with customizable hand thickness and clean digital date.
- **📅 Interactive Calendar:** Full monthly grid, Monday/Sunday first-day toggle, today indicator, previous/next month navigation, national holiday highlights, and quick launcher.
- **⛅ Open-Meteo Weather:** Real-time weather and 3-day forecast via Open-Meteo API (no API key required), automatic IP-based location detection on first run, city search, and metric/imperial unit toggle.
- **💾 Dynamic Drive Monitor:** Automatically detects all connected fixed drives (C:, D:, etc.), displays free space and usage percentage bars. Single click opens the drive root in File Explorer.
- **⚡ Zero-Overhead Hardware Telemetry:** Custom NativeAOT in-process plugin (`NvBridge.dll`) written in C# .NET 8. Directly queries CPU Package temperature, GPU load/temperature/VRAM via NVML, and active game FPS with **0.00% CPU usage** without requiring LibreHardwareMonitor or RTSS.
- **🖥️ Smart Display Binding:** Binds cleanly to any selected display (including multi-monitor setups) by hardware PnP ID, adhering to work area boundaries and taskbars.
- **⚙️ Built-in GUI Settings:** Interactive configuration panel (accessible via the gear button or right-click) to configure monitors, weather location, units, fonts, languages, and app shortcuts.

---

## 📦 Installation

### Option 1: 1-Click Install (.rmskin) — Recommended

1. Download the latest **`Darksidebar-11-v1.0.0.rmskin`** from [GitHub Releases](https://github.com/Anilexis/Darksidebar-11/releases/latest).
2. Double-click the downloaded file.
3. Rainmeter's Skin Installer will open automatically. Click **Install**.
4. The sidebar will immediately appear on your primary screen!

> **Prerequisite:** Make sure [Rainmeter](https://www.rainmeter.net/) (v4.5.18 or newer) is installed on your computer.

---

### Option 2: Scoop Package Manager

If you use [Scoop](https://scoop.sh/), you can install and update Darksidebar-11 effortlessly:

```powershell
# 1. Add the Darksidebar-11 bucket
scoop bucket add darksidebar https://github.com/Anilexis/Darksidebar-11

# 2. Install the skin
scoop install darksidebar-11

# 3. Update whenever a new version is released
scoop update darksidebar-11
```

---

## ⚙️ Configuration

Click the **Gear icon** in the top-right corner of the sidebar or right-click the skin to open the **Settings** window:

- **Target Monitor:** Choose which display to place the sidebar on (Primary, Secondary, or custom).
- **Placement:** Dock to the Right or Left screen edge with custom margins.
- **Weather & Location:** Search any city worldwide or click *Auto-detect by IP*.
- **Units:** Toggle between Celsius (°C) and Fahrenheit (°F).
- **Calendar & Clock:** Set first day of week (Monday/Sunday) and clock hand thickness (Thin, Normal, Thick).
- **App Launchers:** Assign custom apps to launch when clicking the Calendar or Weather modules.
- **Language:** Seamlessly switch between English and Russian on the fly.

---

## 🛠️ Building from Source

To compile the NativeAOT hardware telemetry plugin and build the `.rmskin` package locally:

1. Clone this repository:
   ```powershell
   git clone https://github.com/Anilexis/Darksidebar-11.git
   cd Darksidebar-11
   ```
2. Build the package using PowerShell:
   ```powershell
   .\build-package.ps1 -Version "1.0.0" -RebuildPlugin
   ```
   The resulting `.rmskin` file will be generated in the `dist/` directory.

---

## 📄 License

Distributed under the [MIT License](LICENSE).
