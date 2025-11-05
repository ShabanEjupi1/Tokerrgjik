@echo off
REM Run Flutter Web with CORS disabled for development
REM This allows the app to make requests to external APIs during development

echo Starting TokerrGjik Flutter Web with CORS disabled...
echo.
echo WARNING: This is for DEVELOPMENT ONLY!
echo Do not use --disable-web-security in production.
echo.

cd /d "%~dp0tokerrgjik_mobile"

flutter run -d chrome --web-browser-flag="--disable-web-security" --web-browser-flag="--user-data-dir=C:\Temp\chrome_dev"

pause
