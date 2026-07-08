@echo off
setlocal
REM ============================================================
REM  Dink Smallwood HD - Mac automated smoke test (remote)
REM
REM  Runs the LAST BUILT dev binary on the mac over ssh with
REM  -autotest, then copies the artifacts (screenshots + results)
REM  back to script\testruns\mac\ and reports PASS/FAIL.
REM
REM  Prerequisites:
REM    - Build first with BuildMac.bat (any mode); this script does
REM      not rebuild.
REM    - User "seth" must be logged into the mac's GUI session
REM      (a windowed app launched over ssh attaches to it).
REM
REM  Honors NO_PAUSE=1.  Exits 0 on pass, 1 on fail.
REM ============================================================

set MAC_HOST=seth@studiomac.local
set MAC_APP_BIN=$HOME/projects/proton/RTDink/OSX/build/Release/Dink Smallwood HD.app/Contents/MacOS/Dink Smallwood HD
set MAC_AUTOTEST_DIR=Library/Application Support/Dink Smallwood HD/autotest
set SCRIPT_DIR=%~dp0
set OUT_DIR=%SCRIPT_DIR%testruns\mac

ssh %MAC_HOST% "test -f '%MAC_APP_BIN%'" >NUL 2>&1
if not errorlevel 1 goto :app_ok
echo ERROR: No built app on the mac. Run BuildMac.bat first (e.g. BuildMac.bat local nonotarize).
goto :fail
:app_ok

ssh %MAC_HOST% "rm -rf '$HOME/%MAC_AUTOTEST_DIR%'"

echo Running autotest on the mac (a game window opens on its screen, ~1-2 minutes)...
ssh %MAC_HOST% "'%MAC_APP_BIN%' -autotest"

ssh %MAC_HOST% "test -f '$HOME/%MAC_AUTOTEST_DIR%/autotest_results.txt'" >NUL 2>&1
if not errorlevel 1 goto :results_ok
echo ERROR: No results file was written on the mac. Is anyone logged into its GUI session?
echo Check the game log: ssh %MAC_HOST% "cat '$HOME/Library/Application Support/Dink Smallwood HD/log.txt'"
goto :fail
:results_ok

if not exist "%OUT_DIR%" mkdir "%OUT_DIR%"
scp -q %MAC_HOST%:"'%MAC_AUTOTEST_DIR%/autotest_results.txt'" "%OUT_DIR%\" || goto :fail
scp -q %MAC_HOST%:"'%MAC_AUTOTEST_DIR%/'*.png" "%OUT_DIR%\" >NUL 2>&1

echo.
echo ---- autotest_results.txt ----
type "%OUT_DIR%\autotest_results.txt"
echo ------------------------------
echo Artifacts copied to %OUT_DIR%
echo.

findstr /C:"SUMMARY: PASS" "%OUT_DIR%\autotest_results.txt" >NUL
if errorlevel 1 goto :fail

echo MAC AUTOTEST: PASS
if not defined NO_PAUSE pause
exit /b 0

:fail
echo MAC AUTOTEST: FAIL
if not defined NO_PAUSE pause
exit /b 1
