@echo off
CHCP 437 >NUL
setlocal enabledelayedexpansion

set GLADOS_HOST=glados@glados
set GLADOS_REPO=/home/glados/RTDink
set FLATPAK_ID=com.rtsoft.DinkSmallwoodHD
set SCRIPT_DIR=%~dp0

REM -- Parse args: optional arch (default: build all) plus optional "local" flag --
REM    "local" builds the current working tree (uncommitted changes included)
REM    instead of the committed HEAD. .gitignore is respected, so saves,
REM    secrets, and build output never leave this machine.
set REQUESTED=
set LOCAL_MODE=
for %%A in (%*) do (
    if /i "%%~A"=="local" (set LOCAL_MODE=1) else (set REQUESTED=%%~A)
)
if /i "%REQUESTED%"=="arm" set REQUESTED=aarch64
if /i "%REQUESTED%"=="arm64" set REQUESTED=aarch64

if "%REQUESTED%"=="" (
    set DO_X86=1
    set DO_ARM=1
) else if "%REQUESTED%"=="x86_64" (
    set DO_X86=1
    set DO_ARM=
) else if "%REQUESTED%"=="aarch64" (
    set DO_X86=
    set DO_ARM=1
) else (
    echo ERROR: Unknown architecture "%REQUESTED%". Use x86_64, aarch64, or omit for both.
    goto :fail
)

set ARCH_LABEL=
if defined DO_X86 set ARCH_LABEL=x86_64
if defined DO_ARM set ARCH_LABEL=%ARCH_LABEL% aarch64

echo ============================================
echo  Dink Smallwood HD - Flatpak Builder
echo  Architectures:%ARCH_LABEL%
if defined LOCAL_MODE (echo  Source: LOCAL working tree) else (echo  Source: committed HEAD)
echo ============================================
echo.

REM ========== Shared setup ==========
ssh %GLADOS_HOST% "test -d %GLADOS_REPO%/.git" >NUL 2>&1
if not errorlevel 1 goto :repo_ok
echo [setup] RTDink repo not found on glados, cloning...
ssh %GLADOS_HOST% "git clone https://github.com/SethRobinson/RTDink.git %GLADOS_REPO% && git -C %GLADOS_REPO% config user.email 'seth@rtsoft.com' && git -C %GLADOS_REPO% config user.name 'Seth Robinson'"
if errorlevel 1 echo ERROR: Failed to clone repo on glados. & goto :fail
:repo_ok

ssh %GLADOS_HOST% "command -v flatpak-builder" >NUL 2>&1
if not errorlevel 1 goto :builder_ok
echo [setup] Installing flatpak-builder on glados...
ssh -t %GLADOS_HOST% "sudo apt-get update && sudo apt-get install -y flatpak flatpak-builder && flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo && flatpak install --user -y flathub org.freedesktop.Platform//24.08 org.freedesktop.Sdk//24.08"
if errorlevel 1 echo ERROR: Failed to install flatpak tools on glados. & goto :fail
:builder_ok

REM Having flatpak-builder does not mean the runtimes are there; check separately
ssh %GLADOS_HOST% "flatpak info org.freedesktop.Sdk//24.08 >/dev/null 2>&1 && flatpak info org.freedesktop.Platform//24.08 >/dev/null 2>&1" >NUL 2>&1
if not errorlevel 1 goto :runtimes_ok
echo [setup] Installing freedesktop 24.08 Platform and Sdk on glados...
ssh %GLADOS_HOST% "flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo && flatpak install --user -y flathub org.freedesktop.Platform//24.08 org.freedesktop.Sdk//24.08"
if errorlevel 1 echo ERROR: Failed to install freedesktop runtimes on glados. & goto :fail
:runtimes_ok

