@echo off
setlocal
REM Uploads the packaged Mac DMG (made by BuildMac.bat) to rtsoft.com/dink/
REM so it's available at https://www.rtsoft.com/dink/DinkSmallwoodHD.dmg
REM (the link README.md's download table points at).  Honors NO_PAUSE=1.

set SCRIPT_DIR=%~dp0
cd /d "%SCRIPT_DIR%"

if exist DinkSmallwoodHD.dmg goto :dmg_ok
echo ERROR: DinkSmallwoodHD.dmg not found. Run BuildMac.bat first (full notarized build for releases).
goto :fail
:dmg_ok

echo Uploading DinkSmallwoodHD.dmg...
call %RT_PROJECTS%\UploadFileToRTsoftSSH.bat DinkSmallwoodHD.dmg dink
if errorlevel 1 (
    echo ERROR: Failed to upload DinkSmallwoodHD.dmg
    goto :fail
)

echo Mac DMG uploaded.
if not defined NO_PAUSE pause
exit /b 0

:fail
if not defined NO_PAUSE pause
exit /b 1
