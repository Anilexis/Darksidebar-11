# switch-language.ps1
# Переключение языка интерфейса и адаптивный перевод текущего города
param(
    [string]$NewLang = "Russian"
)

$scriptsDir = $PSScriptRoot
$resourcesDir = Split-Path $scriptsDir
$settingsPath = Join-Path $resourcesDir "Settings.inc"

if (-not (Test-Path $settingsPath)) { exit }

$cp1251 = [System.Text.Encoding]::GetEncoding(1251)
$content = [System.IO.File]::ReadAllText($settingsPath, $cp1251)

$currentCity = "London"
$currentLat = "57.1522"
$currentLon = "65.5272"

if ($content -match '(?m)^WeatherCity=(.*)$') { $currentCity = $Matches[1].Trim() }
if ($content -match '(?m)^WeatherLat=(.*)$') { $currentLat = $Matches[1].Trim() }
if ($content -match '(?m)^WeatherLon=(.*)$') { $currentLon = $Matches[1].Trim() }

$dictRuToEn = @{
    "London" = "Лондон"
    "Москва" = "Moscow"
    "Санкт-Петербург" = "St. Petersburg"
    "Екатеринбург" = "Yekaterinburg"
    "Новосибирск" = "Novosibirsk"
    "Казань" = "Kazan"
    "Нижний Новгород" = "Nizhny Novgorod"
    "Самара" = "Samara"
    "Омск" = "Omsk"
    "Челябинск" = "Chelyabinsk"
    "Уфа" = "Ufa"
    "Красноярск" = "Krasnoyarsk"
}

$dictEnToRu = @{
    "Лондон" = "London"
    "Moscow" = "Москва"
    "St. Petersburg" = "Санкт-Петербург"
    "Saint Petersburg" = "Санкт-Петербург"
    "Yekaterinburg" = "Екатеринбург"
    "Ekaterinburg" = "Екатеринбург"
    "Novosibirsk" = "Новосибирск"
    "Kazan" = "Казань"
    "Nizhny Novgorod" = "Нижний Новгород"
    "Samara" = "Самара"
    "Omsk" = "Омск"
    "Челябинск" = "Челябинск"
    "Ufa" = "Уфа"
    "Красноярск" = "Красноярск"
}

$newCity = $currentCity

if ($NewLang -eq "English") {
    if ($dictRuToEn.ContainsKey($currentCity)) {
        $newCity = $dictRuToEn[$currentCity]
    } else {
        try {
            $enc = [Uri]::EscapeDataString($currentCity)
            $url = "https://geocoding-api.open-meteo.com/v1/search?name=$enc&count=1&language=en&format=json"
            $res = Invoke-RestMethod -Uri $url -TimeoutSec 4 -Headers @{ "User-Agent" = "Darksidebar-11/1.0.0" }
            if ($res.results -and $res.results.Count -gt 0) {
                $newCity = $res.results[0].name
            }
        } catch { }
    }
} else {
    if ($dictEnToRu.ContainsKey($currentCity)) {
        $newCity = $dictEnToRu[$currentCity]
    } else {
        try {
            $enc = [Uri]::EscapeDataString($currentCity)
            $url = "https://geocoding-api.open-meteo.com/v1/search?name=$enc&count=1&language=ru&format=json"
            $res = Invoke-RestMethod -Uri $url -TimeoutSec 4 -Headers @{ "User-Agent" = "Darksidebar-11/1.0.0" }
            if ($res.results -and $res.results.Count -gt 0) {
                $newCity = $res.results[0].name
            }
        } catch { }
    }
}

$content = $content -replace '(?m)^Language=.*$', "Language=$NewLang"
$content = $content -replace '(?m)^WeatherCity=.*$', "WeatherCity=$newCity"

[System.IO.File]::WriteAllText($settingsPath, $content, $cp1251)

# Purge any WeatherCity from cache file so cache never overrides translated city
$cachePath = Join-Path $resourcesDir "Cache\weather-data.inc"
if (Test-Path $cachePath) {
    try {
        $c = [System.IO.File]::ReadAllText($cachePath, $cp1251)
        $c = $c -replace '(?m)^WeatherCity=.*?\r?\n', ''
        [System.IO.File]::WriteAllText($cachePath, $c, $cp1251)
    } catch { }
}

Write-Host "Switched to $NewLang, City: $newCity"
