-- Weather.lua for Darksidebar-11 (Version 3.5 Standalone)
-- Native Rainmeter Lua parser for Open-Meteo API JSON
-- Zero external processes: runs 100% inside Rainmeter.exe

local cachePath = ""

local function GetWmoDescription(code, lang)
    code = math.floor(tonumber(code) or 0)
    if lang == "English" then
        if code == 0 then return "clear"
        elseif code == 1 then return "mainly clear"
        elseif code == 2 then return "partly cloudy"
        elseif code == 3 then return "overcast"
        elseif code == 45 or code == 48 then return "fog"
        elseif code == 51 then return "light drizzle"
        elseif code == 53 then return "moderate drizzle"
        elseif code == 55 then return "dense drizzle"
        elseif code == 61 then return "slight rain"
        elseif code == 63 then return "rain"
        elseif code == 65 then return "heavy rain"
        elseif code == 71 then return "slight snow"
        elseif code == 73 then return "snowfall"
        elseif code == 75 then return "heavy snow"
        elseif code == 77 then return "snow grains"
        elseif code == 80 then return "rain showers"
        elseif code == 81 then return "showers"
        elseif code == 82 then return "violent showers"
        elseif code == 85 then return "snow showers"
        elseif code == 86 then return "blizzard"
        elseif code == 95 then return "thunderstorm"
        elseif code == 96 then return "thunder & hail"
        elseif code == 99 then return "heavy storm"
        else return "cloudy" end
    else
        if code == 0 then return "€сно"
        elseif code == 1 then return "преим. €сно"
        elseif code == 2 then return "перем. облачность"
        elseif code == 3 then return "пасмурно"
        elseif code == 45 or code == 48 then return "туман"
        elseif code == 51 then return "легка€ морось"
        elseif code == 53 then return "умеренна€ морось"
        elseif code == 55 then return "плотна€ морось"
        elseif code == 61 then return "небольшой дождь"
        elseif code == 63 then return "дождь"
        elseif code == 65 then return "сильный дождь"
        elseif code == 71 then return "небольшой снег"
        elseif code == 73 then return "снегопад"
        elseif code == 75 then return "сильный снегопад"
        elseif code == 77 then return "снежные зерна"
        elseif code == 80 then return "кратковр. дождь"
        elseif code == 81 then return "ливень"
        elseif code == 82 then return "сильный ливень"
        elseif code == 85 then return "кратковр. снег"
        elseif code == 86 then return "метель"
        elseif code == 95 then return "гроза"
        elseif code == 96 then return "гроза с градом"
        elseif code == 99 then return "сильна€ гроза"
        else return "облачно" end
    end
end

local function GetWeatherIcon(code)
    code = math.floor(tonumber(code) or 0)
    if code == 0 or code == 1 then return "sun"
    elseif code == 2 then return "cloud_sun"
    elseif code == 3 then return "cloud"
    elseif code == 45 or code == 48 then return "fog"
    elseif (code >= 51 and code <= 67) or (code >= 80 and code <= 82) then return "rain"
    elseif (code >= 71 and code <= 77) or (code >= 85 and code <= 86) then return "snow"
    elseif code >= 95 and code <= 99 then return "thunder"
    else return "cloud" end
end

local function GetWindDirection(deg, lang)
    local dirsRu = { "север", "северо-восток", "восток", "юго-восток", "юг", "юго-запад", "запад", "северо-запад" }
    local dirsEn = { "N", "NE", "E", "SE", "S", "SW", "W", "NW" }
    local dirs = (lang == "English") and dirsEn or dirsRu
    local val = tonumber(deg) or 0
    local idx = math.floor((val + 22.5) / 45) % 8
    return dirs[idx + 1]
end

