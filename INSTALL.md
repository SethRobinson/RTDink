# RTDink -- Build Instructions

See [README.md](README.md) for download links if you just want to play the game.

## Platform Overview

| Platform | Build System | Notes |
|----------|-------------|-------|
| **Windows** | Visual Studio 2017+ | Proton SDK sibling layout, uses FMOD for audio |
| **Linux** | CMake | Proton SDK cloned inside project, uses SDL2 + SDL2_mixer for audio |
| **iOS** | Xcode | Proton SDK sibling layout, uses FMOD for audio |
| **Android** | Gradle + CMake | Proton SDK sibling layout, uses FMOD for audio |
| **macOS** | Xcode | Universal binary (Intel + Apple Silicon), uses SDL2 + SDL2_mixer for audio (see [macOS section](#macos)) |
| **HTML5** | Emscripten | See [Proton HTML5 setup](https://www.rtsoft.com/wiki/doku.php?id=proton:html5_setup) |

All platforms require the **Dink Smallwood game data** (`dink/` directory) to play. See [README.md](README.md#just-want-to-play) for how to obtain it.

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

## macOS

The macOS build uses the Xcode project at `OSX/RTDink.xcodeproj`.

- **Supported architectures:** Universal binary — runs natively on both **Intel (x86_64)** and **Apple Silicon (ARM64 / M1+)**.
- **Audio:** Uses **SDL2** + **SDL2_mixer** — no FMOD required.
- **SDL2 frameworks are bundled inside the `.app`** — no SDL2 installation required to run the game.

### Directory layout

Clone both repos as **siblings**:

```
some_folder/
  proton/              <-- Proton SDK (cloned here)
    shared/
  RTDink/              <-- this repo (cloned here)
    OSX/
      RTDink.xcodeproj
```

The Xcode project references `../../shared/` (relative to `OSX/`) to find the Proton SDK.

### Steps

1. Clone the Proton SDK and this repo as siblings:

```bash
git clone https://github.com/SethRobinson/proton.git
git clone https://github.com/SethRobinson/RTDink.git
```

2. Install **SDL2** and **SDL2_mixer** frameworks:

   **Option A — DMG frameworks** (recommended, works on all Macs, required for universal binary):
   ```bash
   # SDL2 framework
   curl -L -o ~/SDL2.dmg "https://github.com/libsdl-org/SDL/releases/download/release-2.30.9/SDL2-2.30.9.dmg"
   hdiutil attach ~/SDL2.dmg
   mkdir -p ~/Library/Frameworks
   cp -r /Volumes/SDL2/SDL2.framework ~/Library/Frameworks/
   hdiutil detach /Volumes/SDL2

   # SDL2_mixer framework
   curl -L -o ~/SDL2_mixer.dmg "https://github.com/libsdl-org/SDL_mixer/releases/download/release-2.8.0/SDL2_mixer-2.8.0.dmg"
   hdiutil attach ~/SDL2_mixer.dmg
   cp -r "/Volumes/SDL2_mixer/SDL2_mixer.framework" ~/Library/Frameworks/
   hdiutil detach /Volumes/SDL2_mixer
   ```
   The Xcode project looks for both frameworks in `~/Library/Frameworks/` automatically. These are universal frameworks (arm64 + x86_64) so the resulting `.app` runs on both Intel and Apple Silicon Macs.

   **Option B — Homebrew** (native arch only, not suitable for universal binary):
   ```bash
   brew install sdl2 sdl2_mixer
   ```
   > **Note:** Homebrew on Apple Silicon only provides arm64 libraries. Use Option A if you need a universal binary.

3. Generate the required libpng config header:

```bash
LIBPNG=proton/shared/Irrlicht/source/Irrlicht/libpng
cp "$LIBPNG/pnglibconf.h.prebuilt" "$LIBPNG/pnglibconf.h"
```

4. Open the Xcode project:

```bash
open RTDink/OSX/RTDink.xcodeproj
```

5. Select the **Release** configuration and build (`⌘B`).

> **Note:** The SDL2 frameworks are automatically embedded into the `.app` bundle at build time, so the final app is self-contained and does not require SDL2 to be installed on the target machine.

---

## Linux

### Install via Flatpak (recommended for most users)

No build required. Use the correct bundle for your CPU:

- **x86_64 (Intel/AMD):** [DinkSmallwoodHD-x86_64.flatpak](https://www.rtsoft.com/dink/DinkSmallwoodHD-x86_64.flatpak)
- **aarch64 (ARM 64-bit, e.g. Raspberry Pi 4, Jetson, Apple Silicon in Linux):** [DinkSmallwoodHD-aarch64.flatpak](https://www.rtsoft.com/dink/DinkSmallwoodHD-aarch64.flatpak)

```sh
# Install Flatpak if needed (Debian/Ubuntu)
sudo apt install flatpak

# Download and install (example for x86_64)
wget https://www.rtsoft.com/dink/DinkSmallwoodHD-x86_64.flatpak
flatpak install --user DinkSmallwoodHD-x86_64.flatpak

# Run
flatpak run com.rtsoft.DinkSmallwoodHD
```

On ARM, use `DinkSmallwoodHD-aarch64.flatpak` instead.

### Build from source

#### Quick setup (Ubuntu/Debian)

The easiest way is to use the automated script from the repo root:

```sh
./linux_setup.sh
```

This installs dependencies, clones the Proton SDK, and builds RTDink. Game data is included in the repo.

#### Manual build

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

# 2. Configure and build
mkdir build && cd build
cmake ..
make -j$(nproc)

# 3. Run (game data is in the repo under bin/dink)
./RTDinkApp
```

CMake automatically creates symlinks for `interface/`, `audio/`, and `dink/` so the binary finds resources when run from `build/`.

### Troubleshooting

- **Missing dependencies:** Install any missing `-dev` packages as reported by CMake.
- **No game data:** The `dink/` game data is included in the repo (under `bin/dink/`). If it is missing, the game will crash when starting a new game.

---

## Notes

- The Linux CMake build is independent from the Windows/macOS project files -- they can coexist safely.
- The Linux build uses SDL2 + SDL2_mixer for audio instead of FMOD (no proprietary dependencies).
- Proton SDK must be obtained separately on each platform.
- Contributions and bug reports are welcome!
