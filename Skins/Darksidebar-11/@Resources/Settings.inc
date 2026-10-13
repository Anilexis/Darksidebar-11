[Variables]
; Global dimensions
SkinWidth=240
ContentWidth=216
SidePadding=12

; Neutral desaturated background with subtle transparency
ColorBg=18,18,18,220
ColorBorder=255,255,255,18

; Theme Accents
ColorAccent=0,180,255,255
ColorAccentBg=0,180,255,40
ColorToday=240,110,40,255
ColorTodayBg=0,180,255,220

; Text Typography
ColorTextPrimary=240,245,255,255
ColorTextSecondary=160,175,195,255
ColorTextMuted=110,125,140,255

; Hardware & Disk Bars (Neutral grey background, Blue fill)
ColorBarBg=45,45,45,180
ColorBarFill=0,180,255,230

; Aliases for compatibility
ColorText=240,245,255,255
ColorBar=0,180,255,230

; Typography Fonts & Sizes
FontMain=Segoe UI
FontMono=Consolas
FontSizeTitle=10
FontSizeBody=9
FontSizeLarge=18
FontSizeHuge=28

; ============================================================
; USER CONFIGURATION (Configurable via Settings.ini GUI)
; ============================================================
; Display & Placement Settings
MonitorTargetId=MONITOR\PHL04C3\{4d36e96e-e325-11ce-bfc1-08002be10318}\0003
MonitorFriendlyName=Philips FTV
MonitorFallbackDev=\\.\DISPLAY3
PlacementEdge=Right
RightMargin=0
TopMargin=0
HideWhenTargetMissing=0

; Weather Settings (Default: London / Greenwich; auto-detected on first run)
WeatherCity=Тюмень
WeatherLat=57.1522
WeatherLon=65.5272
WeatherCountryCode=RU
WeatherCountryName=Россия
WeatherUnits=metric

; Localization Settings
Language=Russian

; Weather Temperature Unit (C or F)
WeatherTempUnit=C

; Calendar First Day of Week (Monday or Sunday)
CalendarFirstDay=Monday

; Clock Hand Thickness (Thin, Normal, Thick)
ClockHandThickness=Normal
ClockHourLineWidth=3.5
ClockMinuteLineWidth=2.2

; Application Launchers on click (None, System, Custom)
CalendarAppType=System
CalendarAppPath=
CalendarAction=["outlookcal:"]
CalendarCursor=2
CalendarToolTip=#LangOpenCalendar#

WeatherAppType=System
WeatherAppPath=
WeatherAction=["msnweather:"]
WeatherCursor=2
WeatherToolTip=#LangOpenWeather#

; Holidays Configuration
HolidaysEnabled=1

; First run flag (0 = triggers IP auto-detection of location on first launch)
FirstRunDone=1