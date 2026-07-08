@echo off
setlocal
REM ============================================================
REM  Dink Smallwood HD - Windows automated smoke test
REM
REM  Runs the already-built exe with -autotest (screenshots the
REM  main menu and a new game, installs a DMOD via the in-game
REM  browser and one from a URL, cleans up, quits) then collects
REM  the artifacts into script\testruns\windows\ and reports
REM  PASS/FAIL.  Build first (see AGENTS.md for the MSBuild
REM  command).  Honors NO_PAUSE=1.  Exits 0 on pass, 1 on fail.
REM ============================================================

set SCRIPT_DIR=%~dp0
set EXE=%SCRIPT_DIR%..\bin\winRTDink_Release GL.exe
set AUTOTEST_DIR=%SCRIPT_DIR%..\bin\autotest
set OUT_DIR=%SCRIPT_DIR%testruns\windows

if exist "%EXE%" goto :exe_ok
echo ERROR: "%EXE%" not found. Build it first, see AGENTS.md.
goto :fail
:exe_ok

if exist "%AUTOTEST_DIR%" rd /s /q "%AUTOTEST_DIR%"

echo Running autotest (the game window will open and drive itself, ~1-2 minutes)...
start "" /wait "%EXE%" -autotest

if exist "%AUTOTEST_DIR%\autotest_results.txt" goto :results_ok
echo ERROR: No results file was written. Check %SCRIPT_DIR%..\bin\log.txt
goto :fail
:results_ok

if not exist "%OUT_DIR%" mkdir "%OUT_DIR%"
xcopy /y /q "%AUTOTEST_DIR%\*" "%OUT_DIR%\" >NUL

echo.
echo ---- autotest_results.txt ----
type "%OUT_DIR%\autotest_results.txt"
echo ------------------------------
echo Artifacts copied to %OUT_DIR%
echo.

findstr /C:"SUMMARY: PASS" "%OUT_DIR%\autotest_results.txt" >NUL
if errorlevel 1 goto :fail

echo WINDOWS AUTOTEST: PASS
if not defined NO_PAUSE pause
exit /b 0

:fail
echo WINDOWS AUTOTEST: FAIL
if not defined NO_PAUSE pause
exit /b 1
