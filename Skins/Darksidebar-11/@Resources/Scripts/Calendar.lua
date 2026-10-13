-- Calendar.lua for Darksidebar-11 (Version 3.5 Standalone)
local monthsRuShort = {
    "Янв", "Фев", "Мар", "Апр", "Май", "Июн",
    "Июл", "Авг", "Сен", "Окт", "Ноя", "Дек"
}

local monthsEnShort = {
    "Jan", "Feb", "Mar", "Apr", "May", "Jun",
    "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
}

local defaultRuHolidays = {
    ["01-01"] = "Новый год", ["01-02"] = "Новогодние каникулы", ["01-03"] = "Новогодние каникулы",
    ["01-04"] = "Новогодние каникулы", ["01-05"] = "Новогодние каникулы", ["01-06"] = "Новогодние каникулы",
    ["01-07"] = "Рождество Христово", ["01-08"] = "Новогодние каникулы",
    ["02-23"] = "День защитника Отечества", ["03-08"] = "Международный женский день",
    ["05-01"] = "Праздник Весны и Труда", ["05-09"] = "День Победы",
    ["06-12"] = "День России", ["11-04"] = "День народного единства"
}

local holidaysData = nil
local lastLoadedYear = 0

local function loadHolidays(year)
    local resPath = SKIN:GetVariable("@", "")
    local path = resPath .. "Cache/holidays.lua"
    local ok, h = pcall(dofile, path)
    if ok and type(h) == "table" and type(h.days) == "table" then
        holidaysData = h.days
        lastLoadedYear = h.year or year
    else
        holidaysData = nil
    end
end

local viewYear = 2026
local viewMonth = 10
local todayYear = 2026
local todayMonth = 10
local todayDay = 13

local colCenters = { 26, 58, 89, 120, 151, 182, 214 }
local gridTop = 290
local rowHeight = 17

local function isLeapYear(y)
    return (y % 4 == 0 and y % 100 ~= 0) or (y % 400 == 0)
end

local function getDaysInMonth(y, m)
    if m == 2 then
        return isLeapYear(y) and 29 or 28
    elseif m == 4 or m == 6 or m == 9 or m == 11 then
        return 30
    else
        return 31
    end
end

local function getFirstDayCol(y, m, isMondayFirst)
    local t = {0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4}
    local yAdj = (m < 3) and (y - 1) or y
    local sunBased = (yAdj + math.floor(yAdj/4) - math.floor(yAdj/100) + math.floor(yAdj/400) + t[m] + 1) % 7
    if isMondayFirst then
        return (sunBased + 6) % 7
    else
        return sunBased
    end
end

function Initialize()
    local now = os.date("*t")
    todayYear, todayMonth, todayDay = now.year, now.month, now.day
    viewYear, viewMonth = todayYear, todayMonth
    loadHolidays(viewYear)
    RefreshGrid()
end

function Update()
    local now = os.date("*t")
    if now.day ~= todayDay or now.month ~= todayMonth or now.year ~= todayYear then
        todayYear, todayMonth, todayDay = now.year, now.month, now.day
        loadHolidays(todayYear)
        RefreshGrid()
    end
end

function PrevMonth()
    viewMonth = viewMonth - 1
    if viewMonth < 1 then
        viewMonth = 12
        viewYear = viewYear - 1
        loadHolidays(viewYear)
    end
    RefreshGrid()
end

function NextMonth()
    viewMonth = viewMonth + 1
    if viewMonth > 12 then
        viewMonth = 1
        viewYear = viewYear + 1
        loadHolidays(viewYear)
    end
    RefreshGrid()
end

function ResetToday()
    local now = os.date("*t")
    todayYear, todayMonth, todayDay = now.year, now.month, now.day
    viewYear, viewMonth = todayYear, todayMonth
    loadHolidays(viewYear)
    RefreshGrid()
end

