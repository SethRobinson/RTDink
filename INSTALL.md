# RTDink – Linux Build Instructions

## Prerequisites

- **C++ Compiler:** GCC 7+ or Clang 7+
- **CMake:** 3.10 or newer
- **Development Libraries:**
  - OpenGL (`libgl1-mesa-dev`)
  - X11 (`libx11-dev`)
  - PNG (`libpng-dev`)
  - JPEG (`libjpeg-dev`)
  - zlib (`zlib1g-dev`)
  - pthreads (usually included)
  - libcurl (`libcurl4-openssl-dev`)
  - FMOD Studio API (see below)

### FMOD Notes

- **FMOD is a proprietary audio library.**
- Download the FMOD Studio API for Linux from [FMOD Downloads](https://www.fmod.com/download).
- Extract the archive (e.g., to `~/fmodstudioapi20312linux`).
- You will need the `inc/` (headers) and `lib/` (libraries) directories from the FMOD package.
- If you install FMOD somewhere non-standard, set `PKG_CONFIG_PATH` and/or `LD_LIBRARY_PATH` as needed.

## Build Steps

1. **Install dependencies (Ubuntu/Debian):**
   ```sh
   sudo apt update
   sudo apt install build-essential cmake libgl1-mesa-dev libx11-dev libpng-dev libjpeg-dev zlib1g-dev libcurl4-openssl-dev
   ```
   - FMOD: Download and extract as described above.

2. **Configure the build:**
   ```sh
   mkdir build
   cd build
   cmake .. -DFMOD_ROOT_DIR=/path/to/fmodstudioapi20312linux/api/core
   ```

3. **Build:**
   ```sh
   make -j$(nproc)
   ```

4. **Run:**
   ```sh
   ./RTDinkApp
   ```

## Troubleshooting

- **FMOD not found:**  
  Make sure `libfmod.so` is in your library path and `pkg-config` can find it.  
  You may need to set:
  ```sh
  export PKG_CONFIG_PATH=/path/to/fmodstudioapi20312linux/api/core/lib/pkgconfig:$PKG_CONFIG_PATH
  export LD_LIBRARY_PATH=/path/to/fmodstudioapi20312linux/api/core/lib/x86_64:$LD_LIBRARY_PATH
  ```

- **Missing dependencies:**  
  Install any missing `-dev` packages as reported by CMake.

- **Other issues:**  
  Please open an issue on [GitHub](https://github.com/SethRobinson/RTDink/issues).

---

## Notes

- This build is for Linux desktop (x86_64). For other platforms, see platform-specific folders.
- Contributions and bug reports are welcome!