if not defined DO_ARM goto :qemu_ok
echo [setup] Checking QEMU and aarch64 runtimes on glados...
ssh %GLADOS_HOST% "dpkg -s qemu-user-static 2>/dev/null | grep -q 'Status: install ok installed'" >NUL 2>&1
if not errorlevel 1 goto :qemu_installed
echo Installing qemu-user-static and binfmt-support on glados...
ssh -t %GLADOS_HOST% "sudo apt-get update && sudo apt-get install -y qemu-user-static binfmt-support && sudo systemctl restart systemd-binfmt"
if errorlevel 1 echo ERROR: Failed to install QEMU on glados. & goto :fail
:qemu_installed
ssh %GLADOS_HOST% "flatpak --user info org.freedesktop.Platform/aarch64/24.08" >NUL 2>&1
if not errorlevel 1 goto :arm_runtime_ok
echo Installing aarch64 freedesktop runtime and SDK...
ssh %GLADOS_HOST% "flatpak install --user -y flathub org.freedesktop.Platform/aarch64/24.08 org.freedesktop.Sdk/aarch64/24.08"
if errorlevel 1 echo ERROR: Failed to install aarch64 runtimes. & goto :fail
:arm_runtime_ok
echo Refreshing Flatpak remotes on glados...
ssh %GLADOS_HOST% "flatpak update --user -y"
echo QEMU and aarch64 runtimes OK.
echo.
:qemu_ok

git remote get-url glados >NUL 2>&1
if not errorlevel 1 goto :remote_ok
git remote add glados %GLADOS_HOST%:%GLADOS_REPO%
:remote_ok

REM Detach HEAD on glados so pushing to flatpak-build is never rejected as
REM "branch is currently checked out" (it stays on flatpak-build after a build)
ssh %GLADOS_HOST% "cd %GLADOS_REPO% && git checkout --detach --force HEAD" >NUL 2>&1

if not defined LOCAL_MODE goto :push_head

echo [setup] LOCAL mode: snapshotting working tree. Differences from HEAD:
git status --porcelain
REM Build a throwaway commit of the working tree using a temp index so the
REM real index (anything you have staged) is untouched. .gitignore is
REM respected, so ignored junk (saves, bundles, logs) stays out.
set SNAP_TREE=
set SNAP_COMMIT=
set GIT_INDEX_FILE=%TEMP%\rtdink_flatpak_snapshot_index
del "%GIT_INDEX_FILE%" >NUL 2>&1
git read-tree HEAD
git add -A
REM Belt and braces: never ship saves or AI credential notes, even if
REM someone un-ignores them someday
git rm --cached -q --ignore-unmatch agents_secret.md "bin/dink/save*.dat" "bin/dink/quicksave.dat" "bin/dink/continue_state.dat" "bin/dink/autosave*.dat" "bin/save.dat" >NUL 2>&1
for /f %%T in ('git write-tree') do set SNAP_TREE=%%T
for /f %%C in ('git commit-tree %SNAP_TREE% -p HEAD -m "flatpak local build snapshot (throwaway, not a real commit)"') do set SNAP_COMMIT=%%C
set GIT_INDEX_FILE=
del "%TEMP%\rtdink_flatpak_snapshot_index" >NUL 2>&1
if not defined SNAP_COMMIT echo ERROR: Failed to snapshot working tree. & goto :fail
echo [setup] Pushing working-tree snapshot %SNAP_COMMIT% to glados...
git push glados %SNAP_COMMIT%:refs/heads/flatpak-build --force
if errorlevel 1 echo ERROR: Failed to push to glados. & goto :fail
echo Push OK.
echo.
goto :push_done

:push_head
echo [setup] Pushing committed HEAD to glados (add "local" parm to include uncommitted changes)...
git push glados HEAD:flatpak-build --force
if errorlevel 1 echo ERROR: Failed to push to glados. & goto :fail
echo Push OK.
echo.
:push_done

REM --force resets the work tree to the newly pushed commit even from detached HEAD
ssh %GLADOS_HOST% "cd %GLADOS_REPO% && git checkout --force flatpak-build && git clean -fd -e build-flatpak/ -e build-flatpak-aarch64/ -e .flatpak-builder/"
if errorlevel 1 echo ERROR: Failed to prepare repo on glados. & goto :fail