function RefreshGrid()
    local lang = SKIN:GetVariable("Language", "Russian")
    local firstDaySetting = SKIN:GetVariable("CalendarFirstDay", "Monday")
    local isMondayFirst = (firstDaySetting ~= "Sunday")
    local calTip = SKIN:GetVariable("CalendarToolTip", "")

    local months = (lang == "English") and monthsEnShort or monthsRuShort
    local titleText = string.format("%s %d", months[viewMonth], viewYear)
    SKIN:Bang("!SetOption", "MeterMonthYear", "Text", titleText)

    -- Update column headers dynamically
    local headers = {
        "MeterHeaderMon", "MeterHeaderTue", "MeterHeaderWed",
        "MeterHeaderThu", "MeterHeaderFri", "MeterHeaderSat", "MeterHeaderSun"
    }
    local labelsRu = isMondayFirst and {"Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"} or {"Вс", "Пн", "Вт", "Ср", "Чт", "Пт", "Сб"}
    local labelsEn = isMondayFirst and {"Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"} or {"Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"}
    local labels = (lang == "English") and labelsEn or labelsRu

    for i = 1, 7 do
        local isWk
        if isMondayFirst then
            isWk = (i == 6 or i == 7)
        else
            isWk = (i == 1 or i == 7)
        end
        local c = isWk and "#ColorToday#" or "#ColorTextMuted#"
        SKIN:Bang("!SetOption", headers[i], "Text", labels[i])
        SKIN:Bang("!SetOption", headers[i], "FontColor", c)
    end

    local firstCol = getFirstDayCol(viewYear, viewMonth, isMondayFirst)
    local totalDaysCurrent = getDaysInMonth(viewYear, viewMonth)

    local prevMonth = (viewMonth > 1) and (viewMonth - 1) or 12
    local prevYear = (viewMonth > 1) and viewYear or (viewYear - 1)
    local totalDaysPrev = getDaysInMonth(prevYear, prevMonth)
    local dayPrevStart = totalDaysPrev - firstCol + 1

    local todayVisible = false

    for cell = 1, 42 do
        local meterName = "MeterDay" .. cell
        local dayText = ""
        local color = "80,85,95,140"
        local weight = "400"
        local tip = calTip
        local col = ((cell - 1) % 7)
        local row = math.floor((cell - 1) / 7)
        
        local isWeekend
        if isMondayFirst then
            isWeekend = (col == 5 or col == 6)
        else
            isWeekend = (col == 0 or col == 6)
        end

        local mx = colCenters[col + 1]
        local my = gridTop + row * rowHeight + 9

        if cell <= firstCol then
            dayText = tostring(dayPrevStart + (cell - 1))
            color = "80,85,95,140"
            tip = ""
        elseif cell <= firstCol + totalDaysCurrent then
            local d = cell - firstCol
            dayText = tostring(d)
            
            local dateKey = string.format("%04d-%02d-%02d", viewYear, viewMonth, d)
            local shortKey = string.format("%02d-%02d", viewMonth, d)
            local holidayName = nil
            if holidaysData then
                holidayName = holidaysData[dateKey]
            elseif lang == "Russian" then
                holidayName = defaultRuHolidays[shortKey]
            end
            local isHoliday = (holidayName ~= nil)

            if viewYear == todayYear and viewMonth == todayMonth and d == todayDay then
                color = "255,255,255,255"
                weight = "700"
                todayVisible = true

                SKIN:Bang("!SetOption", "MeterTodayHighlight", "X", tostring(mx))
                SKIN:Bang("!SetOption", "MeterTodayHighlight", "Y", tostring(my))
                SKIN:Bang("!ShowMeter", "MeterTodayHighlight")
                if isHoliday then tip = holidayName end
            elseif isHoliday then
                color = "240,110,40,255"
                weight = "600"
                tip = holidayName
            elseif isWeekend then
                color = "240,110,40,255"
            else
                color = "230,235,245,255"
            end
        else
            dayText = tostring(cell - (firstCol + totalDaysCurrent))
            color = "80,85,95,140"
            tip = ""
        end

        SKIN:Bang("!SetOption", meterName, "Text", dayText)
        SKIN:Bang("!SetOption", meterName, "FontColor", color)
        SKIN:Bang("!SetOption", meterName, "FontWeight", weight)
        SKIN:Bang("!SetOption", meterName, "ToolTipText", tip)
    end

    if not todayVisible then
        SKIN:Bang("!HideMeter", "MeterTodayHighlight")
    end

    SKIN:Bang("!UpdateMeterGroup", "CalendarGroup")
    SKIN:Bang("!Redraw")
end