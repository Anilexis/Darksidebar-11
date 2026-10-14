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

[MeasureFreeStringC]
Measure=FreeDiskSpace
Drive=C:
UpdateDivider=10
AutoScale=1

[MeterDiskRowC]
TransformationMatrix=(#UiScale#);0;0;(#UiScale#);0;0
DynamicVariables=1
Meter=String
X=18
Y=628
W=204
H=16
SolidColor=0,0,0,1
ToolTipText="#LangOpenDisk# C:"
LeftMouseUpAction=["C:\"]
Cursor=2

[MeterDiskLabelC]
TransformationMatrix=(#UiScale#);0;0;(#UiScale#);0;0
DynamicVariables=1
Meter=String
X=18
Y=628
FontFace=#FontMain#
FontSize=#FontSizeBody#
FontWeight=600
FontColor=#ColorTextPrimary#
AntiAlias=1
Text="System (C:)"

[MeterDiskStatsC]
TransformationMatrix=(#UiScale#);0;0;(#UiScale#);0;0
DynamicVariables=1
Meter=String
MeasureName=MeasureFreeStringC
DynamicVariables=1
X=222
Y=628
StringAlign=Right
FontFace=#FontMain#
FontSize=#FontSizeBody#
FontColor=#ColorTextSecondary#
AntiAlias=1
Text="[MeasureFreePercentC:0]% #LangFree#  (%1)"

[MeterDiskBarBgC]
TransformationMatrix=(#UiScale#);0;0;(#UiScale#);0;0
DynamicVariables=1
Meter=Shape
X=18
Y=645
Shape=Rectangle 0,0,204,3,1 | Fill Color #ColorBarBg# | StrokeWidth 0

[MeterDiskBarC]
TransformationMatrix=(#UiScale#);0;0;(#UiScale#);0;0
DynamicVariables=1
Meter=Bar
MeasureName=MeasureUsedPercentC
DynamicVariables=1
X=18
Y=645
W=204
H=3
BarColor=#ColorBarFill#
BarOrientation=Horizontal
