:: NvidiaShaderCleanup.bat
::
:: =========================================================
:: NVIDIA Shader Cache Cleanup Launcher
:: Written by Kkthnx
::
:: Double-click this file to run the cleanup. It asks for
:: administrator rights, which are needed to clear the caches
:: owned by the driver service, then runs the PowerShell
:: script sitting next to it.
::
:: Any arguments you pass here are handed to the script, so
:: NvidiaShaderCleanup.bat -DryRun works too.
:: =========================================================

@echo off
setlocal EnableExtensions EnableDelayedExpansion
title NVIDIA Shader Cache Cleanup

set "SCRIPT_DIR=%~dp0"
set "PS_SCRIPT=%SCRIPT_DIR%NvidiaShaderCleanup.ps1"
set "PS_EXE=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"

if not exist "%PS_EXE%" set "PS_EXE=powershell.exe"

if not exist "%PS_SCRIPT%" (
    echo.
    echo [ERROR] Missing PowerShell script:
    echo   %PS_SCRIPT%
    echo.
    echo Keep NvidiaShaderCleanup.bat and NvidiaShaderCleanup.ps1 in the
    echo same folder.
    echo.
    pause
    exit /b 2
)

:: Re-launch elevated if we are not already running as administrator.
:: The script self-elevates as well, but doing it here keeps the
:: console window and its output in one place.
net session >nul 2>&1
if not "%errorlevel%"=="0" (
    echo Requesting administrator rights...
    "%PS_EXE%" -NoLogo -NoProfile -ExecutionPolicy Bypass -Command ^
        "Start-Process -FilePath '%ComSpec%' -ArgumentList @('/c', '\"\"%~f0\" %*\"') -Verb RunAs"
    exit /b %errorlevel%
)

"%PS_EXE%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%" %*
set "RESULT=%errorlevel%"

endlocal & exit /b %RESULT%