REM ========== Build x86_64 ==========
if not defined DO_X86 goto :build_arm
echo ============================================
echo  Building: x86_64
echo ============================================
echo.
echo [x86_64 1/4] Building Flatpak...
REM pipefail keeps the tail pipe from hiding a failed build exit code
ssh %GLADOS_HOST% "cd %GLADOS_REPO% && set -o pipefail && flatpak-builder --user --force-clean --install build-flatpak flatpak/%FLATPAK_ID%.json 2>&1 | tail -5"
if errorlevel 1 echo ERROR: Flatpak build failed for x86_64. & goto :fail
echo Build OK.
echo.
echo [x86_64 2/4] Running smoke test...
ssh %GLADOS_HOST% "timeout 5 flatpak run %FLATPAK_ID% 2>&1; echo SMOKE_TEST_DONE"
echo Smoke test done.
echo.
echo [x86_64 3/4] Exporting .flatpak bundle...
ssh %GLADOS_HOST% "flatpak build-bundle ~/.local/share/flatpak/repo %GLADOS_REPO%/DinkSmallwoodHD-x86_64.flatpak %FLATPAK_ID% 2>&1"
if errorlevel 1 echo ERROR: Failed to export x86_64 bundle. & goto :fail
echo Bundle exported.
echo.
echo [x86_64 4/4] Copying to %SCRIPT_DIR%...
scp %GLADOS_HOST%:%GLADOS_REPO%/DinkSmallwoodHD-x86_64.flatpak "%SCRIPT_DIR%DinkSmallwoodHD-x86_64.flatpak"
if errorlevel 1 echo ERROR: Failed to copy x86_64 bundle. & goto :fail
echo x86_64 done.
echo.

REM ========== Build aarch64 ==========
:build_arm
if not defined DO_ARM goto :summary
echo ============================================
echo  Building: aarch64
echo ============================================
echo.
echo [aarch64 1/4] Building Flatpak...
ssh %GLADOS_HOST% "cd %GLADOS_REPO% && set -o pipefail && flatpak-builder --user --force-clean --install --arch=aarch64 build-flatpak-aarch64 flatpak/%FLATPAK_ID%.json 2>&1 | tail -5"
if errorlevel 1 echo ERROR: Flatpak build failed for aarch64. & goto :fail
echo Build OK.
echo.
echo [aarch64 2/4] Skipping smoke test for cross-compiled build.
echo.
echo [aarch64 3/4] Exporting .flatpak bundle...
ssh %GLADOS_HOST% "flatpak build-bundle --arch=aarch64 ~/.local/share/flatpak/repo %GLADOS_REPO%/DinkSmallwoodHD-aarch64.flatpak %FLATPAK_ID% 2>&1"
if errorlevel 1 echo ERROR: Failed to export aarch64 bundle. & goto :fail
echo Bundle exported.
echo.
echo [aarch64 4/4] Copying to %SCRIPT_DIR%...
scp %GLADOS_HOST%:%GLADOS_REPO%/DinkSmallwoodHD-aarch64.flatpak "%SCRIPT_DIR%DinkSmallwoodHD-aarch64.flatpak"
if errorlevel 1 echo ERROR: Failed to copy aarch64 bundle. & goto :fail
echo aarch64 done.
echo.

REM ========== Summary ==========
:summary
echo ============================================
echo  ALL BUILDS COMPLETE
echo  Bundles in: %SCRIPT_DIR%
echo.
if defined DO_X86 for %%F in ("%SCRIPT_DIR%DinkSmallwoodHD-x86_64.flatpak") do echo   DinkSmallwoodHD-x86_64.flatpak  (%%~zF bytes)
if defined DO_ARM for %%F in ("%SCRIPT_DIR%DinkSmallwoodHD-aarch64.flatpak") do echo   DinkSmallwoodHD-aarch64.flatpak  (%%~zF bytes)
echo ============================================
echo.
echo To install: flatpak install [bundle-file]
echo Usage: %~nx0 [x86_64^|aarch64] [local]   omit arch for both, "local" builds uncommitted working tree
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
