@echo off
setlocal
REM ============================================================
REM  Dink Smallwood HD - Linux automated smoke test (remote)
REM
REM  Runs the INSTALLED flatpak on glados over ssh with -autotest
REM  (glados has a real display, the game window opens there),
REM  then copies the artifacts back to script\testruns\linux\ and
REM  reports PASS/FAIL.
REM
REM  Prerequisites: build+install the flatpak on glados first with
REM  BuildFlatpak.bat (it uses flatpak-builder --install).  This
REM  script does not rebuild, so rebuild after game changes or
REM  you'll be testing an old binary.
REM
REM  Honors NO_PAUSE=1.  Exits 0 on pass, 1 on fail.
REM ============================================================

set GLADOS_HOST=glados@glados
set FLATPAK_ID=com.rtsoft.DinkSmallwoodHD
set REMOTE_DATA_DIR=.var/app/%FLATPAK_ID%/data/dink-smallwood-hd
set SCRIPT_DIR=%~dp0
set OUT_DIR=%SCRIPT_DIR%testruns\linux

ssh %GLADOS_HOST% "flatpak info %FLATPAK_ID% >/dev/null 2>&1"
if not errorlevel 1 goto :flatpak_ok
echo ERROR: %FLATPAK_ID% is not installed on glados. Run BuildFlatpak.bat first.
goto :fail
:flatpak_ok

ssh %GLADOS_HOST% "rm -rf ~/%REMOTE_DATA_DIR%/autotest"

echo Running autotest on glados (a game window opens on its display, ~1-2 minutes)...
REM timeout 720 is a belt-and-braces hang guard on top of the game's own watchdog
ssh %GLADOS_HOST% "export DISPLAY=${DISPLAY:-:0}; export XDG_RUNTIME_DIR=/run/user/$(id -u); timeout 720 flatpak run %FLATPAK_ID% -autotest"

ssh %GLADOS_HOST% "test -f ~/%REMOTE_DATA_DIR%/autotest/autotest_results.txt"
if not errorlevel 1 goto :results_ok
echo ERROR: No results file was written on glados. Is its display reachable (DISPLAY=:0)?
echo Check the game log: ssh %GLADOS_HOST% "cat ~/%REMOTE_DATA_DIR%/log.txt"
goto :fail
:results_ok

if not exist "%OUT_DIR%" mkdir "%OUT_DIR%"
scp -q %GLADOS_HOST%:%REMOTE_DATA_DIR%/autotest/* "%OUT_DIR%\" || goto :fail

echo.
echo ---- autotest_results.txt ----
type "%OUT_DIR%\autotest_results.txt"
echo ------------------------------
echo Artifacts copied to %OUT_DIR%
echo.

findstr /C:"SUMMARY: PASS" "%OUT_DIR%\autotest_results.txt" >NUL
if errorlevel 1 goto :fail

echo LINUX AUTOTEST: PASS
if not defined NO_PAUSE pause
exit /b 0

:fail
echo LINUX AUTOTEST: FAIL
if not defined NO_PAUSE pause
exit /b 1
