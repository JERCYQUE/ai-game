# tools/export_release.ps1
# Release export for Windows without the MCP dev addon.
#
# Why this script exists: the MCPRuntimeProbe autoload lives in project.godot, but its
# script (addons/godot_mcp) is excluded from the export - so a plain export produces a
# build that fails on startup. This script temporarily removes the autoload, exports,
# and restores project.godot afterwards.
#
# Usage:  powershell -ExecutionPolicy Bypass -File tools\export_release.ps1

param(
    [string]$Godot = "D:\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe",
    [string]$Preset = "Windows Desktop",
    [string]$Output = "build/AIGame.exe"
)

$ErrorActionPreference = "Stop"

$projectDir = Split-Path -Parent $PSScriptRoot
$projectFile = Join-Path $projectDir "project.godot"
$backupFile = "$projectFile.bak"

if (-not (Test-Path $Godot)) { throw "Godot executable not found: $Godot (pass -Godot <path>)" }
if (-not (Test-Path $projectFile)) { throw "project.godot not found in $projectDir" }

$outDir = Split-Path -Parent (Join-Path $projectDir $Output)
$null = New-Item -ItemType Directory -Force -Path $outDir

Copy-Item $projectFile $backupFile -Force
try {
    $content = Get-Content $projectFile -Raw
    $content = $content -replace '(?m)^MCPRuntimeProbe=.*\r?\n', ''
    Set-Content -Path $projectFile -Value $content -NoNewline

    Write-Host "Exporting preset '$Preset' -> $Output ..."
    # Start-Process -Wait: the Godot editor build is a GUI-subsystem exe, calling it
    # with '&' does not reliably wait nor set $LASTEXITCODE.
    $proc = Start-Process -FilePath $Godot `
        -ArgumentList @('--headless', '--path', "`"$projectDir`"", '--export-release', "`"$Preset`"", "`"$Output`"") `
        -PassThru -Wait -NoNewWindow
    if ($proc.ExitCode -ne 0) { throw "Export failed with exit code $($proc.ExitCode)" }

    $exe = Join-Path $projectDir $Output
    $sizeMb = [math]::Round((Get-Item $exe).Length / 1MB, 1)
    Write-Host "Done: $exe ($sizeMb MB)"
}
finally {
    Move-Item $backupFile $projectFile -Force
    Write-Host "project.godot restored (dev autoload is back)"
}
