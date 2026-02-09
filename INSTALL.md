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
  libpng-dev libjpeg-dev zlib1g-dev libbz2-dev libcurl4-openssl-dev libsdl2-dev
```

- **FMOD Studio API** (proprietary, not included — see below)
- **Proton SDK** (cloned automatically — see below)

### FMOD Setup

FMOD is a proprietary audio library and is **not included** in this repository.

1. Download the FMOD Studio API for Linux from [fmod.com/download](https://www.fmod.com/download)
2. Extract and rename the directory to `fmodstudio` in the project root:
   ```sh
   # Example: if you downloaded fmodstudioapi20312linux.tar.gz
   tar xzf fmodstudioapi20312linux.tar.gz
   mv fmodstudioapi20312linux fmodstudio
   ```
3. Verify the headers exist: `fmodstudio/api/core/inc/fmod.hpp`

### Build Steps

```sh
# 1. Clone Proton SDK inside the project
git clone https://github.com/SethRobinson/proton.git

# 2. Fix case-sensitivity issue (Linux only — Proton has a capital 'Addons' include)
ln -s addons proton/shared/Addons

# 3. Configure and build
mkdir build && cd build
cmake ..
make -j$(nproc)

# 4. Run
export LD_LIBRARY_PATH=../fmodstudio/api/core/lib/x86_64:$LD_LIBRARY_PATH
./RTDinkApp
```

### Troubleshooting

- **FMOD not found at runtime:**
  ```sh
  export LD_LIBRARY_PATH=/path/to/fmodstudio/api/core/lib/x86_64:$LD_LIBRARY_PATH
  ```

- **Missing dependencies:**
  Install any missing `-dev` packages as reported by CMake.

- **Other issues:**
  Please open an issue on [GitHub](https://github.com/mateusbentes/RTDink/issues).

---

## Notes

- The Linux CMake build is independent from the Windows/macOS project files — they can coexist safely.
- Proton SDK is gitignored and must be obtained separately on each platform.
- FMOD SDK is gitignored and must be downloaded from fmod.com.
- Contributions and bug reports are welcome!
