# RTDink – Build Instructions

## Platform Overview

| Platform | Build System | Notes |
|----------|-------------|-------|
| **Windows** | Visual Studio 2017+ (`windows_vs2017/winRTDink.vcxproj`) | Expects Proton SDK at `../../shared` (sibling layout) |
| **macOS** | Xcode (`RTDink.xcodeproj`) | Expects Proton SDK at `../../shared` (sibling layout) |
| **Linux** | CMake (`CMakeLists.txt`) | Proton SDK cloned inside the project |

---

## Windows

The Visual Studio project is in `windows_vs2017/`. It expects the original Proton SDK layout where RTDink is cloned inside the Proton tree:

```
proton/
  shared/          ← Proton SDK
  RTDink/          ← this repo
    windows_vs2017/
      winRTDink.vcxproj
```

1. Clone [Proton SDK](https://github.com/SethRobinson/proton)
2. Clone this repo inside the Proton directory
3. Open `windows_vs2017/winRTDink.vcxproj` in Visual Studio
4. Build

---

## macOS

The Xcode project is at the repo root (`RTDink.xcodeproj`). Same sibling layout as Windows:

```
proton/
  shared/
  RTDink/
    RTDink.xcodeproj
```

1. Clone [Proton SDK](https://github.com/SethRobinson/proton)
2. Clone this repo inside the Proton directory
3. Open `RTDink.xcodeproj` in Xcode
4. Build

---

## Linux

### Prerequisites

- **C++ Compiler:** GCC 7+ or Clang 7+
- **CMake:** 3.10 or newer
- **Development Libraries:**

```sh
sudo apt update
sudo apt install build-essential cmake libgl1-mesa-dev libx11-dev \
  libpng-dev zlib1g-dev libbz2-dev libcurl4-openssl-dev libsdl2-dev libsdl2-mixer-dev
```

- **Proton SDK** (cloned separately — see below)

### Build Steps

```sh
# 1. Clone Proton SDK inside the project
git clone https://github.com/SethRobinson/proton.git

# 2. Fix case-sensitivity issue (Linux only — Proton has a capital 'Addons' include)
ln -s addons proton/shared/Addons

# 3. Apply patches to Proton SDK (adds missing Linux stubs)
cd proton
git apply ../patches/proton-linux-missing-stubs.patch
cd ..

# 4. Configure and build
mkdir build && cd build
cmake ..
make -j$(nproc)

# 5. Run
./RTDinkApp
```

### Game Data

RTDink requires the original **Dink Smallwood** game data to run. Place it in a `dink/` directory at the project root:

```
RTDink/
  dink/           ← game data goes here
    dink.ini
    map.dat
    dink.dat
    hard.dat
    story/
    tiles/
    graphics/
    sound/
  build/
  source/
  ...
```

You can obtain the game data from the free [Dink Smallwood HD](https://www.rtsoft.com/pages/dink.php) release. CMake will automatically symlink `dink/` into the build directory.

### Troubleshooting

- **Missing dependencies:**
  Install any missing `-dev` packages as reported by CMake.

- **Other issues:**
  Please open an issue on [GitHub](https://github.com/SethRobinson/RTDink/issues).

---

## Notes

- The Linux CMake build is independent from the Windows/macOS project files — they can coexist safely.
- The Linux build uses SDL2_mixer for audio instead of FMOD (no proprietary dependencies).
- Proton SDK is gitignored and must be obtained separately on each platform.
- Contributions and bug reports are welcome!
