:: NvidiaShaderCleanup.bat
::
:: =========================================================
:: NVIDIA Shader Cache Cleanup Launcher
:: Written by Kkthnx
::
:: Double-click this file to run the cleanup. It will ask for
:: administrator rights (needed to clear the system-profile
:: caches) and then run the PowerShell script next to it.
:: =========================================================

@echo off
setlocal EnableExtensions
title NVIDIA Shader Cache Cleanup

:: Check for admin rights; relaunch elevated if needed.
net session >nul 2>&1
if %errorlevel% neq 0 (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ^
    "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

set "SCRIPT_DIR=%~dp0"
set "PS_SCRIPT=%SCRIPT_DIR%NvidiaShaderCleanup.ps1"

if not exist "%PS_SCRIPT%" (
    echo.
    echo [ERROR] Missing PowerShell script:
    echo %PS_SCRIPT%
    echo.
    pause
    exit /b 1
)

powershell.exe ^
 -NoLogo ^
 -NoProfile ^
 -ExecutionPolicy Bypass ^
 -File "%PS_SCRIPT%"

endlocal
