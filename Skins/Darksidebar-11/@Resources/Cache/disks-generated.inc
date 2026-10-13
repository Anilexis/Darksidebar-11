; Initial Disks topology for Darksidebar-11
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
UpdateDivider=10

[MeterDiskRowC]
Meter=String
MeterStyle=StyleDiskLabel
Y=643
Text=C: [MeasureFreeC:/1073741824, 0]G #LangFree#
ToolTipText=#LangOpenDisk# C:
LeftMouseUpAction=["C:\"]
DynamicVariables=1

[MeterDiskBarBgC]
Meter=Image
MeterStyle=StyleDiskBarBg
Y=657

[MeterDiskBarFillC]
Meter=Bar
MeterStyle=StyleDiskBarFill
MeasureName=MeasureUsedPercentC
Y=657