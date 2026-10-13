; Auto-generated Disks topology for Darksidebar-11
; Generated: 2026-10-13 21:41:42

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

[MeasureTotalD]
Measure=FreeDiskSpace
Drive=D:
Total=1
UpdateDivider=10

[MeasureFreeD]
Measure=FreeDiskSpace
Drive=D:
UpdateDivider=10

[MeasureUsedPercentD]
Measure=Calc
Formula=Round((MeasureTotalD - MeasureFreeD) / MeasureTotalD * 100)
MinValue=0
MaxValue=100
UpdateDivider=10

[MeasureFreePercentD]
Measure=Calc
Formula=Round(MeasureFreeD / MeasureTotalD * 100)
MinValue=0
MaxValue=100
UpdateDivider=10
IfCondition=MeasureFreePercentD < 10
IfTrueAction=[!SetOption MeterDiskValueD FontColor "240,110,40,255"]
IfFalseAction=[!SetOption MeterDiskValueD FontColor "#ColorTextSecondary#"]

[MeasureTotalE]
Measure=FreeDiskSpace
Drive=E:
Total=1
UpdateDivider=10

[MeasureFreeE]
Measure=FreeDiskSpace
Drive=E:
UpdateDivider=10

[MeasureUsedPercentE]
Measure=Calc
Formula=Round((MeasureTotalE - MeasureFreeE) / MeasureTotalE * 100)
MinValue=0
MaxValue=100
UpdateDivider=10

[MeasureFreePercentE]
Measure=Calc
Formula=Round(MeasureFreeE / MeasureTotalE * 100)
MinValue=0
MaxValue=100
UpdateDivider=10
IfCondition=MeasureFreePercentE < 10
IfTrueAction=[!SetOption MeterDiskValueE FontColor "240,110,40,255"]
IfFalseAction=[!SetOption MeterDiskValueE FontColor "#ColorTextSecondary#"]

[MeasureTotalG]
Measure=FreeDiskSpace
Drive=G:
Total=1
UpdateDivider=10

[MeasureFreeG]
Measure=FreeDiskSpace
Drive=G:
UpdateDivider=10

[MeasureUsedPercentG]
Measure=Calc
Formula=Round((MeasureTotalG - MeasureFreeG) / MeasureTotalG * 100)
MinValue=0
MaxValue=100
UpdateDivider=10

[MeasureFreePercentG]
Measure=Calc
Formula=Round(MeasureFreeG / MeasureTotalG * 100)
MinValue=0
MaxValue=100
UpdateDivider=10
IfCondition=MeasureFreePercentG < 10
IfTrueAction=[!SetOption MeterDiskValueG FontColor "240,110,40,255"]
IfFalseAction=[!SetOption MeterDiskValueG FontColor "#ColorTextSecondary#"]

[MeasureTotalT]
Measure=FreeDiskSpace
Drive=T:
Total=1
UpdateDivider=10

[MeasureFreeT]
Measure=FreeDiskSpace
Drive=T:
UpdateDivider=10

[MeasureUsedPercentT]
Measure=Calc
Formula=Round((MeasureTotalT - MeasureFreeT) / MeasureTotalT * 100)
MinValue=0
MaxValue=100
UpdateDivider=10

[MeasureFreePercentT]
Measure=Calc
Formula=Round(MeasureFreeT / MeasureTotalT * 100)
MinValue=0
MaxValue=100
UpdateDivider=10
IfCondition=MeasureFreePercentT < 10
IfTrueAction=[!SetOption MeterDiskValueT FontColor "240,110,40,255"]
IfFalseAction=[!SetOption MeterDiskValueT FontColor "#ColorTextSecondary#"]

[MeasureTotalW]
Measure=FreeDiskSpace
Drive=W:
Total=1
UpdateDivider=10

[MeasureFreeW]
Measure=FreeDiskSpace
Drive=W:
UpdateDivider=10

[MeasureUsedPercentW]
Measure=Calc
Formula=Round((MeasureTotalW - MeasureFreeW) / MeasureTotalW * 100)
MinValue=0
MaxValue=100
UpdateDivider=10

