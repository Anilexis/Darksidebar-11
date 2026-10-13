# open-weather-app.ps1
$scriptsDir = $PSScriptRoot
$resourcesDir = Split-Path $scriptsDir
$settingsPath = Join-Path $resourcesDir "Settings.inc"

$appType = "System"
$appPath = ""
$city = "London"
$lat = "57.1522"
$lon = "65.5272"

if (Test-Path $settingsPath) {
    try {
        $cp1251 = [System.Text.Encoding]::GetEncoding(1251)
        $lines = [System.IO.File]::ReadAllLines($settingsPath, $cp1251)
        foreach ($line in $lines) {
            if ($line -match '^\s*WeatherAppType\s*=\s*(.*?)\s*$') { $appType = $Matches[1].Trim() }
            if ($line -match '^\s*WeatherAppPath\s*=\s*(.*?)\s*$') { $appPath = $Matches[1].Trim() }
            if ($line -match '^\s*WeatherCity\s*=\s*(.*?)\s*$') { $city = $Matches[1].Trim() }
            if ($line -match '^\s*WeatherLat\s*=\s*(.*?)\s*$') { $lat = $Matches[1].Trim() }
            if ($line -match '^\s*WeatherLon\s*=\s*(.*?)\s*$') { $lon = $Matches[1].Trim() }
            # Legacy
            if ($line -match '^\s*WeatherApp\s*=\s*(.*?)\s*$') {
                if ($Matches[1].Trim() -eq "Web") {
                    $appType = "System"
                }
            }
        }
    } catch { }
}

if ($appType -eq "None") {
    # Disabled, do nothing
    exit
} elseif ($appType -eq "System") {
    try {
        Start-Process "msnweather:" -ErrorAction Stop
    } catch {
        try {
            Start-Process "bingweather:" -ErrorAction Stop
        } catch {
            $enc = [Uri]::EscapeDataString($city)
            Start-Process "https://www.google.com/search?q=weather+$enc"
        }
    }
} elseif ($appType -eq "Custom") {
    if ($appPath -and (Test-Path $appPath)) {
        Start-Process $appPath
    } else {
        $enc = [Uri]::EscapeDataString($city)
        Start-Process "https://www.google.com/search?q=weather+$enc"
    }
}
