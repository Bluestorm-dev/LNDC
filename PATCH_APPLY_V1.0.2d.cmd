@echo off
setlocal
cd /d "%~dp0"
echo Application du hotfix V1.0.2d...
node tools\apply-v1.0.2d.mjs
if errorlevel 1 (
  echo.
  echo ERREUR pendant l'application du patch.
  pause
  exit /b 1
)
echo.
echo Patch applique. Lance ensuite le SQL Supabase puis :
echo npx supabase functions deploy sync-football-data
echo node tests\test-v1.0.2d.mjs
pause