local function parse_json(str)
    local pos = 1
    local len = #str

    local function skip_whitespace()
        while pos <= len and str:sub(pos, pos):match("%s") do
            pos = pos + 1
        end
    end

    local parse_value

    local function parse_string()
        pos = pos + 1
        local start = pos
        while pos <= len do
            local c = str:sub(pos, pos)
            if c == '"' then
                local s = str:sub(start, pos - 1)
                pos = pos + 1
                return s
            elseif c == '\\' then
                pos = pos + 2
            else
                pos = pos + 1
            end
        end
        return ""
    end

    local function parse_number()
        local start = pos
        if str:sub(pos, pos) == '-' then pos = pos + 1 end
        while pos <= len and str:sub(pos, pos):match("[0-9%.eE%+%-]") do
            pos = pos + 1
        end
        return tonumber(str:sub(start, pos - 1))
    end

    local function parse_array()
        pos = pos + 1
        local arr = {}
        skip_whitespace()
        if pos <= len and str:sub(pos, pos) == ']' then
            pos = pos + 1
            return arr
        end
        while pos <= len do
            table.insert(arr, parse_value())
            skip_whitespace()
            local c = str:sub(pos, pos)
            if c == ']' then
                pos = pos + 1
                return arr
            elseif c == ',' then
                pos = pos + 1
            else
                break
            end
        end
        return arr
    end

    local function parse_object()
        pos = pos + 1
        local obj = {}
        skip_whitespace()
        if pos <= len and str:sub(pos, pos) == '}' then
            pos = pos + 1
            return obj
        end
        while pos <= len do
            skip_whitespace()
            if pos <= len and str:sub(pos, pos) == '}' then
                pos = pos + 1
                return obj
            end
            local key = parse_string()
            skip_whitespace()
            if str:sub(pos, pos) == ':' then
                pos = pos + 1
            end
            skip_whitespace()
            obj[key] = parse_value()
            skip_whitespace()
            local c = str:sub(pos, pos)
            if c == '}' then
                pos = pos + 1
                return obj
            elseif c == ',' then
                pos = pos + 1
            else
                break
            end
        end
        return obj
    end

    parse_value = function()
        skip_whitespace()
        if pos > len then return nil end
        local c = str:sub(pos, pos)
        if c == '{' then
            return parse_object()
        elseif c == '[' then
            return parse_array()
        elseif c == '"' then
            return parse_string()
        elseif c:match("[0-9%-]") then
            return parse_number()
        elseif str:sub(pos, pos + 3) == 'true' then
            pos = pos + 4
            return true
        elseif str:sub(pos, pos + 4) == 'false' then
            pos = pos + 5
            return false
        elseif str:sub(pos, pos + 3) == 'null' then
            pos = pos + 4
            return nil
        else
            pos = pos + 1
            return nil
        end
    end

    return parse_value()
end

function Initialize()
    cachePath = SKIN:GetVariable('@') .. "Cache\\weather-data.inc"
end

