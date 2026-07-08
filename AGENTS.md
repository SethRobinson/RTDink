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


## Security

- Never commit sensitive data, including credentials, tokens, passwords, private keys, cookies, customer data, personal data, or machine-specific authentication material.
- If an AI assistant needs authentication data or other secrets for local work, use `agents_secret.md` for those notes.
- `agents_secret.md` must stay ignored by git and must not be committed.
- Do not put secrets in commit messages, logs, issue text, pull request descriptions, generated docs, or other tracked files.
- Before committing, review staged changes for accidental secrets.

## Git

- Never add OpenAI/Codex/Claude etc as a co-author on git commits.

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
- Notarization uses a notarytool keychain profile named `rtsoft-notary`;
  the one-time `store-credentials` setup command is in the header of
  BuildAndPackageMac.sh.
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


