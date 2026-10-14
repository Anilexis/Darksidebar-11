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
$tempStaging = Join-Path $env:TEMP "Darksidebar_Staging_$([Guid]::NewGuid().ToString('N'))"
$stagingSkins = Join-Path $tempStaging "Skins\$skinName"
$stagingPlugins64 = Join-Path $tempStaging "Plugins\64bit"

New-Item -ItemType Directory -Path $stagingSkins -Force | Out-Null
New-Item -ItemType Directory -Path $stagingPlugins64 -Force | Out-Null

# Копируем чистые файлы скина
Copy-Item -Path "$skinsSource\*" -Destination $stagingSkins -Recurse -Force

# Копируем плагин в Plugins\64bit\ для стандартного Rainmeter Skin Installer
Copy-Item -Path "$skinsSource\@Resources\Plugins\NvBridge.dll" -Destination "$stagingPlugins64\NvBridge.dll" -Force

# Для релизного пакета гарантируем UTF-8 с BOM
$stagingSettings = Join-Path $stagingSkins "@Resources\Settings.inc"
if (Test-Path $stagingSettings) {
    $utf8BOM = [System.Text.UTF8Encoding]::new($true)
    $text = [System.IO.File]::ReadAllText($stagingSettings, [System.Text.Encoding]::UTF8)
    [System.IO.File]::WriteAllText($stagingSettings, $text, $utf8BOM)
}

# 3. Формируем метаданные Rainmeter.tag
Write-Host "[3/4] Создание манифеста Rainmeter.tag..." -ForegroundColor Yellow
$tagContent = @"
[Rainmeter]
SkinName=$skinName
Author=Anilexis
Version=$Version
Merge=0
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
