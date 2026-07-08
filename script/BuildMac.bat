@echo off
CHCP 437 >NUL
setlocal enabledelayedexpansion

set MAC_HOST=seth@studiomac.local
set MAC_REPO=projects/proton/RTDink
set MAC_PROTON=projects/proton
set BUILD_BRANCH=mac-desktop-build
set SCRIPT_DIR=%~dp0

REM -- Parse args: optional "local" flag plus optional "nonotarize" --
REM    "local" builds the current working tree (uncommitted changes included)
REM    instead of the committed HEAD. .gitignore is respected, so saves,
REM    secrets, and build output never leave this machine.
REM    "nonotarize" skips the Apple notarization step (quick test builds).
REM    "adhoc" signs ad-hoc instead of Developer ID (no keychain needed,
REM            implies nonotarize; for testing the pipeline only).
set LOCAL_MODE=
set MAC_ARGS=
set MAC_ENV=
for %%A in (%*) do (
    if /i "%%~A"=="local" (set LOCAL_MODE=1) else if /i "%%~A"=="nonotarize" (set MAC_ARGS=nonotarize) else if /i "%%~A"=="adhoc" (set MAC_ENV=CODESIGN_IDENTITY=- & set MAC_ARGS=nonotarize) else (
        echo ERROR: Unknown option "%%~A". Usage: %~nx0 [local] [nonotarize] [adhoc]
        goto :fail
    )
)

echo ============================================
echo  Dink Smallwood HD - Mac Builder
if defined LOCAL_MODE (echo  Source: LOCAL working tree) else (echo  Source: committed HEAD)
if "%MAC_ARGS%"=="nonotarize" (echo  Notarize: NO) else (echo  Notarize: yes)
echo ============================================
echo.

REM ========== Shared setup ==========
ssh %MAC_HOST% "test -d %MAC_REPO%/.git" >NUL 2>&1
if not errorlevel 1 goto :repo_ok
echo [setup] RTDink repo not found on the mac, cloning proton + RTDink...
ssh %MAC_HOST% "mkdir -p projects && cd projects && (test -d proton/.git || git clone https://github.com/SethRobinson/proton.git) && cd proton && git clone https://github.com/SethRobinson/RTDink.git && git -C RTDink config user.email 'seth@rtsoft.com' && git -C RTDink config user.name 'Seth Robinson'"
if errorlevel 1 echo ERROR: Failed to clone repos on the mac. & goto :fail
:repo_ok

REM Shallow clones can't reliably receive pushes; unshallow if needed
ssh %MAC_HOST% "cd %MAC_REPO% && if [ -f .git/shallow ]; then git fetch --unshallow; fi"
ssh %MAC_HOST% "cd %MAC_PROTON% && if [ -f .git/shallow ]; then git fetch --unshallow; fi && git pull --ff-only" >NUL 2>&1

git remote get-url studiomac >NUL 2>&1
if not errorlevel 1 goto :remote_ok
git remote add studiomac %MAC_HOST%:%MAC_REPO%
:remote_ok

REM Detach HEAD on the mac so pushing to the build branch is never rejected as
REM "branch is currently checked out"
ssh %MAC_HOST% "cd %MAC_REPO% && git checkout --detach --force HEAD" >NUL 2>&1

if not defined LOCAL_MODE goto :push_head

echo [setup] LOCAL mode: snapshotting working tree. Differences from HEAD:
git status --porcelain
REM Build a throwaway commit of the working tree using a temp index so the
REM real index (anything you have staged) is untouched. .gitignore is
REM respected, so ignored junk (saves, bundles, logs) stays out.
set SNAP_TREE=
set SNAP_COMMIT=
set GIT_INDEX_FILE=%TEMP%\rtdink_mac_snapshot_index
del "%GIT_INDEX_FILE%" >NUL 2>&1
git read-tree HEAD
git add -A
REM Belt and braces: never ship saves or AI credential notes, even if
REM someone un-ignores them someday
git rm --cached -q --ignore-unmatch agents_secret.md "bin/dink/save*.dat" "bin/dink/quicksave.dat" "bin/dink/continue_state.dat" "bin/dink/autosave*.dat" "bin/save.dat" >NUL 2>&1
for /f %%T in ('git write-tree') do set SNAP_TREE=%%T
for /f %%C in ('git commit-tree %SNAP_TREE% -p HEAD -m "mac local build snapshot (throwaway, not a real commit)"') do set SNAP_COMMIT=%%C
set GIT_INDEX_FILE=
del "%TEMP%\rtdink_mac_snapshot_index" >NUL 2>&1
if not defined SNAP_COMMIT echo ERROR: Failed to snapshot working tree. & goto :fail
echo [setup] Pushing working-tree snapshot %SNAP_COMMIT% to the mac...
git push studiomac %SNAP_COMMIT%:refs/heads/%BUILD_BRANCH% --force
if errorlevel 1 echo ERROR: Failed to push to the mac. & goto :fail
echo Push OK.
echo.
goto :push_done

:push_head
echo [setup] Pushing committed HEAD to the mac (add "local" parm to include uncommitted changes)...
git push studiomac HEAD:%BUILD_BRANCH% --force
if errorlevel 1 echo ERROR: Failed to push to the mac. & goto :fail
echo Push OK.
echo.
:push_done

REM --force resets the work tree to the newly pushed commit even from detached HEAD
ssh %MAC_HOST% "cd %MAC_REPO% && git checkout --force %BUILD_BRANCH% && git clean -fd"
if errorlevel 1 echo ERROR: Failed to prepare repo on the mac. & goto :fail

REM ========== Build, sign, notarize ==========
echo [1/2] Building and packaging on the mac (see BuildAndPackageMac.sh)...
ssh %MAC_HOST% "cd %MAC_REPO%/script && %MAC_ENV% bash BuildAndPackageMac.sh %MAC_ARGS%"
if errorlevel 1 echo ERROR: Mac build/package failed. & goto :fail
echo Build OK.
echo.

echo [2/2] Copying DMG to %SCRIPT_DIR%...
scp %MAC_HOST%:%MAC_REPO%/script/builds/mac/DinkSmallwoodHD.dmg "%SCRIPT_DIR%DinkSmallwoodHD.dmg"
if errorlevel 1 echo ERROR: Failed to copy DMG. & goto :fail

REM ========== Summary ==========
echo ============================================
echo  MAC BUILD COMPLETE
for %%F in ("%SCRIPT_DIR%DinkSmallwoodHD.dmg") do echo   DinkSmallwoodHD.dmg  (%%~zF bytes)
echo ============================================
echo.
echo Usage: %~nx0 [local] [nonotarize] [adhoc]
echo.
goto :done

:fail
echo.
echo Build failed.
if not defined NO_PAUSE pause
exit /b 1

:done
if not defined NO_PAUSE pause
exit /b 0
