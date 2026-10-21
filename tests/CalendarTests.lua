-- CalendarTests.lua
-- Unit tests for Calendar.lua logic and wraparound

local skinVariables = {
    ["Language"] = "Russian",
    ["CalendarFirstDay"] = "Monday",
    ["CalendarToolTip"] = "",
    ["@"] = "./Skins/Darksidebar-11/@Resources/"
}

local bangs = {}

SKIN = {
    GetVariable = function(self, key, default)
        local val = skinVariables[key]
        if val ~= nil then return val end
        return default
    end,
    Bang = function(self, bangName, ...)
        table.insert(bangs, { bang = bangName, args = { ... } })
    end
}

-- Load Calendar.lua
dofile("Skins/Darksidebar-11/@Resources/Scripts/Calendar.lua")

local testCount = 0
local function assert_eq(actual, expected, msg)
    testCount = testCount + 1
    if actual ~= expected then
        error(string.format("FAILED: %s | Expected: %s, got: %s", msg or "", tostring(expected), tostring(actual)))
    end
end

print("Running Calendar.lua Unit Tests...")

-- Test 1: NextMonth Wraparound from December to January
SetViewDate(2026, 12)
NextMonth()
local y, m = GetViewDate()
assert_eq(y, 2027, "NextMonth year should advance from 2026 to 2027 on Dec -> Jan")
assert_eq(m, 1, "NextMonth month should wrap to 1 (January)")

-- Test 2: PrevMonth Wraparound from January to December
SetViewDate(2026, 1)
PrevMonth()
y, m = GetViewDate()
assert_eq(y, 2025, "PrevMonth year should decrease from 2026 to 2025 on Jan -> Dec")
assert_eq(m, 12, "PrevMonth month should wrap to 12 (December)")

-- Test 3: Normal Progression Forward
SetViewDate(2026, 5)
NextMonth()
y, m = GetViewDate()
assert_eq(y, 2026, "Normal NextMonth keeps same year")
assert_eq(m, 6, "Normal NextMonth increments month")

-- Test 4: Normal Progression Backward
SetViewDate(2026, 5)
PrevMonth()
y, m = GetViewDate()
assert_eq(y, 2026, "Normal PrevMonth keeps same year")
assert_eq(m, 4, "Normal PrevMonth decrements month")

-- Test 5: Multi-year step forward (24 months)
SetViewDate(2025, 6)
for i = 1, 24 do
    NextMonth()
end
y, m = GetViewDate()
assert_eq(y, 2027, "24 NextMonth steps from 2025-06 should reach 2027-06")
assert_eq(m, 6, "24 NextMonth steps should preserve month")

-- Test 6: Multi-year step backward (24 months)
SetViewDate(2025, 6)
for i = 1, 24 do
    PrevMonth()
end
y, m = GetViewDate()
assert_eq(y, 2023, "24 PrevMonth steps from 2025-06 should reach 2023-06")
assert_eq(m, 6, "24 PrevMonth steps should preserve month")

-- Test 7: ResetToday
SetViewDate(1990, 1)
ResetToday()
y, m = GetViewDate()
local now = os.date("*t")
assert_eq(y, now.year, "ResetToday restores view year to current year")
assert_eq(m, now.month, "ResetToday restores view month to current month")

-- Test 8: RefreshGrid with English and Sunday-first
skinVariables["Language"] = "English"
skinVariables["CalendarFirstDay"] = "Sunday"
RefreshGrid()
-- If no exceptions thrown and bangs generated, grid refreshed successfully
assert_eq(#bangs > 0, true, "RefreshGrid generates UI update bangs")

-- Test 9: RefreshGrid with Russian and Monday-first
skinVariables["Language"] = "Russian"
skinVariables["CalendarFirstDay"] = "Monday"
RefreshGrid()
assert_eq(#bangs > 10, true, "RefreshGrid generates UI update bangs for Russian/Monday")

print(string.format("All %d Calendar.lua assertions PASSED successfully!", testCount))
