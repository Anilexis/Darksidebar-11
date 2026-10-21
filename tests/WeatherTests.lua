-- WeatherTests.lua
-- Unit tests for Weather.lua parse_json (RFC 8259 compliance, edge cases, malformed JSON)

-- Mock Rainmeter environment before requiring Weather.lua
local skinVariables = {
    ["@"] = "./Skins/Darksidebar-11/@Resources/",
    ["Language"] = "Russian",
    ["WeatherTempUnit"] = "C"
}

SKIN = {
    GetVariable = function(self, k, def) return skinVariables[k] or def end,
    GetMeasure = function(self, name) return nil end,
    Bang = function(self, ...) end
}

dofile("Skins/Darksidebar-11/@Resources/Scripts/Weather.lua")

local parse_json = Weather.parse_json

local testCount = 0
local function assert_true(cond, msg)
    testCount = testCount + 1
    if not cond then
        error(string.format("ASSERTION FAILED: %s", msg or "expected true"))
    end
end

local function assert_eq(actual, expected, msg)
    testCount = testCount + 1
    if actual ~= expected then
        error(string.format("ASSERTION FAILED: %s | Expected: %s, got: %s", msg or "", tostring(expected), tostring(actual)))
    end
end

print("Running Weather.lua parse_json Unit & Edge-Case Tests...")

-- 1. Nil, empty, and whitespace
assert_eq(parse_json(nil), nil, "parse_json(nil) -> nil")
assert_eq(parse_json(""), nil, "parse_json('') -> nil")
assert_eq(parse_json("   \t\r\n  "), nil, "parse_json(whitespace) -> nil")
assert_eq(parse_json(123), nil, "parse_json(non-string) -> nil")

-- 2. Literals
assert_eq(parse_json("true"), true, "parse_json('true') -> true")
assert_eq(parse_json("false"), false, "parse_json('false') -> false")
assert_eq(parse_json("null"), nil, "parse_json('null') -> nil")

-- 3. Numbers
assert_eq(parse_json("0"), 0, "number 0")
assert_eq(parse_json("42"), 42, "integer 42")
assert_eq(parse_json("-17"), -17, "negative integer -17")
assert_true(math.abs(parse_json("3.14159") - 3.14159) < 0.0001, "float 3.14159")
assert_true(math.abs(parse_json("-0.05") - (-0.05)) < 0.0001, "negative float -0.05")
assert_eq(parse_json("1e3"), 1000, "scientific 1e3")
assert_true(math.abs(parse_json("2.5e-2") - 0.025) < 0.0001, "scientific 2.5e-2")

-- 4. Strings
assert_eq(parse_json('""'), "", "empty string")
assert_eq(parse_json('"hello world"'), "hello world", "basic string")
assert_eq(parse_json('"line1\\nline2"'), "line1\\nline2", "escaped newline")
assert_eq(parse_json('"with \\"quotes\\""'), 'with \\"quotes\\"', "escaped quotes")
assert_eq(parse_json('"Москва 2026"'), "Москва 2026", "cyrillic string")

-- 5. Arrays
local arrEmpty = parse_json("[]")
assert_true(type(arrEmpty) == "table" and #arrEmpty == 0, "empty array []")

local arrNumbers = parse_json("[1, 2, 3, 4]")
assert_eq(#arrNumbers, 4, "array length")
assert_eq(arrNumbers[1], 1, "arr[1]")
assert_eq(arrNumbers[4], 4, "arr[4]")

local arrMixed = parse_json('[ "test", 123, true, false ]')
assert_eq(#arrMixed, 4, "mixed array length")
assert_eq(arrMixed[1], "test", "mixed array str")
assert_eq(arrMixed[2], 123, "mixed array num")
assert_eq(arrMixed[3], true, "mixed array true")
assert_eq(arrMixed[4], false, "mixed array false")

local arrNested = parse_json('[[1, 2], [3, [4, 5]]]')
assert_eq(arrNested[1][2], 2, "nested array [1][2]")
assert_eq(arrNested[2][2][1], 4, "deep nested array [2][2][1]")

-- 6. Objects
local objEmpty = parse_json("{}")
assert_true(type(objEmpty) == "table", "empty object {}")

local objSimple = parse_json('{"city": "Tyumen", "temp": 18.5, "is_day": 1}')
assert_eq(objSimple.city, "Tyumen", "obj.city")
assert_eq(objSimple.temp, 18.5, "obj.temp")
assert_eq(objSimple.is_day, 1, "obj.is_day")

local objNested = parse_json('{"coord": {"lat": 57.15, "lon": 65.54}, "tags": ["cold", "siberia"]}')
assert_eq(objNested.coord.lat, 57.15, "nested obj lat")
assert_eq(objNested.coord.lon, 65.54, "nested obj lon")
assert_eq(objNested.tags[1], "cold", "nested obj tags[1]")

-- 7. Realistic Open-Meteo Weather JSON payload
local meteoJson = [[
{
  "latitude": 57.15,
  "longitude": 65.54,
  "current": {
    "time": "2026-10-21T12:00",
    "temperature_2m": 12.4,
    "relative_humidity_2m": 65,
    "apparent_temperature": 10.8,
    "is_day": 1,
    "weather_code": 3,
    "wind_speed_10m": 4.5,
    "wind_direction_10m": 220
  },
  "daily": {
    "time": ["2026-10-21", "2026-10-22"],
    "weather_code": [3, 61],
    "temperature_2m_max": [14.0, 11.2],
    "temperature_2m_min": [5.1, 3.4]
  }
}
]]
local meteoData = parse_json(meteoJson)
assert_true(meteoData ~= nil, "open-meteo payload parsed")
assert_eq(meteoData.current.temperature_2m, 12.4, "meteo current temp")
assert_eq(meteoData.current.weather_code, 3, "meteo current weather_code")
assert_eq(meteoData.daily.time[1], "2026-10-21", "meteo daily date")
assert_eq(meteoData.daily.temperature_2m_max[2], 11.2, "meteo daily max temp")

-- 8. Edge cases & Malformed JSON (must not crash, loop infinitely, or throw)
local p1 = parse_json("{")
assert_true(type(p1) == "table", "malformed unclosed { -> table")

local p2 = parse_json("[")
assert_true(type(p2) == "table", "malformed unclosed [ -> table")

local p3 = parse_json('"unclosed string')
assert_eq(p3, "unclosed string", "unterminated string handled gracefully")

local p4 = parse_json('{"key": ')
assert_true(type(p4) == "table", "missing value in object")

local p5 = parse_json('[1, 2, ]')
assert_true(type(p5) == "table" and #p5 == 2, "trailing comma in array")

local p6 = parse_json('{"a": 1, }')
assert_true(type(p6) == "table" and p6.a == 1, "trailing comma in object")

local p7 = parse_json('{foo: 123}')
assert_true(type(p7) == "table", "unquoted key handled gracefully")

local p8 = parse_json('42 extra_garbage')
assert_eq(p8, 42, "trailing garbage ignored after valid value")

-- 9. Performance benchmark check
local t0 = os.clock()
for i = 1, 1000 do
    parse_json('{"temp": 21.5, "humidity": 50, "items": [1, 2, 3, "test"]}')
end
local elapsed = os.clock() - t0
print(string.format("Performance: 1,000 JSON parses completed in %.4f seconds", elapsed))
assert_true(elapsed < 2.0, "1,000 JSON parses must complete under 2 seconds")

print(string.format("All %d Weather.lua parse_json assertions PASSED successfully!", testCount))