[MeasureFreePercentW]
Measure=Calc
Formula=Round(MeasureFreeW / MeasureTotalW * 100)
MinValue=0
MaxValue=100
UpdateDivider=10
IfCondition=MeasureFreePercentW < 10
IfTrueAction=[!SetOption MeterDiskValueW FontColor "240,110,40,255"]
IfFalseAction=[!SetOption MeterDiskValueW FontColor "#ColorTextSecondary#"]

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

[MeterDiskRowD]
Meter=Shape
X=12
Y=654
Shape=Rectangle 0,0,(#SkinWidth# - 24),20,2 | Fill Color 255,255,255,3 | StrokeWidth 0
MouseOverAction=[!SetOption MeterDiskRowD Fill "Color 255,255,255,15"][!Redraw]
MouseLeaveAction=[!SetOption MeterDiskRowD Fill "Color 255,255,255,3"][!Redraw]
LeftMouseUpAction=["explorer.exe" "D:"]
ToolTipText="#LangOpenDisk# D:"
Cursor=2

[MeterDiskLabelD]
Meter=String
X=18
Y=654
FontFace=#FontMain#
FontSize=8
FontWeight=600
FontColor=#ColorTextPrimary#
AntiAlias=1
Text="HDD (D:)"

[MeterDiskValueD]
Meter=String
MeasureName=MeasureFreeD
X=222
Y=654
StringAlign=Right
FontFace=#FontMain#
FontSize=8
FontColor=#ColorTextSecondary#
AntiAlias=1
AutoScale=1
NumOfDecimals=0
DynamicVariables=1
Text="[MeasureFreePercentD:0]% #LangFree#  (%1)"

[MeterDiskBarBgD]
Meter=Shape
X=18
Y=668
Shape=Rectangle 0,0,204,3,1 | Fill Color #ColorBarBg# | StrokeWidth 0

[MeterDiskBarD]
Meter=Bar
MeasureName=MeasureUsedPercentD
X=18
Y=668
W=204
H=3
BarColor=#ColorBarFill#
BarOrientation=Horizontal

[MeterDiskRowE]
Meter=Shape
X=12
Y=677
Shape=Rectangle 0,0,(#SkinWidth# - 24),20,2 | Fill Color 255,255,255,3 | StrokeWidth 0
MouseOverAction=[!SetOption MeterDiskRowE Fill "Color 255,255,255,15"][!Redraw]
MouseLeaveAction=[!SetOption MeterDiskRowE Fill "Color 255,255,255,3"][!Redraw]
LeftMouseUpAction=["explorer.exe" "E:"]
ToolTipText="#LangOpenDisk# E:"
Cursor=2

[MeterDiskLabelE]
Meter=String
X=18
Y=677
FontFace=#FontMain#
FontSize=8
FontWeight=600
FontColor=#ColorTextPrimary#
AntiAlias=1
Text="nvGames (E:)"

[MeterDiskValueE]
Meter=String
MeasureName=MeasureFreeE
X=222
Y=677
StringAlign=Right
FontFace=#FontMain#
FontSize=8
FontColor=#ColorTextSecondary#
AntiAlias=1
AutoScale=1
NumOfDecimals=0
DynamicVariables=1
Text="[MeasureFreePercentE:0]% #LangFree#  (%1)"

[MeterDiskBarBgE]
Meter=Shape
X=18
Y=691
Shape=Rectangle 0,0,204,3,1 | Fill Color #ColorBarBg# | StrokeWidth 0

[MeterDiskBarE]
Meter=Bar
MeasureName=MeasureUsedPercentE
X=18
Y=691
W=204
H=3
BarColor=#ColorBarFill#
BarOrientation=Horizontal

[MeterDiskRowG]
Meter=Shape
X=12
Y=700
Shape=Rectangle 0,0,(#SkinWidth# - 24),20,2 | Fill Color 255,255,255,3 | StrokeWidth 0
MouseOverAction=[!SetOption MeterDiskRowG Fill "Color 255,255,255,15"][!Redraw]
MouseLeaveAction=[!SetOption MeterDiskRowG Fill "Color 255,255,255,3"][!Redraw]
LeftMouseUpAction=["explorer.exe" "G:"]
ToolTipText="#LangOpenDisk# G:"
Cursor=2

[MeterDiskLabelG]
Meter=String
X=18
Y=700
FontFace=#FontMain#
FontSize=8
FontWeight=600
FontColor=#ColorTextPrimary#
AntiAlias=1
Text="Games (G:)"

[MeterDiskValueG]
Meter=String
MeasureName=MeasureFreeG
X=222
Y=700
StringAlign=Right
FontFace=#FontMain#
FontSize=8
FontColor=#ColorTextSecondary#
AntiAlias=1
AutoScale=1
NumOfDecimals=0
DynamicVariables=1
Text="[MeasureFreePercentG:0]% #LangFree#  (%1)"

[MeterDiskBarBgG]
Meter=Shape
X=18
Y=714
Shape=Rectangle 0,0,204,3,1 | Fill Color #ColorBarBg# | StrokeWidth 0

[MeterDiskBarG]
Meter=Bar
MeasureName=MeasureUsedPercentG
X=18
Y=714
W=204
H=3
BarColor=#ColorBarFill#
BarOrientation=Horizontal

[MeterDiskRowT]
Meter=Shape
X=12
Y=723
Shape=Rectangle 0,0,(#SkinWidth# - 24),20,2 | Fill Color 255,255,255,3 | StrokeWidth 0
MouseOverAction=[!SetOption MeterDiskRowT Fill "Color 255,255,255,15"][!Redraw]
MouseLeaveAction=[!SetOption MeterDiskRowT Fill "Color 255,255,255,3"][!Redraw]
LeftMouseUpAction=["explorer.exe" "T:"]
ToolTipText="#LangOpenDisk# T:"
Cursor=2

[MeterDiskLabelT]
Meter=String
X=18
Y=723
FontFace=#FontMain#
FontSize=8
FontWeight=600
FontColor=#ColorTextPrimary#
AntiAlias=1
Text="Thrash (T:)"

[MeterDiskValueT]
Meter=String
MeasureName=MeasureFreeT
X=222
Y=723
StringAlign=Right
FontFace=#FontMain#
FontSize=8
FontColor=#ColorTextSecondary#
AntiAlias=1
AutoScale=1
NumOfDecimals=0
DynamicVariables=1
Text="[MeasureFreePercentT:0]% #LangFree#  (%1)"

[MeterDiskBarBgT]
Meter=Shape
X=18
Y=737
Shape=Rectangle 0,0,204,3,1 | Fill Color #ColorBarBg# | StrokeWidth 0

[MeterDiskBarT]
Meter=Bar
MeasureName=MeasureUsedPercentT
X=18
Y=737
W=204
H=3
BarColor=#ColorBarFill#
BarOrientation=Horizontal

[MeterDiskRowW]
Meter=Shape
X=12
Y=746
Shape=Rectangle 0,0,(#SkinWidth# - 24),20,2 | Fill Color 255,255,255,3 | StrokeWidth 0
MouseOverAction=[!SetOption MeterDiskRowW Fill "Color 255,255,255,15"][!Redraw]
MouseLeaveAction=[!SetOption MeterDiskRowW Fill "Color 255,255,255,3"][!Redraw]
LeftMouseUpAction=["explorer.exe" "W:"]
ToolTipText="#LangOpenDisk# W:"
Cursor=2

[MeterDiskLabelW]
Meter=String
X=18
Y=746
FontFace=#FontMain#
FontSize=8
FontWeight=600
FontColor=#ColorTextPrimary#
AntiAlias=1
Text="Work (W:)"

[MeterDiskValueW]
Meter=String
MeasureName=MeasureFreeW
X=222
Y=746
StringAlign=Right
FontFace=#FontMain#
FontSize=8
FontColor=#ColorTextSecondary#
AntiAlias=1
AutoScale=1
NumOfDecimals=0
DynamicVariables=1
Text="[MeasureFreePercentW:0]% #LangFree#  (%1)"

[MeterDiskBarBgW]
Meter=Shape
X=18
Y=760
Shape=Rectangle 0,0,204,3,1 | Fill Color #ColorBarBg# | StrokeWidth 0

[MeterDiskBarW]
Meter=Bar
MeasureName=MeasureUsedPercentW
X=18
Y=760
W=204
H=3
BarColor=#ColorBarFill#
BarOrientation=Horizontal

