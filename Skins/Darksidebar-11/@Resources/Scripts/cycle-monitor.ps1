# cycle-monitor.ps1
# Переключение активного монитора (вперед / назад) для Darksidebar-11
param(
    [ValidateSet("Next", "Prev")]
    [string]$Direction = "Next"
)

$scriptsDir = $PSScriptRoot
$resourcesDir = Split-Path $scriptsDir
$settingsPath = Join-Path $resourcesDir "Settings.inc"
$detectScript = Join-Path $scriptsDir "detect-monitors.ps1"

if (-not (Test-Path $detectScript) -or -not (Test-Path $settingsPath)) { exit }

# Получаем текущие настройки
$currentPnpId = ""
$lines = Get-Content $settingsPath -Encoding UTF8 -ErrorAction SilentlyContinue
foreach ($l in $lines) {
    if ($l -match '^\s*MonitorTargetId\s*=\s*(.*?)\s*$') {
        $currentPnpId = $Matches[1].Trim()
    }
}

# Обнаруживаем все мониторы
$monitors = & $detectScript
if (-not $monitors -or $monitors.Count -eq 0) { exit }

$currentIndex = 0
for ($i = 0; $i -lt $monitors.Count; $i++) {
    if ($monitors[$i].PnpId -eq $currentPnpId -or $currentPnpId.Contains($monitors[$i].PnpId)) {
        $currentIndex = $i
        break
    }
}

$nextIndex = if ($Direction -eq "Next") {
    ($currentIndex + 1) % $monitors.Count
} else {
    ($currentIndex - 1 + $monitors.Count) % $monitors.Count
}

$selected = $monitors[$nextIndex]
$newPnpId = $selected.PnpId
$newFriendly = $selected.FriendlyName
$newDev = $selected.DeviceName

# Обновляем Settings.inc
$content = Get-Content $settingsPath -Raw -Encoding UTF8
$content = $content -replace '(?m)^MonitorTargetId=.*$', "MonitorTargetId=$newPnpId"
$content = $content -replace '(?m)^MonitorFriendlyName=.*$', "MonitorFriendlyName=$newFriendly"
$content = $content -replace '(?m)^MonitorFallbackDev=.*$', "MonitorFallbackDev=$newDev"

[System.IO.File]::WriteAllText($settingsPath, $content, [System.Text.UTF8Encoding]::new($false))
Write-Host "Switched to monitor: $newFriendly ($newDev)"
