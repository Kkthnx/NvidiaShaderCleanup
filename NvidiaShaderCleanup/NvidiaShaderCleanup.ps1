<#
.SYNOPSIS
    Clears the NVIDIA and Windows DirectX/OpenGL shader caches.

.DESCRIPTION
    NVIDIA Shader Cache Cleanup Utility.

    Use this AFTER installing a new GPU driver, or when games start
    crashing on launch, stuttering, flickering, or showing visual
    artifacts. Stale or corrupted shader caches are a common cause.

    The script:
      1. Stops NVIDIA background apps (NVIDIA App, overlay, Share,
         Broadcast, helpers) so they release file locks.
      2. Temporarily stops the NVIDIA Display Container service so the
         system-profile caches can be cleared, then restarts it.
      3. Deletes the CONTENTS of every known shader-cache folder,
         keeping the folders so the driver refills them in place.
      4. Reports how much disk space was freed.

    The driver and Windows rebuild the caches automatically the next
    time each game is launched. Folders that do not exist are skipped,
    so the script is safe to run on any NVIDIA system.

.PARAMETER DryRun
    Preview mode. Reports what WOULD be cleared and how much space it
    would free, without stopping any process/service or deleting
    anything.

.PARAMETER NoPause
    Do not wait for a key press before exiting. Useful for automation
    or chaining the script after a driver install.

.EXAMPLE
    .\NvidiaShaderCleanup.ps1
    Runs a full cleanup (prompts for admin rights if needed).

.EXAMPLE
    .\NvidiaShaderCleanup.ps1 -DryRun
    Shows what would be cleared without changing anything.

.EXAMPLE
    .\NvidiaShaderCleanup.ps1 -NoPause
    Runs a full cleanup and exits without waiting for a key press.

.NOTES
    Author : Kkthnx
    License: MIT
    Requires: Windows 10/11, an NVIDIA GPU, administrator rights.
#>

[CmdletBinding()]
param (
    [switch]$DryRun,
    [switch]$NoPause
)

# -----------------------------
# Safe Runtime Settings
# -----------------------------
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# -----------------------------
# Self-Elevate (safety net if the .ps1 is launched directly)
# -----------------------------
$isAdmin = ([Security.Principal.WindowsPrincipal] `
        [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "Requesting administrator privileges..."

    $forwardedArgs = @(
        "-NoProfile",
        "-ExecutionPolicy", "Bypass",
        "-File", "`"$PSCommandPath`""
    )
    if ($DryRun) { $forwardedArgs += "-DryRun" }
    if ($NoPause) { $forwardedArgs += "-NoPause" }

    try {
        Start-Process -FilePath "powershell.exe" -Verb RunAs -ArgumentList $forwardedArgs
    }
    catch {
        Write-Host "Elevation was cancelled. Exiting." -ForegroundColor Yellow
    }
    exit
}

# -----------------------------
# Cached Environment Variables
# -----------------------------
$envLocalAppData = $env:LOCALAPPDATA
$envProgramData = $env:ProgramData
$envUserProfile = $env:USERPROFILE
$systemProfile = Join-Path $env:SystemRoot "System32\config\systemprofile"

# -----------------------------
# Helpers
# -----------------------------
function Format-Size {
    param ([long]$Bytes)

    if ($Bytes -ge 1GB) { return ("{0:N2} GB" -f ($Bytes / 1GB)) }
    if ($Bytes -ge 1MB) { return ("{0:N2} MB" -f ($Bytes / 1MB)) }
    if ($Bytes -ge 1KB) { return ("{0:N2} KB" -f ($Bytes / 1KB)) }
    return "$Bytes B"
}

# -----------------------------
# Console Header
# -----------------------------
Clear-Host

Write-Host ""
Write-Host "=================================================" -ForegroundColor DarkGreen
Write-Host " NVIDIA Shader Cache Cleanup Utility" -ForegroundColor Green
Write-Host " Written by Kkthnx" -ForegroundColor Green
Write-Host "=================================================" -ForegroundColor DarkGreen
if ($DryRun) {
    Write-Host " DRY RUN - nothing will be deleted" -ForegroundColor Yellow
    Write-Host "=================================================" -ForegroundColor DarkGreen
}
Write-Host ""

# -----------------------------
# Stop NVIDIA User Processes
# -----------------------------
# These are the NVIDIA App / overlay / capture processes. They are
# not critical and will relaunch on their own. We stop them so any
# open handles to the cache folders are released before cleanup.
$processList = @(
    "NVIDIA app",
    "NVIDIA Share",
    "NVIDIA Web Helper",
    "nvcontainer",
    "NVIDIA Overlay",
    "NVIDIA Broadcast",
    "nvsphelper64"
)

if (-not $DryRun) {
    Write-Host "Stopping NVIDIA background processes..."
    foreach ($processName in $processList) {
        $procs = Get-Process -Name $processName -ErrorAction SilentlyContinue
        if ($procs) {
            try {
                $procs | Stop-Process -Force -ErrorAction SilentlyContinue
                Write-Host "  -> Stopped: $processName"
            }
            catch {
                Write-Host "  -> Could not stop: $processName" -ForegroundColor Yellow
            }
        }
    }
}

# -----------------------------
# Stop NVIDIA Display Container Service
# -----------------------------
# The display driver service (NVDisplay.ContainerLocalSystem) holds
# open handles to the system-profile shader caches. We stop it so
# those caches can be cleared, then restart it afterwards. The screen
# may briefly flicker while the service restarts; this is expected.
$nvServiceName = "NVDisplay.ContainerLocalSystem"
$nvServiceWasRunning = $false

