@echo off
cd /d "%~dp0"
node tools\apply-v1.0.2c.mjs
if errorlevel 1 (
  echo.
  echo ERREUR pendant l'application du patch.
  pause
  exit /b 1
)
echo.
echo Patch V1.0.2c applique.
echo Execute maintenant le SQL dans Supabase puis redeploie sync-football-data.
pause
