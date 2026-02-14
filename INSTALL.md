# RTDink -- Build Instructions

See [README.md](README.md) for download links if you just want to play the game.

## Platform Overview

| Platform | Build System | Notes |
|----------|-------------|-------|
| **Windows** | Visual Studio 2017+ | Proton SDK sibling layout, uses FMOD for audio |
| **Linux** | CMake | Proton SDK cloned inside project, uses SDL2 + SDL2_mixer for audio |
| **iOS** | Xcode | Proton SDK sibling layout, uses FMOD for audio |
| **Android** | Gradle + CMake | Proton SDK sibling layout, uses FMOD for audio |
| **macOS** | Xcode | Broken/unmaintained |
| **HTML5** | Emscripten | See [Proton HTML5 setup](https://www.rtsoft.com/wiki/doku.php?id=proton:html5_setup) |

All platforms require the **Dink Smallwood game data** (`dink/` directory) to play. See [README.md](README.md#game-data-requirement) for how to obtain it.

Most platforms (except Linux) expect the **Proton SDK sibling layout** -- RTDink is cloned inside the Proton directory:

```
proton/
  shared/          <-- Proton SDK
  RTDink/          <-- this repo
```

---

## Windows

Full step-by-step instructions are in [README.md](README.md#windows), including FMOD setup and required DLLs.

The short version:

```
proton/
  shared/          <-- Proton SDK
  RTDink/          <-- this repo
    windows_vs2017/
      iPhoneRTDink.sln
```

1. Clone [Proton SDK](https://github.com/SethRobinson/proton)
2. Clone this repo inside the Proton directory
3. Run `media\update_media.bat`
4. Set up FMOD (see [README.md](README.md#step-2---getting-fmod-and-building-rtsimpleapp-in-fmod-mode))
5. Open `windows_vs2017/iPhoneRTDink.sln` in Visual Studio
6. Build `Release GL | x64`, copy DLLs and game data to `bin/`

---

## iOS

The Xcode project at the repo root (`RTDink.xcodeproj`) includes iOS targets. It uses the Proton SDK sibling layout:

```
proton/
  shared/          <-- Proton SDK
  RTDink/
    RTDink.xcodeproj
```

1. Clone [Proton SDK](https://github.com/SethRobinson/proton)
2. Clone this repo inside the Proton directory
3. Open `RTDink.xcodeproj` in Xcode
4. Select the iOS target/device and build
5. You will need an Apple Developer account for device deployment

---

## Android

The Android build uses Gradle with CMake for native code. It uses the Proton SDK sibling layout:

```
proton/
  shared/          <-- Proton SDK
  RTDink/
    AndroidGradle/
      app/
        src/main/cpp/CMakeLists.txt   <-- references ../../../../../../shared
```

1. Clone [Proton SDK](https://github.com/SethRobinson/proton)
2. Clone this repo inside the Proton directory
3. Copy `AndroidGradle/local.properties_removethispart_` to `AndroidGradle/local.properties` and edit it with your Android SDK path, keystore info, and package name
4. Run `media\update_media.bat` to prepare assets (or ensure `bin/interface` and `bin/audio` exist)
5. Open `AndroidGradle/` in Android Studio
6. `PrepareResources.bat` runs automatically during the build to copy assets and shared Java sources from the Proton SDK
7. Build and deploy

**Note:** The game data for Android comes from `bin/dink_for_android/` (a trimmed version of the game data). See `PrepareResources.bat` for details on what gets packaged into the APK.

---

## macOS (broken/unmaintained)

> **Note:** The macOS build has not been maintained for a long time and likely does not build without fixes. It is left here for reference.

The Xcode project is at the repo root (`RTDink.xcodeproj`). Same sibling layout as Windows:

```
proton/
  shared/          <-- Proton SDK
  RTDink/
    RTDink.xcodeproj
```

1. Clone [Proton SDK](https://github.com/SethRobinson/proton)
2. Clone this repo inside the Proton directory
3. Open `RTDink.xcodeproj` in Xcode
4. Build and run (may require fixes)

---

## Linux

### Quick setup (Ubuntu/Debian)

The easiest way is to use the automated script from the repo root:

```sh
./linux_setup.sh
```

This installs dependencies, clones the Proton SDK, builds RTDink, and optionally downloads the game data.

### Manual build

#### Prerequisites

- **C++ Compiler:** GCC 7+ or Clang 7+
- **CMake:** 3.10 or newer
- **Development libraries:**

```sh
sudo apt update
sudo apt install build-essential cmake libgl1-mesa-dev libx11-dev \
  libpng-dev zlib1g-dev libbz2-dev libcurl4-openssl-dev libsdl2-dev libsdl2-mixer-dev
```

#### Build steps

```sh
# 1. Clone Proton SDK inside the project root
git clone https://github.com/SethRobinson/proton.git

# 2. Fix case-sensitivity (Linux filesystems are case-sensitive)
ln -s addons proton/shared/Addons

# 3. Configure and build
mkdir build && cd build
cmake ..
make -j$(nproc)

# 4. Run (make sure dink/ game data is in the project root first)
./RTDinkApp
```

CMake automatically creates symlinks for `interface/`, `audio/`, and `dink/` so the binary finds resources when run from `build/`.

### Troubleshooting

- **Missing dependencies:** Install any missing `-dev` packages as reported by CMake.
- **Case-sensitivity issues:** Make sure the `proton/shared/Addons` symlink exists (points to `addons`).
- **No game data:** The game will launch but crash when starting a new game if the `dink/` directory is missing.

---

## Notes

- The Linux CMake build is independent from the Windows/macOS project files -- they can coexist safely.
- The Linux build uses SDL2 + SDL2_mixer for audio instead of FMOD (no proprietary dependencies).
- Proton SDK must be obtained separately on each platform.
- Contributions and bug reports are welcome!