if (-not $DryRun) {
    $nvService = Get-Service -Name $nvServiceName -ErrorAction SilentlyContinue
    if ($nvService -and $nvService.Status -eq "Running") {
        $nvServiceWasRunning = $true
        Write-Host "Stopping service: NVIDIA Display Container LS..."
        try {
            Stop-Service -Name $nvServiceName -Force -ErrorAction Stop
        }
        catch {
            Write-Host "  -> Could not stop the display service (caches in use may be skipped)." -ForegroundColor Yellow
            $nvServiceWasRunning = $false
        }
    }

    # Give Windows time to release file handles.
    Start-Sleep -Seconds 2
}

# -----------------------------
# Cache Paths
# -----------------------------
# Every path below is a documented NVIDIA or Windows shader cache
# location. Missing paths are skipped automatically.
$cachePaths = @(

    # --- Current user: modern NVIDIA driver caches ---
    "$envLocalAppData\NVIDIA\DXCache",
    "$envLocalAppData\NVIDIA\GLCache",
    "$envLocalAppData\NVIDIA\ComputeCache",

    # --- Current user: per-driver-version caches (driver 545.xx+) ---
    "$envUserProfile\AppData\LocalLow\NVIDIA\PerDriverVersion\DXCache",
    "$envUserProfile\AppData\LocalLow\NVIDIA\PerDriverVersion\GLCache",
    "$envUserProfile\AppData\LocalLow\NVIDIA\DXCache",

    # --- Current user: legacy NVIDIA caches ---
    "$envProgramData\NVIDIA Corporation\NV_Cache",
    "$envLocalAppData\NVIDIA Corporation\NV_Cache",

    # --- System profile: caches used by the driver service ---
    "$systemProfile\AppData\LocalLow\NVIDIA\DXCache",
    "$systemProfile\AppData\LocalLow\NVIDIA\PerDriverVersion\DXCache",
    "$systemProfile\AppData\LocalLow\NVIDIA\PerDriverVersion\GLCache",
    "$systemProfile\AppData\Local\NVIDIA\DXCache",
    "$systemProfile\AppData\Local\NVIDIA Corporation\NV_Cache",

    # --- Windows DirectX shader cache (any GPU) ---
    "$envLocalAppData\D3DSCache",
    "$envLocalAppData\Microsoft\D3DSCache"
)

# -----------------------------
# Cleanup Function
# -----------------------------
# Deletes the CONTENTS of a cache folder but keeps the folder itself,
# so the driver recreates files in the same place. In dry-run mode it
# only measures. Returns the number of bytes freed (or that would be).
function Clear-ShaderCache {
    param (
        [Parameter(Mandatory)][string]$Path,
        [switch]$Preview
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        Write-Host "[SKIPPED] $Path" -ForegroundColor DarkGray
        return [long]0
    }

    Write-Host "[FOUND]   $Path"

    $items = Get-ChildItem -LiteralPath $Path -Force -Recurse -ErrorAction SilentlyContinue
    $measure = $items |
        Where-Object { -not $_.PSIsContainer } |
        Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue

    [long]$freed = 0
    if ($measure -and $null -ne $measure.Sum) { $freed = [long]$measure.Sum }

    if ($Preview) {
        Write-Host ("  -> Would free {0}" -f (Format-Size $freed)) -ForegroundColor Yellow
        return [long]$freed
    }

    $items | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue

    $remaining = Get-ChildItem -LiteralPath $Path -Force -ErrorAction SilentlyContinue
    if ($remaining) {
        Write-Host ("  -> Partially cleared ({0} freed, some files in use)" -f (Format-Size $freed)) -ForegroundColor Yellow
    }
    else {
        Write-Host ("  -> Cleared ({0} freed)" -f (Format-Size $freed)) -ForegroundColor Green
    }

    return [long]$freed
}

# -----------------------------
# Execute Cleanup
# -----------------------------
Write-Host ""
Write-Host "Cleaning shader caches..."
Write-Host ""

[long]$totalFreed = 0
foreach ($path in $cachePaths) {
    $totalFreed += Clear-ShaderCache -Path $path -Preview:$DryRun
}

# -----------------------------
# Restart NVIDIA Display Container Service
# -----------------------------
if ($nvServiceWasRunning) {
    Write-Host ""
    Write-Host "Restarting service: NVIDIA Display Container LS..."
    try {
        Start-Service -Name $nvServiceName -ErrorAction Stop
        Write-Host "  -> Restarted" -ForegroundColor Green
    }
    catch {
        Write-Host "  -> Could not restart automatically. It will start on next reboot." -ForegroundColor Yellow
    }
}

# -----------------------------
# Completion
# -----------------------------
Write-Host ""
Write-Host "=================================================" -ForegroundColor DarkGreen
if ($DryRun) {
    Write-Host " Dry Run Complete" -ForegroundColor Green
    Write-Host (" Total space that would be freed: {0}" -f (Format-Size $totalFreed))
}
else {
    Write-Host " Cleanup Complete" -ForegroundColor Green
    Write-Host (" Total space freed: {0}" -f (Format-Size $totalFreed))
}
Write-Host "=================================================" -ForegroundColor DarkGreen
Write-Host ""

if (-not $DryRun) {
    Write-Host "NOTE:" -ForegroundColor Cyan
    Write-Host "Games may stutter or load slowly the first time after"
    Write-Host "this cleanup while shaders are rebuilt. This is normal."
    Write-Host ""
}

# -----------------------------
# Wait for user before closing
# -----------------------------
if (-not $NoPause) {
    Write-Host "Press Enter to exit..."
    Read-Host | Out-Null
}

exit
