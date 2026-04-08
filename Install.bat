@echo off
chcp 65001 >nul 2>&1
title ELEGOO Saturn 4 Ultra 16K Profile Patch for CHITUBOX Dental

net session >nul 2>&1
if errorlevel 1 (
    echo.
    echo   [*] Requesting Administrator privileges...
    powershell -NoProfile -Command "Start-Process -FilePath \"%~f0\" -Verb RunAs" 2>nul
    exit /b
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0lib\Install.ps1"
set "PS_EXIT=%errorlevel%"

echo.
pause
exit /b %PS_EXIT%
