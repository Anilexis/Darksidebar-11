# DetectWeatherIpTests.ps1
# Pester tests for detect-weather-ip.ps1 (API fallback and dual-failure graceful handling)

BeforeAll {
    $scriptRoot = $PSScriptRoot
    $repoRoot = Split-Path $scriptRoot -Parent
    $scriptPath = Join-Path $repoRoot "Skins/Darksidebar-11/@Resources/Scripts/detect-weather-ip.ps1"
}

Describe 'detect-weather-ip.ps1 Fallback & Resilience' {
    BeforeEach {
        $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ("ds_test_" + [System.Guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
        $testSettings = Join-Path $tempDir "Settings.inc"
        $testPersist = Join-Path $tempDir "Persist"
        New-Item -ItemType Directory -Path $testPersist -Force | Out-Null

        $initialContent = @"
[Variables]
WeatherCity=London
WeatherLat=51.5074
WeatherLon=-0.1278
WeatherCountryCode=GB
WeatherCountryName=United Kingdom
"@
        $cp1251 = [System.Text.Encoding]::GetEncoding(1251)
        [System.IO.File]::WriteAllText($testSettings, $initialContent, $cp1251)
    }

    AfterEach {
        if (Test-Path $tempDir) {
            Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It 'Successfully updates settings when primary API (ipwho.is) succeeds' {
        Mock -CommandName Invoke-RestMethod -MockWith {
            param($Uri)
            if ($Uri -like '*ipwho.is*') {
                return [PSCustomObject]@{
                    success = $true
                    city = 'Amsterdam'
                    latitude = 52.3676
                    longitude = 4.9041
                    country_code = 'NL'
                    country = 'Netherlands'
                }
            }
            throw "Secondary API should not be called"
        }

        { & $scriptPath -SettingsFilePath $testSettings -PersistentConfigDir $testPersist } | Should -Not -Throw

        $cp1251 = [System.Text.Encoding]::GetEncoding(1251)
        $result = [System.IO.File]::ReadAllText($testSettings, $cp1251)
        $result | Should -Match 'WeatherCity=Amsterdam'
        $result | Should -Match 'WeatherLat=52\.3676'
        $result | Should -Match 'WeatherLon=4\.9041'
        $result | Should -Match 'WeatherCountryCode=NL'
        $result | Should -Match 'WeatherCountryName=Netherlands'
    }

    It 'Falls back to secondary API (ip-api.com) when primary API fails' {
        Mock -CommandName Invoke-RestMethod -MockWith {
            param($Uri)
            if ($Uri -like '*ipwho.is*') {
                throw [System.Net.WebException]::new("Primary service timeout")
            }
            if ($Uri -like '*ip-api.com*') {
                return [PSCustomObject]@{
                    status = 'success'
                    city = 'Tokyo'
                    lat = 35.6762
                    lon = 139.6503
                    countryCode = 'JP'
                    country = 'Japan'
                }
            }
            throw "Unknown Uri $Uri"
        }

        { & $scriptPath -SettingsFilePath $testSettings -PersistentConfigDir $testPersist } | Should -Not -Throw

        $cp1251 = [System.Text.Encoding]::GetEncoding(1251)
        $result = [System.IO.File]::ReadAllText($testSettings, $cp1251)
        $result | Should -Match 'WeatherCity=Tokyo'
        $result | Should -Match 'WeatherLat=35\.6762'
        $result | Should -Match 'WeatherLon=139\.6503'
        $result | Should -Match 'WeatherCountryCode=JP'
        $result | Should -Match 'WeatherCountryName=Japan'
    }

    It 'Gracefully handles failure without throwing unhandled exceptions when BOTH APIs fail' {
        Mock -CommandName Invoke-RestMethod -MockWith {
            param($Uri)
            throw [System.Net.WebException]::new("Connection refused to $Uri")
        }

        { & $scriptPath -SettingsFilePath $testSettings -PersistentConfigDir $testPersist } | Should -Not -Throw

        # Settings should remain unchanged
        $cp1251 = [System.Text.Encoding]::GetEncoding(1251)
        $result = [System.IO.File]::ReadAllText($testSettings, $cp1251)
        $result | Should -Match 'WeatherCity=London'
        $result | Should -Match 'WeatherLat=51\.5074'
        $result | Should -Match 'WeatherLon=-0\.1278'
        $result | Should -Match 'WeatherCountryCode=GB'
    }
}
