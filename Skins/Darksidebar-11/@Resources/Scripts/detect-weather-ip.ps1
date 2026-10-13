# detect-weather-ip.ps1
# Автоопределение города, координат и страны по текущему IP
$scriptsDir = $PSScriptRoot
$resourcesDir = Split-Path $scriptsDir
$settingsPath = Join-Path $resourcesDir "Settings.inc"

$city = ""
$lat = 0.0
$lon = 0.0
$countryCode = "RU"
$countryName = "Россия"

try {
    $res = Invoke-RestMethod -Uri "https://ipwho.is/" -TimeoutSec 5 -ErrorAction Stop
    if ($res.success) {
        $city = [string]$res.city
        $lat = [double]$res.latitude
        $lon = [double]$res.longitude
        if ($res.country_code) { $countryCode = [string]$res.country_code.ToUpperInvariant() }
        if ($res.country) { $countryName = [string]$res.country }
    }
} catch {
    try {
        $res = Invoke-RestMethod -Uri "http://ip-api.com/json/" -TimeoutSec 5 -ErrorAction Stop
        if ($res.status -eq 'success') {
            $city = [string]$res.city
            $lat = [double]$res.lat
            $lon = [double]$res.lon
            if ($res.countryCode) { $countryCode = [string]$res.countryCode.ToUpperInvariant() }
            if ($res.country) { $countryName = [string]$res.country }
        }
    } catch { }
}

if ($city -and $lat -ne 0.0) {
    if (Test-Path $settingsPath) {
        $latStr = $lat.ToString("0.0000", [System.Globalization.CultureInfo]::InvariantCulture)
        $lonStr = $lon.ToString("0.0000", [System.Globalization.CultureInfo]::InvariantCulture)

        $cp1251 = [System.Text.Encoding]::GetEncoding(1251)
        $content = [System.IO.File]::ReadAllText($settingsPath, $cp1251)
        $content = $content -replace '(?m)^WeatherCity=.*$', "WeatherCity=$city"
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
        Write-Host "Updated weather location: $city ($latStr, $lonStr), Country: $countryCode"

        # Обновляем праздники для определенной страны
        $fetchHolidays = Join-Path $scriptsDir "fetch-holidays.ps1"
        if (Test-Path $fetchHolidays) {
            & pwsh -NoProfile -ExecutionPolicy Bypass -File $fetchHolidays -CountryCode $countryCode
        }
    }
}