function Parse()
    local rawMeasure = SKIN:GetMeasure('MeasureWeatherRaw')
    if not rawMeasure then return end
    local raw = rawMeasure:GetStringValue()
    if not raw or raw == "" then return end

    local data = parse_json(raw)
    if not data or not data.current or not data.daily then return end

    local cur = data.current
    local daily = data.daily

    local lang = SKIN:GetVariable("Language", "Russian")
    local tempUnit = SKIN:GetVariable("WeatherTempUnit", "C")

    local function ToTemp(val)
        local n = tonumber(val) or 0
        if tempUnit == "F" then
            return math.floor(n * 9 / 5 + 32 + 0.5)
        end
        return math.floor(n + 0.5)
    end

    local curTemp = ToTemp(cur.temperature_2m)
    local appTemp = ToTemp(cur.apparent_temperature)
    local humidity = math.floor(tonumber(cur.relative_humidity_2m) + 0.5)
    local windSpeed
    local windUnit
    if tempUnit == "F" then
        windSpeed = string.format("%.1f", (tonumber(cur.wind_speed_10m) or 0) * 2.237)
        windUnit = "mph"
    else
        windSpeed = string.format("%.1f", tonumber(cur.wind_speed_10m) or 0)
        windUnit = (lang == "English") and "m/s" or "м/с"
    end
    local windDir = GetWindDirection(cur.wind_direction_10m, lang)
    local desc = GetWmoDescription(cur.weather_code, lang)
    local icon = GetWeatherIcon(cur.weather_code)
    local timeStr = os.date("%H:%M")

    local d1Min = ToTemp(daily.temperature_2m_min[1])
    local d1Max = ToTemp(daily.temperature_2m_max[1])
    local d1Desc = GetWmoDescription(daily.weather_code[1], lang)

    local d2Min = ToTemp(daily.temperature_2m_min[2])
    local d2Max = ToTemp(daily.temperature_2m_max[2])
    local d2Desc = GetWmoDescription(daily.weather_code[2], lang)

    local d3Min = ToTemp(daily.temperature_2m_min[3])
    local d3Max = ToTemp(daily.temperature_2m_max[3])
    local d3Desc = GetWmoDescription(daily.weather_code[3], lang)

    local day1Name = (lang == "English") and "Today" or "—егодн€"
    local day2Name = (lang == "English") and "Tomorrow" or "«автра"
    local day3Name = (lang == "English") and "Day after" or "ѕослезавтра"

    -- Update Rainmeter variables live in memory (do not touch WeatherCity)
    SKIN:Bang("!SetVariable", "WeatherTemp", tostring(curTemp))
    SKIN:Bang("!SetVariable", "WeatherApparent", tostring(appTemp))
    SKIN:Bang("!SetVariable", "WeatherHumidity", tostring(humidity))
    SKIN:Bang("!SetVariable", "WeatherWindSpeed", windSpeed)
    SKIN:Bang("!SetVariable", "WeatherWindUnit", windUnit)
    SKIN:Bang("!SetVariable", "WeatherWindDir", windDir)
    SKIN:Bang("!SetVariable", "WeatherDesc", desc)
    SKIN:Bang("!SetVariable", "WeatherIcon", icon)
    SKIN:Bang("!SetVariable", "WeatherLastUpdated", timeStr)

    SKIN:Bang("!SetVariable", "WeatherDay1Name", day1Name)
    SKIN:Bang("!SetVariable", "WeatherDay1Min", tostring(d1Min))
    SKIN:Bang("!SetVariable", "WeatherDay1Max", tostring(d1Max))
    SKIN:Bang("!SetVariable", "WeatherDay1Desc", d1Desc)

    SKIN:Bang("!SetVariable", "WeatherDay2Name", day2Name)
    SKIN:Bang("!SetVariable", "WeatherDay2Min", tostring(d2Min))
    SKIN:Bang("!SetVariable", "WeatherDay2Max", tostring(d2Max))
    SKIN:Bang("!SetVariable", "WeatherDay2Desc", d2Desc)

    SKIN:Bang("!SetVariable", "WeatherDay3Name", day3Name)
    SKIN:Bang("!SetVariable", "WeatherDay3Min", tostring(d3Min))
    SKIN:Bang("!SetVariable", "WeatherDay3Max", tostring(d3Max))
    SKIN:Bang("!SetVariable", "WeatherDay3Desc", d3Desc)

    SKIN:Bang("!UpdateMeterGroup", "WeatherGroup")
    SKIN:Bang("!Redraw")

    -- Persist to cache file in CP1251 for instant rendering on next launch (WITHOUT WeatherCity)
    if cachePath and cachePath ~= "" then
        local f = io.open(cachePath, "w")
        if f then
            f:write("[Variables]\n")
            f:write("WeatherTemp=" .. curTemp .. "\n")
            f:write("WeatherApparent=" .. appTemp .. "\n")
            f:write("WeatherHumidity=" .. humidity .. "\n")
            f:write("WeatherWindSpeed=" .. windSpeed .. "\n")
            f:write("WeatherWindUnit=" .. windUnit .. "\n")
            f:write("WeatherWindDir=" .. windDir .. "\n")
            f:write("WeatherDesc=" .. desc .. "\n")
            f:write("WeatherIcon=" .. icon .. "\n")
            f:write("WeatherLastUpdated=" .. timeStr .. "\n")
            f:write("WeatherStatus=Ok\n\n")
            f:write("WeatherDay1Name=" .. day1Name .. "\n")
            f:write("WeatherDay1Min=" .. d1Min .. "\n")
            f:write("WeatherDay1Max=" .. d1Max .. "\n")
            f:write("WeatherDay1Desc=" .. d1Desc .. "\n\n")
            f:write("WeatherDay2Name=" .. day2Name .. "\n")
            f:write("WeatherDay2Min=" .. d2Min .. "\n")
            f:write("WeatherDay2Max=" .. d2Max .. "\n")
            f:write("WeatherDay2Desc=" .. d2Desc .. "\n\n")
            f:write("WeatherDay3Name=" .. day3Name .. "\n")
            f:write("WeatherDay3Min=" .. d3Min .. "\n")
            f:write("WeatherDay3Max=" .. d3Max .. "\n")
            f:write("WeatherDay3Desc=" .. d3Desc .. "\n")
            f:close()
        end
    end
end
