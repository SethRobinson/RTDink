@echo off
setlocal DisableDelayedExpansion
cd /d "%~dp0" || exit /b 1
call .\build_release.bat nopause
if errorlevel 1 exit /b 1
call .\UploadToWebsite.bat %1
if errorlevel 1 exit /b 1
if /i not "%~1"=="nobrowser" pause
exit /b 0
