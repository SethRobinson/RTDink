# AGENTS.md

Project operating instructions for AI assistants working in this repository.

## Shared Project Memory

- Read this file before doing any work in this repository.
- Treat this file as the shared project memory for AI assistants.
- Do not rely on vendor-specific, proprietary, or hidden memory systems for project facts, preferences, or operating instructions. (except to remember to ALWAYS read this file first before doing anything.  Remember that.)
- Update this file with important repo-specific information learned during work, including build commands, test commands, conventions, decisions, pitfalls, and current project preferences.
- Keep this file accurate and current. Remove or correct stale, misleading, or incorrect information when discovered.
- If information is temporary or uncertain, label it clearly rather than presenting it as permanent fact.

## Testing

- When possible, design automated tests for new features and bug fixes.
- Run relevant automated tests after finishing changes to guard against regressions.
- If tests cannot be run or do not exist, state that clearly in the handoff and describe any manual verification performed.

### Automated smoke test (`-autotest`, added July 2026)

The game has a self-driving smoke test: `dink -autotest` (implies `-window` and
`-skip`, forces a 1024x768 window) runs one scripted session that screenshots
the main menu, installs a DMOD through the live dinknetwork.com browser
pipeline, installs a DMOD from a URL, starts a new game and screenshots it,
deletes everything it installed (saves/continue state are preserved via
backup+restore), writes `autotest/autotest_results.txt` plus
`autotest_mainmenu.png` / `autotest_newgame.png` in the save dir, and quits.
The results file is the authoritative pass/fail channel (`SUMMARY: PASS (5/5)`
on the last line; the process exit code is always 0). Implementation:
`source/AutoTester.cpp` state machine, hooked from `App::Update`/`App::Draw`;
the two test DMODs are constants at the top of that file (browser test looks
up "Cycles of Evil" in the live list; URL test downloads the 24K
`abcdefgh.dmod`, plain http because the Mac build's NetHTTP has no TLS).

Per-platform driver scripts (all honor `NO_PAUSE=1`, exit 0/1, copy artifacts
to `script\testruns\<platform>\`, which is gitignored):

- `script\TestWindows.bat` - runs `bin\winRTDink_Release GL.exe`; build first.
- `script\TestMac.bat` - runs the last dev build on studiomac over ssh
  (`OSX/build/Release/Dink Smallwood HD.app`, produced by BuildMac.bat).
  Requires seth logged into the mac's GUI session.
- `script\TestLinux.bat` - runs the installed flatpak on glados over ssh with
  `DISPLAY=:0` (glados has a real display). BuildFlatpak.bat installs the
  flatpak; rebuild before testing or you test a stale binary.

Gotcha: the Cocoa entry path on Mac never passed argv to the app; `App::Init`
now ingests it via `_NSGetArgc/_NSGetArgv` (this also made `-game`/`-window`
etc work on Mac for the first time).


## Security

- Never commit sensitive data, including credentials, tokens, passwords, private keys, cookies, customer data, personal data, or machine-specific authentication material.
- If an AI assistant needs authentication data or other secrets for local work, use `agents_secret.md` for those notes.
- `agents_secret.md` must stay ignored by git and must not be committed.
- Do not put secrets in commit messages, logs, issue text, pull request descriptions, generated docs, or other tracked files.
- Before committing, review staged changes for accidental secrets.

## Git

- Never add OpenAI/Codex/Claude etc as a co-author on git commits.
- NEVER `git push` unless Seth explicitly says to push. "Commit" means commit
  locally only; committing is not permission to push.

## Building (verified July 2026)

### Windows (Release GL x64)

Requires the Proton SDK sibling layout (this repo lives at `proton/RTDink`, SDK at
`proton/shared`) and VS 2026 (v18) Community. Command-line build that works:

```
"C:\Program Files\Microsoft Visual Studio\18\Community\MSBuild\Current\Bin\MSBuild.exe" windows_vs2017\iPhoneRTDink.sln /p:Configuration="Release GL" /p:Platform=x64 /m
```

Output: `bin\winRTDink_Release GL.exe`. Only deprecation warnings expected
(boost bind placeholders, std::iterator, ClanLib unary minus).

### Windows packaging (`script\BuildAndPackageWindows.bat`)

- Does NOT compile; it packages an already-built `winRTDink_Release GL.exe` into
  `dink.exe`, builds the NSIS installer (`DinkSmallwoodHDInstaller.exe`), and stages
  a portable tree in `script\builds\win`.
- Needs env vars `RT_PROJECTS` (d:\projects) and `RT_PROTON_UTIL`
  (proton\shared\win\utils), plus NSIS at `d:\projects\util\NSIS`.
- It deletes local saves in `bin\dink` (save*.dat, quicksave, autosave,
  continue_state.dat) as a packaging cleanup step; expected.
- sign.bat (in `%RT_PROJECTS%\Signing`, outside this repo) requires THREE args:
  file, description, info URL (feeds signtool `/d` and `/du`). Calling it with 2
  args makes `/du` eat the filename and signing fails. Fixed July 2026: the script
  now passes the URL and aborts if signing fails.
- The staged readme comes from `script\win_installer\readme.txt` (same file the
  NSIS installer ships); the repo root has README.md only.

### Flatpak (`script\BuildFlatpak.bat [x86_64|aarch64] [local]`)

- Builds remotely on the `glados` Linux box over ssh. By default it pushes
  committed HEAD to a `flatpak-build` branch there; uncommitted local changes are
  NOT included.
- Pass `local` (any position) to build the current working tree instead: the
  script makes a throwaway snapshot commit via a temp index (your real index and
  any staged files are untouched) and pushes that. `.gitignore` is respected, and
  saves/`agents_secret.md` are force-stripped from the snapshot as a second layer.
  The CMake install rule also excludes `save*.dat`/`quicksave`/`autosave*`/
  `continue_state` from the flatpak itself, so saves have three layers keeping
  them out.
- The script checks for the freedesktop 24.08 Platform+Sdk on glados and installs
  them `--user` if missing.
- The remote flatpak-builder command runs with `set -o pipefail` so the
  `| tail -5` pipe cannot hide a failed build; the script exits 1 on failure and
  0 on success, and honors `NO_PAUSE=1` to skip the final `pause` for automation.

### macOS (`script/BuildMac.bat [local] [nonotarize] [adhoc]`) (verified July 2026)

- Builds remotely on `seth@studiomac.local` over ssh, same pattern as the
  Flatpak script: pushes committed HEAD (or a `local` working-tree snapshot)
  to a `mac-desktop-build` branch in `~/projects/proton/RTDink` on the Mac,
  runs `script/BuildAndPackageMac.sh` there, and copies the finished
  `DinkSmallwoodHD.dmg` back to `script/`. Honors `NO_PAUSE=1`.
- Layout on the Mac mirrors Windows: RTDink is cloned INSIDE the proton
  checkout (`~/projects/proton/RTDink`). The Xcode project
  (`OSX/RTDink.xcodeproj`) references `../../shared` and `../../RTSimpleApp`,
  so a sibling layout does NOT work.
- Universal binary (arm64 + x86_64), macOS 11+. Audio is SDL2_mixer
  (`RT_USE_SDL_AUDIO`, the define is read by proton's AudioManagerSDL.h), no
  FMOD. Gamepads via GamepadProviderSDL2.
- SDL2/SDL2_mixer come from `~/Library/Frameworks` (official universal DMG
  releases, see INSTALL.md). Install with `ditto`/`cp -R`, never `cp -r`,
  which flattens the framework symlinks and later breaks codesign with
  "bundle format is ambiguous".
- Dev builds (plain `xcodebuild -configuration Release`) are ad-hoc signed so
  they work over ssh with a locked keychain, and load SDL2 from
  `~/Library/Frameworks`. The package script embeds the frameworks into the
  .app and does the real Developer ID signing (sign framework `Versions/A`,
  not the top-level `.framework` dir).
- Signing identity: `Developer ID Application: Robinson Technologies
  Corporation (7DA5SJEYK8)` (the old team MK4EZB35P7 found in ancient configs
  is dead). Over ssh the login keychain shows up locked; the package script
  unlocks it with the password read from `~/.rtdink_keychain_pass` on the Mac
  (chmod 600, never committed anywhere).
- Notarization reuses the `patchy-notary` notarytool keychain profile that
  was set up for the Patchy project (the credentials are Apple ID + team, not
  app specific). Override with the NOTARY_PROFILE env var if needed.
- Gotcha fixed July 2026: on OSX `GetDMODRootPath()` returns the absolute
  save path, so it must not be passed to
  `CreateDirectoryRecursively(GetSavePath(), ...)` the way the relative
  Windows/Linux "dmods/" values are; doing so recreates the save dir inside
  itself.
- The game's save dir and log.txt on the Mac:
  `~/Library/Application Support/Dink Smallwood HD/`.
- History note: `.gitignore` used to ignore the whole `OSX` dir, which is why
  mac files kept going "missing" from the repo (e.g. MainMenu.xib in PR #23).
  Now only `OSX/build`, the generated xcworkspace, and stale local junk are
  ignored.

## Releasing ("Build all three releases of the apps and upload them")

When Seth asks for this, build and upload the Windows, Mac, and Linux releases.
All three are hosted at `https://www.rtsoft.com/dink/<file>`; the upload
scripts use `%RT_PROJECTS%\UploadFileToRTsoftSSH.bat <file> dink` and honor
`NO_PAUSE=1`. README.md's download table links to these exact filenames, so
don't rename anything.

1. Run the smoke tests first (`script\TestWindows.bat` etc., see Testing
   above) so you don't ship a broken build.
2. **Windows**: build `Release GL x64` with MSBuild (command below), run
   `script\BuildAndPackageWindows.bat` (packages + signs + NSIS installer),
   then `script\UploadWindowsVersion.bat`
   (ships `DinkSmallwoodHDInstaller.exe`).
3. **Mac**: `script\BuildMac.bat` (no args: full signed + notarized build,
   takes a few extra minutes for Apple's notary service), then
   `script\UploadMacVersion.bat` (ships `DinkSmallwoodHD.dmg`).
4. **Linux**: `script\BuildFlatpak.bat` (no args builds both x86_64 and
   aarch64), then `script\UploadFlatpakVersion.bat` (ships both
   `DinkSmallwoodHD-<arch>.flatpak` bundles).

The README screenshots (`doc/images/screenshot_*.png`) are copies of
autotest output; refresh them from `script\testruns\windows\` after UI
changes.

### AI-harness shell quirk (Claude Code sandbox on Windows)

The sandboxed shell sets `NoDefaultCurrentDirectoryInExePath=1`, so cmd does not
find `.bat`/`.exe` files in the current directory by bare name. This breaks the
`call setenv.bat` steps inside BuildAndPackageWindows.bat (installer then gets an
empty version string). When an AI session runs REAL builds (Seth wants real
builds, not sandbox-crippled ones), it must clear that variable first and run
without the sandbox, e.g. from PowerShell:

```
Remove-Item env:NoDefaultCurrentDirectoryInExePath -ErrorAction SilentlyContinue
cmd /c ".\BuildAndPackageWindows.bat < nul"
```

Normal interactive shells are unaffected.


