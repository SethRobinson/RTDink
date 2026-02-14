# Dink Smallwood HD

## Just want to play?

Visit https://www.rtsoft.com/pages/dink.php for installers for Windows, Mac, iOS, and Android.

Also mirrored on The Dink Network: https://www.dinknetwork.com/file/dink_smallwood_hd/

## Building from source

RTDink can be built for multiple platforms. Each uses the [Proton SDK](https://github.com/SethRobinson/proton).  Each has full keyboard and controller support except Linux which is keyboard only.

| Platform | Build System | Quick Start |
|----------|-------------|-------------|
| **Windows** | Visual Studio 2017+ | See [detailed Windows instructions](#windows) below |
| **Linux** | CMake + SDL2 | `git clone ... && ./linux_setup.sh` ([details](#linux)) |
| **macOS** | Xcode | Broken/unmaintained -- see [INSTALL.md](INSTALL.md#macos) |
| **HTML5** | Emscripten | See [Proton HTML5 setup](https://www.rtsoft.com/wiki/doku.php?id=proton:html5_setup) |
| **iOS** | Xcode | Proton SDK sibling layout, open `RTDink.xcodeproj` ([more info](INSTALL.md#ios)) |
| **Android** | Gradle + CMake | Proton SDK sibling layout, open `AndroidGradle/` in Android Studio ([more info](INSTALL.md#android)) |

### Game data requirement

All platforms need the **Dink Smallwood game data** (`dink/` directory) to actually play the game. You can get it from:
* The [Dink Smallwood HD](https://www.rtsoft.com/pages/dink.php) installer (extract the `dink/` folder)
* The classic [Dink Smallwood v1.08](https://www.dinknetwork.com/file/dink_smallwood/) release

---

## Linux

The fastest way to get up and running on Linux (Ubuntu/Debian):

```bash
curl -sL https://raw.githubusercontent.com/SethRobinson/RTDink/master/linux_setup.sh | bash
```

That's it -- the script clones the repo, installs dependencies, builds RTDink, and downloads the game data. By default it installs to `~/DinkSmallwoodHD`.

You can also run it manually if you've already cloned the repo:

```bash
./linux_setup.sh
```

Options: `--no-data` (skip game data download), `--dir=PATH` (custom install directory). See [INSTALL.md](INSTALL.md#linux) for manual build steps.

---

## Windows

RTDink is cloned inside the Proton SDK tree:

```
proton/
  shared/          <-- Proton SDK
  RTDink/          <-- this repo
    windows_vs2017/
      iPhoneRTDink.sln
```

### Step 1 - Getting the Proton SDK and building RTSimpleApp

1. Clone the Proton SDK: `git clone https://github.com/SethRobinson/proton`

2. Run `proton\RTSimpleApp\media\update_media.bat` to prepare the Proton texture and sound assets

3. Open `proton\RTSimpleApp\windows_vc\RTSimpleApp.sln`

4. Select `DebugGL | x64` or `ReleaseGL | x64` configuration, build and run it -- it should work!

NOTE: If you want to build for Win32, you will have to manually copy the 32 bit versions of the following dll files:
* `proton\shared\win\lib\zlib1.dll`
* `proton\shared\win\lib\audiere\bin\audiere.dll`

To restore 64 bit libraries, copy these instead:
* `proton\shared\win\lib\zlib1.dll`
* `proton\shared\win\lib\64\zlibwapi.dll`
* `proton\shared\win\lib\audiere\lib64\audiere.dll`

If you have any issues, check out these two pages for more info on the Proton engine:
* https://www.rtsoft.com/wiki/doku.php?id=proton:win_setup
* https://www.rtsoft.com/wiki/doku.php?id=proton:win_setup2

### Step 2 - Getting FMOD and building RTSimpleApp in FMOD mode

1. Get the **FMOD Studio API** from https://www.fmod.com/download#fmodengine (you will need to register an account)

![](doc/images/fmod_download_example.png)

2. Extract the API files into `proton\shared\win\fmodstudio\`

3. NOTE: You don't need to *INSTALL* the FMOD Engine, you just need to extract the `api\core` subfolder, which you can do with 7zip for example

![](doc/images/fmod_libraries.png)

4. Open `proton\RTSimpleApp\windows_vc\RTSimpleApp.sln` once again

5. Select the `DebugFMOD_GL | x64` or `ReleaseFMOD_GL | x64` configuration -- it should build just fine

6. Copy the FMOD dll into the output folder `proton\RTSimpleApp\bin`:
   * `proton\shared\win\fmodstudio\api\core\lib\x64\fmod.dll`

7. The RTSimpleApp with FMOD enabled should run now!

### Step 3 - Building and running RTDink

1. Go into the `proton` root folder and clone the RTDink repo: `git clone https://github.com/SethRobinson/RTDink`

2. Run `proton\RTDink\media\update_media.bat` to prepare the Proton texture and sound assets

3. Open `proton\RTDink\windows_vs2017\iPhoneRTDink.sln`

4. Select the `Debug GL | x64` or `Release GL | x64` configuration and build

5. Copy the required x64 DLLs and curl certificate into `proton\RTDink\bin`:
   * `proton\shared\win\fmodstudio\api\core\lib\x64\fmod.dll`
   * `proton\shared\win\lib\zlib1.dll`
   * `proton\shared\win\lib\64\zlibwapi.dll`
   * `proton\shared\win\lib\x64\libcurl-x64.dll`
   * `proton\shared\win\lib\x64\libcrypto-1_1-x64.dll`
   * `proton\shared\win\lib\x64\libssl-1_1-x64.dll`
   * `proton\shared\win\lib\x64\curl-ca-bundle.crt`

6. Copy the `dink/` game data folder into `proton\RTDink\bin` (see [game data requirement](#game-data-requirement) above)

7. Your Dink Smallwood HD build should be ready to run!

---

## Credits

The original **Dink Smallwood** (1997) was created by **Seth A. Robinson**, **Justin Martin**, **Greg Smith**, and **Shawn Teal**, with additional music by **Joel Bakker** and **Mitch Brink**.

### Source contributors

* **drone1400** -- division-by-zero fix, pixel-perfect rendering, and build improvements
* **Dan Walma** (yeoldetoast) -- DinkC bug reports and fixes
* **RobJ** -- DinkC command fixes and compatibility improvements
* **SimonK** -- DMOD stress testing and limit increase requests
* **Mateus Sales Bentes** -- Linux port work

Special thanks to the entire [dinknetwork.com](https://www.dinknetwork.com/) community for their Dink creations and support over the years!

---

## Other notes

* **Have a bugfix or patch?** Please submit it as a pull request! Any submission (code, media, translations, etc) must be 100% compatible with the license as listed in the source.

* See `script/win_installer/readme.txt` for version history.