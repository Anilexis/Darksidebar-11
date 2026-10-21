# build-package.ps1
# Автоматическая сборка релизного пакета Darksidebar-11.rmskin для GitHub Releases и Scoop
param(
    [string]$Version = "1.0.0",
    [switch]$RebuildPlugin = $false
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$projectRoot = $PSScriptRoot
$skinName = "Darksidebar-11"
$skinsSource = Join-Path $projectRoot "Skins\$skinName"
$distDir = Join-Path $projectRoot "dist"
$rmskinFile = Join-Path $distDir "$skinName-v$Version.rmskin"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " Сборка $skinName v$Version (.rmskin)" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Пересборка NativeAOT плагина NvBridge, если запрошена
if ($RebuildPlugin -or -not (Test-Path "$skinsSource\@Resources\Plugins\NvBridge.dll")) {
    Write-Host "[1/4] Компиляция NativeAOT плагина NvBridgePlugin..." -ForegroundColor Yellow
    $csproj = Join-Path $projectRoot "src\NvBridgePlugin\NvBridgePlugin.csproj"
    dotnet publish -c Release -r win-x64 $csproj
    if ($LASTEXITCODE -ne 0) { throw "Ошибка компиляции плагина!" }
    
    $pubDll = Join-Path $projectRoot "src\NvBridgePlugin\bin\Release\net8.0\win-x64\publish\NvBridgePlugin.dll"
    $targetDll = Join-Path $skinsSource "@Resources\Plugins\NvBridge.dll"
    Copy-Item -Path $pubDll -Destination $targetDll -Force
    Write-Host "      Плагин NvBridge.dll скопирован в @Resources\Plugins\" -ForegroundColor Green
} else {
    Write-Host "[1/4] Плагин NvBridge.dll актуален." -ForegroundColor Green
}

# 2. Подготовка временной структуры дистрибутива
Write-Host "[2/4] Формирование структуры дистрибутива..." -ForegroundColor Yellow
$tempStaging = Join-Path ([System.IO.Path]::GetTempPath()) "Darksidebar_Staging_$([Guid]::NewGuid().ToString('N'))"
$stagingSkins = Join-Path $tempStaging "Skins\$skinName"
$stagingPlugins64 = Join-Path $tempStaging "Plugins\64bit"

New-Item -ItemType Directory -Path $stagingSkins -Force | Out-Null
New-Item -ItemType Directory -Path $stagingPlugins64 -Force | Out-Null

# Копируем чистые файлы скина
Copy-Item -Path "$skinsSource\*" -Destination $stagingSkins -Recurse -Force

# Копируем плагин в Plugins\64bit\ для стандартного Rainmeter Skin Installer
Copy-Item -Path "$skinsSource\@Resources\Plugins\NvBridge.dll" -Destination "$stagingPlugins64\NvBridge.dll" -Force

# 2.1 Деперсонализация настроек и подготовка шаблонов по умолчанию
Write-Host "      Деперсонализация настроек и кэшей дистрибутива..." -ForegroundColor Yellow
$stagingSettings = Join-Path $stagingSkins "@Resources\Settings.inc"
$stagingDefaultSettings = Join-Path $stagingSkins "@Resources\Settings.default.inc"

$sourceSettingsForTemplate = if (Test-Path $stagingDefaultSettings) { $stagingDefaultSettings } else { $stagingSettings }
if (Test-Path $sourceSettingsForTemplate) {
    $cp1251 = [System.Text.Encoding]::GetEncoding(1251)
    $text = [System.IO.File]::ReadAllText($sourceSettingsForTemplate, $cp1251)
    $text = $text -replace '(?m)^WeatherCity=.*$', 'WeatherCity=London'
    $text = $text -replace '(?m)^WeatherLat=.*$', 'WeatherLat=51.5074'
    $text = $text -replace '(?m)^WeatherLon=.*$', 'WeatherLon=-0.1278'
    $text = $text -replace '(?m)^WeatherCountryCode=.*$', 'WeatherCountryCode=GB'
    $text = $text -replace '(?m)^WeatherCountryName=.*$', 'WeatherCountryName=United Kingdom'
    $text = $text -replace '(?m)^MonitorTargetId=.*$', 'MonitorTargetId='
    $text = $text -replace '(?m)^MonitorFriendlyName=.*$', 'MonitorFriendlyName=Primary'
    $text = $text -replace '(?m)^MonitorFallbackDev=.*$', 'MonitorFallbackDev=\\.\DISPLAY1'
    $text = $text -replace '(?m)^FirstRunDone=.*$', 'FirstRunDone=0'
    [System.IO.File]::WriteAllText($stagingDefaultSettings, $text, $cp1251)
}

# КРИТИЧЕСКИ ВАЖНО: Удаляем Settings.inc из дистрибутива!
# При Merge=1 в Rainmeter.tag установщик Rainmeter обновит скин, но НЕ перезапишет Settings.inc пользователя!
if (Test-Path $stagingSettings) {
    Remove-Item -Path $stagingSettings -Force -ErrorAction SilentlyContinue
}

# 2.2 Подготовка шаблонов кэшей и защита пользовательских дисков
$stagingCache = Join-Path $stagingSkins "@Resources\Cache"
if (Test-Path $stagingCache) {
    $cleanDisksVars = "[Variables]`r`nDisksCount=1`r`nDivider4Y=668`r`nHardwareTitleY=688`r`nHardwareCpuY=713`r`nHardwareCpuBarY=727`r`nHardwareRamY=736`r`nHardwareRamBarY=750`r`nHardwareGpuY=759`r`nHardwareGpuBarY=773`r`nHardwareVramY=781`r`n"
    [System.IO.File]::WriteAllText((Join-Path $stagingCache "disks-vars.default.inc"), $cleanDisksVars, [System.Text.Encoding]::GetEncoding(1251))

    $sourceDisksDefault = Join-Path $skinsSource "@Resources\Cache\disks-generated.default.inc"
    if (Test-Path $sourceDisksDefault) {
        Copy-Item -Path $sourceDisksDefault -Destination (Join-Path $stagingCache "disks-generated.default.inc") -Force
    }

    # КРИТИЧЕСКИ ВАЖНО: Удаляем disks-generated.inc и disks-vars.inc из архива,
    # чтобы установщик Rainmeter не затирал дисковую топологию пользователя при обновлении
    Remove-Item -Path (Join-Path $stagingCache "disks-generated.inc") -Force -ErrorAction SilentlyContinue
    Remove-Item -Path (Join-Path $stagingCache "disks-vars.inc") -Force -ErrorAction SilentlyContinue

    [System.IO.File]::WriteAllText((Join-Path $stagingCache "weather-data.inc"), "[Variables]`r`n", [System.Text.Encoding]::GetEncoding(1251))
    [System.IO.File]::WriteAllText((Join-Path $stagingCache "hardware-data.inc"), "[Variables]`r`n", [System.Text.Encoding]::GetEncoding(1251))
    [System.IO.File]::WriteAllText((Join-Path $stagingCache "weather-search-status.inc"), "[Variables]`r`nWeatherSearchStatus=`r`nWeatherSearchFound=0`r`n", [System.Text.Encoding]::GetEncoding(1251))
    [System.IO.File]::WriteAllText((Join-Path $stagingCache "holidays.lua"), "-- holidays cache`r`nreturn {}`r`n", [System.Text.Encoding]::UTF8)
}

# 3. Формируем метаданные Rainmeter.tag
Write-Host "[3/4] Создание манифеста Rainmeter.tag..." -ForegroundColor Yellow
$tagContent = @"
[Rainmeter]
SkinName=$skinName
Author=Anilexis
Version=$Version
Merge=1
LoadType=Skin
Load=$skinName\Sidebar\Sidebar.ini
LoadSkin=$skinName\Sidebar\Sidebar.ini
"@
$tagPath = Join-Path $tempStaging "Rainmeter.tag"
[System.IO.File]::WriteAllText($tagPath, $tagContent, [System.Text.Encoding]::ASCII)

# 4. Упаковка в .rmskin
Write-Host "[4/4] Создание пакета $rmskinFile..." -ForegroundColor Yellow
if (-not (Test-Path $distDir)) {
    New-Item -ItemType Directory -Path $distDir -Force | Out-Null
}
if (Test-Path $rmskinFile) {
    Remove-Item -Path $rmskinFile -Force
}

$tempZip = Join-Path $distDir "temp_archive.zip"
if (Test-Path $tempZip) { Remove-Item -Path $tempZip -Force }

Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::CreateFromDirectory($tempStaging, $tempZip, [System.IO.Compression.CompressionLevel]::Optimal, $false)

# Переименовываем в .rmskin
Move-Item -Path $tempZip -Destination $rmskinFile -Force

# Очистка staging
Remove-Item -Path $tempStaging -Recurse -Force -ErrorAction SilentlyContinue

$sizeKb = [math]::Round((Get-Item $rmskinFile).Length / 1024, 1)
$sha256 = (Get-FileHash -Path $rmskinFile -Algorithm SHA256).Hash

Write-Host "==========================================================" -ForegroundColor Green
Write-Host " ПАКЕТ УСПЕШНО СОБРАН!" -ForegroundColor Green
Write-Host " Файл:    $rmskinFile" -ForegroundColor Cyan
Write-Host " Размер:  $sizeKb КБ" -ForegroundColor Cyan
Write-Host " SHA256:  $sha256" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Green
