# Dynamic generation of storage drives for Darksidebar-11
param(
    [string]$CacheDir = (Join-Path (Split-Path $PSScriptRoot) "Cache"),
    [switch]$IncludeRemovable = $false,
    [switch]$IncludeNetwork = $false
)

$targetInc = Join-Path $CacheDir "disks-generated.inc"
$targetVars = Join-Path $CacheDir "disks-vars.inc"
if (-not (Test-Path $CacheDir)) {
    New-Item -ItemType Directory -Path $CacheDir -Force | Out-Null
}

$filter = "DriveType=3" # Fixed local drives
if ($IncludeRemovable -and $IncludeNetwork) {
    $filter = "DriveType=2 or DriveType=3 or DriveType=4"
} elseif ($IncludeRemovable) {
    $filter = "DriveType=2 or DriveType=3"
} elseif ($IncludeNetwork) {
    $filter = "DriveType=3 or DriveType=4"
}

$disks = Get-CimInstance Win32_LogicalDisk -Filter $filter -ErrorAction SilentlyContinue | Sort-Object DeviceID

if (-not $disks -or $disks.Count -eq 0) {
    $disks = @([PSCustomObject]@{ DeviceID = "C:"; VolumeName = "System"; Size = 1000000000; FreeSpace = 500000000 })
}

$sb = [System.Text.StringBuilder]::new()
$sb.AppendLine("; Auto-generated Disks topology for Darksidebar-11") | Out-Null
$sb.AppendLine("; Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')") | Out-Null
$sb.AppendLine() | Out-Null

# Measures
foreach ($d in $disks) {
    $letter = $d.DeviceID.Substring(0, 1).ToUpper()
    $sb.AppendLine("[MeasureTotal$letter]") | Out-Null
    $sb.AppendLine("Measure=FreeDiskSpace") | Out-Null
    $sb.AppendLine("Drive=${letter}:") | Out-Null
    $sb.AppendLine("Total=1") | Out-Null
    $sb.AppendLine("UpdateDivider=10") | Out-Null
    $sb.AppendLine() | Out-Null

    $sb.AppendLine("[MeasureFree$letter]") | Out-Null
    $sb.AppendLine("Measure=FreeDiskSpace") | Out-Null
    $sb.AppendLine("Drive=${letter}:") | Out-Null
    $sb.AppendLine("UpdateDivider=10") | Out-Null
    $sb.AppendLine() | Out-Null

    $sb.AppendLine("[MeasureUsedPercent$letter]") | Out-Null
    $sb.AppendLine("Measure=Calc") | Out-Null
    $sb.AppendLine("Formula=Round((MeasureTotal$letter - MeasureFree$letter) / MeasureTotal$letter * 100)") | Out-Null
    $sb.AppendLine("MinValue=0") | Out-Null
    $sb.AppendLine("MaxValue=100") | Out-Null
    $sb.AppendLine("UpdateDivider=10") | Out-Null
    $sb.AppendLine() | Out-Null

    $sb.AppendLine("[MeasureFreePercent$letter]") | Out-Null
    $sb.AppendLine("Measure=Calc") | Out-Null
    $sb.AppendLine("Formula=Round(MeasureFree$letter / MeasureTotal$letter * 100)") | Out-Null
    $sb.AppendLine("MinValue=0") | Out-Null
    $sb.AppendLine("MaxValue=100") | Out-Null
    $sb.AppendLine("UpdateDivider=10") | Out-Null
    $sb.AppendLine("IfCondition=MeasureFreePercent$letter < 10") | Out-Null
    $sb.AppendLine('IfTrueAction=[!SetOption MeterDiskValue' + $letter + ' FontColor "240,110,40,255"]') | Out-Null
    $sb.AppendLine('IfFalseAction=[!SetOption MeterDiskValue' + $letter + ' FontColor "#ColorTextSecondary#"]') | Out-Null
    $sb.AppendLine() | Out-Null
}

# Meters
$startY = 631
$step = 23
$idx = 0

