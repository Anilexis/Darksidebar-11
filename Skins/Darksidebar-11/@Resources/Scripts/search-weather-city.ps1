# search-weather-city.ps1
# Поиск города через Open-Meteo Geocoding API и сохранение координат и страны в Settings.inc
param(
    [string]$Query = ""
)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12 -bor [System.Net.SecurityProtocolType]::Tls11 -bor [System.Net.SecurityProtocolType]::Tls

$scriptsDir = $PSScriptRoot
$resourcesDir = Split-Path $scriptsDir
$settingsPath = Join-Path $resourcesDir "Settings.inc"
$cacheDir = Join-Path $resourcesDir "Cache"
$statusFile = Join-Path $cacheDir "weather-search-status.inc"

if (-not (Test-Path $cacheDir)) {
    New-Item -ItemType Directory -Path $cacheDir -Force | Out-Null
}

$currentCity = "London"
$langCode = "ru"

if (Test-Path $settingsPath) {
    $bytes = [System.IO.File]::ReadAllBytes($settingsPath)
    $utf8Text = [System.Text.Encoding]::UTF8.GetString($bytes)
    $cp1251Text = [System.Text.Encoding]::GetEncoding(1251).GetString($bytes)
    
    $cityCandidate = ""
    if ($utf8Text -match '(?m)^\s*WeatherCity\s*=\s*(.*?)\s*$') {
        $cityCandidate = $Matches[1].Trim()
    }
    
    if ($cityCandidate -match '^[A-Za-z0-9\s\.\-]+$' -or ($cityCandidate -match '[\u0400-\u04FF]' -and $cityCandidate -notmatch '[РЎ][\x80-\xBF]')) {
        $currentCity = $cityCandidate
    } else {
        if ($cp1251Text -match '(?m)^\s*WeatherCity\s*=\s*(.*?)\s*$') {
            $currentCity = $Matches[1].Trim()
        }
    }
    
    if ($utf8Text -match '(?m)^\s*Language\s*=\s*English' -or $cp1251Text -match '(?m)^\s*Language\s*=\s*English') {
        $langCode = "en"
    }
}

if ([string]::IsNullOrWhiteSpace($Query)) {
    $Query = $currentCity
} else {
    $Query = $Query.Trim()
}

if ([string]::IsNullOrWhiteSpace($Query)) {
    exit 0
}

$cityName = ""
$lat = 0.0
$lon = 0.0
$countryCode = "RU"
$countryName = "Россия"

# 1. Проверяем, не введены ли прямые координаты: "57.15, 65.52" или "57.15 65.52"
if ($Query -match '^\s*([+-]?\d+(?:\.\d+)?)[,\s]+([+-]?\d+(?:\.\d+)?)\s*$') {
    $lat = [double]$Matches[1]
    $lon = [double]$Matches[2]
    $cityName = if ($langCode -eq "en") { "Custom" } else { "Координаты" }
} else {
    # 2. Поиск города через Open-Meteo Geocoding API
    try {
        $searchLang = if ($Query -match '[\u0400-\u04FF]') { "ru" } else { $langCode }
        $encoded = [Uri]::EscapeDataString($Query)
        $url = "https://geocoding-api.open-meteo.com/v1/search?name=$encoded&count=1&language=$searchLang&format=json"
        $res = Invoke-RestMethod -Uri $url -Headers @{ "User-Agent" = "Mozilla/5.0 Darksidebar-11/1.0.0" } -TimeoutSec 5 -ErrorAction Stop
        $items = @($res.results)
        if ($items.Count -eq 0) {
            $altLang = if ($searchLang -eq "ru") { "en" } else { "ru" }
            $url2 = "https://geocoding-api.open-meteo.com/v1/search?name=$encoded&count=1&language=$altLang&format=json"
            $res2 = Invoke-RestMethod -Uri $url2 -Headers @{ "User-Agent" = "Mozilla/5.0 Darksidebar-11/1.0.0" } -TimeoutSec 5 -ErrorAction SilentlyContinue
            if ($res2 -and $res2.results) { $items = @($res2.results) }
        }
        if ($items.Count -gt 0) {
            $first = $items[0]
            $cityName = [string]$first.name
            $lat = [double]$first.latitude
            $lon = [double]$first.longitude
            if ($first.country_code) { 
                $countryCode = [string]$first.country_code.ToUpperInvariant() 
            }
            if ($first.country) { 
                $countryName = [string]$first.country 
            }
        }
    } catch {
        Write-Host "Geocoding error: $($_.Exception.Message)"
    }
}

$cp1251 = [System.Text.Encoding]::GetEncoding(1251)

if ($cityName -and $lat -ne 0.0) {
    $latStr = $lat.ToString("0.0000", [System.Globalization.CultureInfo]::InvariantCulture)
    $lonStr = $lon.ToString("0.0000", [System.Globalization.CultureInfo]::InvariantCulture)

    if (Test-Path $settingsPath) {
        $content = [System.IO.File]::ReadAllText($settingsPath, $cp1251)
        $content = $content -replace '(?m)^WeatherCity=.*$', "WeatherCity=$cityName"
        $content = $content -replace '(?m)^WeatherLat=.*$', "WeatherLat=$latStr"
        $content = $content -replace '(?m)^WeatherLon=.*$', "WeatherLon=$lonStr"

        if ($content -match '(?m)^WeatherCountryCode=.*$') {
            $content = $content -replace '(?m)^WeatherCountryCode=.*$', "WeatherCountryCode=$countryCode"
        } else {
            $content += "`nWeatherCountryCode=$countryCode"
        }
        if ($content -match '(?m)^WeatherCountryName=.*$') {
            $content = $content -replace '(?m)^WeatherCountryName=.*$', "WeatherCountryName=$countryName"
        } else {
            $content += "`nWeatherCountryName=$countryName"
        }

        [System.IO.File]::WriteAllText($settingsPath, $content, $cp1251)
    }

    $statusContent = @"
[Variables]
WeatherSearchStatus=Найдено: $cityName ($latStr, $lonStr)
WeatherSearchFound=1
"@
    [System.IO.File]::WriteAllText($statusFile, $statusContent, $cp1251)
    Write-Host "Success: $cityName ($latStr, $lonStr), Country: $countryCode"

    # Автоматически обновляем праздники по найденной стране
    $fetchHolidays = Join-Path $scriptsDir "fetch-holidays.ps1"
    if (Test-Path $fetchHolidays) {
        & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $fetchHolidays -CountryCode $countryCode
    }
} else {
    $statusContent = @"
[Variables]
WeatherSearchStatus=Не найдено: $Query
WeatherSearchFound=0
"@
    [System.IO.File]::WriteAllText($statusFile, $statusContent, $cp1251)
    Write-Host "Not found: $Query"
}

# Отправляем команды обновления в Rainmeter
$rainmeterExe = "C:\Program Files\Rainmeter\Rainmeter.exe"
if (Test-Path $rainmeterExe) {
    & $rainmeterExe !Refresh "Darksidebar-11\Sidebar"
    & $rainmeterExe !Refresh "Darksidebar-11\Settings"
}
