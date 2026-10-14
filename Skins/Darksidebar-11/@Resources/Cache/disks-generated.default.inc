; Auto-generated Disks topology for Darksidebar-11
; Default template for distribution (Single System Drive C:)

[MeasureTotalC]
Measure=FreeDiskSpace
Drive=C:
Total=1
UpdateDivider=10

[MeasureFreeC]
Measure=FreeDiskSpace
Drive=C:
UpdateDivider=10

[MeasureUsedPercentC]
Measure=Calc
Formula=Round((MeasureTotalC - MeasureFreeC) / MeasureTotalC * 100)
MinValue=0
MaxValue=100
UpdateDivider=10

[MeasureFreePercentC]
Measure=Calc
Formula=Round(MeasureFreeC / MeasureTotalC * 100)
MinValue=0
MaxValue=100
UpdateDivider=10
IfCondition=MeasureFreePercentC < 10
IfTrueAction=[!SetOption MeterDiskValueC FontColor "240,110,40,255"]
IfFalseAction=[!SetOption MeterDiskValueC FontColor "#ColorTextSecondary#"]

[MeterDiskRowC]
Meter=Shape
X=12
Y=631
Shape=Rectangle 0,0,(#SkinWidth# - 24),20,2 | Fill Color 255,255,255,3 | StrokeWidth 0
MouseOverAction=[!SetOption MeterDiskRowC Fill "Color 255,255,255,15"][!Redraw]
MouseLeaveAction=[!SetOption MeterDiskRowC Fill "Color 255,255,255,3"][!Redraw]
LeftMouseUpAction=["explorer.exe" "C:"]
ToolTipText="#LangOpenDisk# C:"
Cursor=2

[MeterDiskLabelC]
Meter=String
X=18
Y=631
FontFace=#FontMain#
FontSize=8
FontWeight=600
FontColor=#ColorTextPrimary#
AntiAlias=1
Text="System (C:)"

[MeterDiskValueC]
Meter=String
MeasureName=MeasureFreeC
X=222
Y=631
StringAlign=Right
FontFace=#FontMain#
FontSize=8
FontColor=#ColorTextSecondary#
AntiAlias=1
AutoScale=1
NumOfDecimals=0
DynamicVariables=1
Text="[MeasureFreePercentC:0]% #LangFree#  (%1)"

[MeterDiskBarBgC]
Meter=Shape
X=18
Y=645
Shape=Rectangle 0,0,204,3,1 | Fill Color #ColorBarBg# | StrokeWidth 0

[MeterDiskBarC]
Meter=Bar
MeasureName=MeasureUsedPercentC
X=18
Y=645
W=204
H=3
BarColor=#ColorBarFill#
BarOrientation=Horizontal