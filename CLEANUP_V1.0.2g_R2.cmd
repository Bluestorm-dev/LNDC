@echo off
setlocal
cd /d "%~dp0"
node tools\cleanup-v1.0.2g-r2.mjs
if errorlevel 1 (
  echo.
  echo ECHEC DU NETTOYAGE.
  pause
  exit /b 1
)
echo.
echo Nettoyage termine.
pause
