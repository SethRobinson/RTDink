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