foreach ($d in $disks) {
    $letter = $d.DeviceID.Substring(0, 1).ToUpper()
    $vol = $d.VolumeName
    $label = if ([string]::IsNullOrWhiteSpace($vol)) { "$letter`:" } else { "$vol ($letter`:)" }
    $curY = $startY + ($idx * $step)
    $barY = $curY + 14

    $sb.AppendLine("[MeterDiskRow$letter]") | Out-Null
    $sb.AppendLine("Meter=Shape") | Out-Null
    $sb.AppendLine("X=12") | Out-Null
    $sb.AppendLine("Y=$curY") | Out-Null
    $sb.AppendLine("Shape=Rectangle 0,0,(#SkinWidth# - 24),20,2 | Fill Color 255,255,255,3 | StrokeWidth 0") | Out-Null
    $sb.AppendLine('MouseOverAction=[!SetOption MeterDiskRow' + $letter + ' Fill "Color 255,255,255,15"][!Redraw]') | Out-Null
    $sb.AppendLine('MouseLeaveAction=[!SetOption MeterDiskRow' + $letter + ' Fill "Color 255,255,255,3"][!Redraw]') | Out-Null
    $sb.AppendLine('LeftMouseUpAction=["explorer.exe" "' + $letter + ':"]') | Out-Null
    $sb.AppendLine('ToolTipText="#LangOpenDisk# ' + $letter + ':"') | Out-Null
    $sb.AppendLine("Cursor=2") | Out-Null
    $sb.AppendLine() | Out-Null

    $sb.AppendLine("[MeterDiskLabel$letter]") | Out-Null
    $sb.AppendLine("Meter=String") | Out-Null
    $sb.AppendLine("X=18") | Out-Null
    $sb.AppendLine("Y=$curY") | Out-Null
    $sb.AppendLine("FontFace=#FontMain#") | Out-Null
    $sb.AppendLine("FontSize=8") | Out-Null
    $sb.AppendLine("FontWeight=600") | Out-Null
    $sb.AppendLine("FontColor=#ColorTextPrimary#") | Out-Null
    $sb.AppendLine("AntiAlias=1") | Out-Null
    $sb.AppendLine('Text="' + $label + '"') | Out-Null
    $sb.AppendLine() | Out-Null

    $sb.AppendLine("[MeterDiskValue$letter]") | Out-Null
    $sb.AppendLine("Meter=String") | Out-Null
    $sb.AppendLine("MeasureName=MeasureFree$letter") | Out-Null
    $sb.AppendLine("X=222") | Out-Null
    $sb.AppendLine("Y=$curY") | Out-Null
    $sb.AppendLine("StringAlign=Right") | Out-Null
    $sb.AppendLine("FontFace=#FontMain#") | Out-Null
    $sb.AppendLine("FontSize=8") | Out-Null
    $sb.AppendLine("FontColor=#ColorTextSecondary#") | Out-Null
    $sb.AppendLine("AntiAlias=1") | Out-Null
    $sb.AppendLine("AutoScale=1") | Out-Null
    $sb.AppendLine("NumOfDecimals=0") | Out-Null
    $sb.AppendLine("DynamicVariables=1") | Out-Null
    $sb.AppendLine('Text="[MeasureFreePercent' + $letter + ':0]% #LangFree#  (%1)"') | Out-Null
    $sb.AppendLine() | Out-Null

    $sb.AppendLine("[MeterDiskBarBg$letter]") | Out-Null
    $sb.AppendLine("Meter=Shape") | Out-Null
    $sb.AppendLine("X=18") | Out-Null
    $sb.AppendLine("Y=$barY") | Out-Null
    $sb.AppendLine("Shape=Rectangle 0,0,204,3,1 | Fill Color #ColorBarBg# | StrokeWidth 0") | Out-Null
    $sb.AppendLine() | Out-Null

    $sb.AppendLine("[MeterDiskBar$letter]") | Out-Null
    $sb.AppendLine("Meter=Bar") | Out-Null
    $sb.AppendLine("MeasureName=MeasureUsedPercent$letter") | Out-Null
    $sb.AppendLine("X=18") | Out-Null
    $sb.AppendLine("Y=$barY") | Out-Null
    $sb.AppendLine("W=204") | Out-Null
    $sb.AppendLine("H=3") | Out-Null
    $sb.AppendLine("BarColor=#ColorBarFill#") | Out-Null
    $sb.AppendLine("BarOrientation=Horizontal") | Out-Null
    $sb.AppendLine() | Out-Null

    $idx++
}

# Calculate final Y after disks
$lastDiskBarY = $startY + (($idx - 1) * $step) + 14
$divider4Y = $lastDiskBarY + 23
$hwTitleY = $divider4Y + 20
$hwCpuY = $hwTitleY + 25
$hwCpuBarY = $hwTitleY + 39
$hwRamY = $hwTitleY + 48
$hwRamBarY = $hwTitleY + 62
$hwGpuY = $hwTitleY + 71
$hwGpuBarY = $hwTitleY + 85
$hwVramY = $hwTitleY + 93

# 1. Write separate variables file (disks-vars.inc) - SAFE FOR SETTINGS.INI (NO METERS!)
$varsText = @"
[Variables]
DisksCount=$idx
Divider4Y=$divider4Y
HardwareTitleY=$hwTitleY
HardwareCpuY=$hwCpuY
HardwareCpuBarY=$hwCpuBarY
HardwareRamY=$hwRamY
HardwareRamBarY=$hwRamBarY
HardwareGpuY=$hwGpuY
HardwareGpuBarY=$hwGpuBarY
HardwareVramY=$hwVramY
"@

[System.IO.File]::WriteAllText($targetVars, $varsText, [System.Text.Encoding]::GetEncoding(1251))


# Write disks-generated.inc in CP1251 so Rainmeter parses Russian disk labels with 0 mojibake
[System.IO.File]::WriteAllText($targetInc, $sb.ToString(), [System.Text.Encoding]::GetEncoding(1251))
Write-Host "Generated disks inc with $idx drives in CP1251: $targetInc and $targetVars"