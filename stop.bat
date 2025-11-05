@echo off
echo ================================================
echo 🏀 NBA Analysis System - Stop
echo ================================================
echo.

echo Zatrzymywanie aplikacji...
echo.

REM Kill Python processes running main.py
echo Zamykanie backendu...
for /f "tokens=2" %%a in ('tasklist /FI "IMAGENAME eq python.exe" /FO LIST ^| findstr /B "PID:"') do (
    taskkill /PID %%a /F >nul 2>&1
)

REM Kill Node processes
echo Zamykanie frontendu...
for /f "tokens=2" %%a in ('tasklist /FI "IMAGENAME eq node.exe" /FO LIST ^| findstr /B "PID:"') do (
    taskkill /PID %%a /F >nul 2>&1
)

echo.
echo ✅ Aplikacja zatrzymana
echo.
pause
