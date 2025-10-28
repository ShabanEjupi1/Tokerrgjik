@echo off
echo ========================================
echo    Tokerrgjik - Flutter Web Launcher
echo ========================================
echo.

REM Add Flutter to PATH
set PATH=%PATH%;C:\src\flutter\bin

REM Navigate to mobile app directory
cd /d "%~dp0tokerrgjik_mobile"

echo Current directory: %CD%
echo.
echo Starting Flutter web app in Chrome...
echo.
echo Press Ctrl+C to stop the app
echo ========================================
echo.

flutter run -d chrome

pause
