#!/bin/bash
#
# Dink Smallwood HD - Linux Build & Setup Script
#
# This script will:
#   1. Clone RTDink (if not already in the repo)
#   2. Install required dependencies (auto-detects package manager)
#   3. Clone the Proton SDK
#   4. Build RTDink
#   5. Download game data and compiled assets from the Windows release
#   6. Assemble everything into bin/ ready to play
#
# Supported distros: Debian/Ubuntu, Fedora/RHEL, Arch/Manjaro, openSUSE, Alpine
#
# One-liner install:
#   curl -sL https://raw.githubusercontent.com/SethRobinson/RTDink/master/linux_setup.sh | bash
#
# Or from within the repo:
#   ./linux_setup.sh            # full setup (build + game data)
#   ./linux_setup.sh --no-data  # build only, skip game data download
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# ---------------------------------------------------------------------------
# Detect package manager
# ---------------------------------------------------------------------------
detect_pkg_manager() {
    if command -v apt-get >/dev/null 2>&1; then
        PKG_MANAGER="apt"
    elif command -v dnf >/dev/null 2>&1; then
        PKG_MANAGER="dnf"
    elif command -v yum >/dev/null 2>&1; then
        PKG_MANAGER="yum"
    elif command -v pacman >/dev/null 2>&1; then
        PKG_MANAGER="pacman"
    elif command -v zypper >/dev/null 2>&1; then
        PKG_MANAGER="zypper"
    elif command -v apk >/dev/null 2>&1; then
        PKG_MANAGER="apk"
    else
        PKG_MANAGER=""
    fi
}

# Install packages using the detected package manager
# Usage: pkg_install pkg1 pkg2 ...
pkg_install() {
    case "$PKG_MANAGER" in
        apt)
            sudo apt-get update
            sudo apt-get install -y "$@"
            ;;
        dnf)
            sudo dnf install -y "$@"
            ;;
        yum)
            sudo yum install -y "$@"
            ;;
        pacman)
            sudo pacman -S --needed --noconfirm "$@"
            ;;
        zypper)
            sudo zypper install -y "$@"
            ;;
        apk)
            sudo apk add "$@"
            ;;
        *)
            error "No supported package manager found (tried apt, dnf, yum, pacman, zypper, apk)."
            error "Please install the following packages manually, then re-run with --no-data or after installing deps:"
            error "  C/C++ compiler, cmake, OpenGL dev libs, X11 dev libs, libpng, zlib, bzip2,"
            error "  libcurl, SDL2, SDL2_mixer, 7zip/p7zip"
            exit 1
            ;;
    esac
}

# Return the list of packages needed for this distro's package manager
get_build_packages() {
    case "$PKG_MANAGER" in
        apt)
            echo "build-essential cmake libgl1-mesa-dev libx11-dev libpng-dev zlib1g-dev libbz2-dev libcurl4-openssl-dev libsdl2-dev libsdl2-mixer-dev"
            ;;
        dnf|yum)
            echo "gcc gcc-c++ make cmake mesa-libGL-devel libX11-devel libpng-devel zlib-devel bzip2-devel libcurl-devel SDL2-devel SDL2_mixer-devel"
            ;;
        pacman)
            echo "base-devel cmake mesa libx11 libpng zlib bzip2 curl sdl2 sdl2_mixer"
            ;;
        zypper)
            echo "gcc gcc-c++ make cmake Mesa-libGL-devel libX11-devel libpng16-devel zlib-devel libbz2-devel libcurl-devel libSDL2-devel libSDL2_mixer-devel"
            ;;
        apk)
            echo "build-base cmake mesa-dev libx11-dev libpng-dev zlib-dev bzip2-dev curl-dev sdl2-dev sdl2_mixer-dev"
            ;;
    esac
}

# Return the 7zip package name for this distro
get_7zip_package() {
    case "$PKG_MANAGER" in
        apt)     echo "p7zip-full" ;;
        dnf|yum) echo "p7zip p7zip-plugins" ;;
        pacman)  echo "p7zip" ;;
        zypper)  echo "p7zip-full" ;;
        apk)     echo "7zip" ;;
    esac
}

# Return the git package name (always "git" but keeps the pattern consistent)
get_git_package() {
    echo "git"
}

detect_pkg_manager

# ---------------------------------------------------------------------------
# Parse arguments
# ---------------------------------------------------------------------------
SKIP_DATA=false
INSTALL_DIR="$HOME/RTDink"
for arg in "$@"; do
    case $arg in
        --no-data) SKIP_DATA=true ;;
        --dir=*) INSTALL_DIR="${arg#*=}" ;;
        --help|-h)
            echo "Usage: $0 [--no-data] [--dir=PATH]"
            echo "  --no-data    Skip downloading game data (build only)"
            echo "  --dir=PATH   Install directory (default: ~/RTDink)"
            echo ""
            echo "One-liner install:"
            echo "  curl -sL https://raw.githubusercontent.com/SethRobinson/RTDink/master/linux_setup.sh | bash"
            exit 0
            ;;
    esac
done

# ---------------------------------------------------------------------------
# Bootstrap: if we're not inside the RTDink repo, clone it and re-run
# ---------------------------------------------------------------------------
if [ ! -f "CMakeLists.txt" ] || [ ! -d "source" ]; then
    info "RTDink repo not detected in current directory."

    # Make sure git is available
    if ! command -v git >/dev/null 2>&1; then
        info "Installing git..."
        pkg_install $(get_git_package)
    fi

    if [ -d "$INSTALL_DIR/.git" ]; then
        info "RTDink already cloned at $INSTALL_DIR, pulling latest..."
        cd "$INSTALL_DIR"
        git pull || warn "git pull failed (local changes or network issue?), continuing with existing files..."
    elif [ -d "$INSTALL_DIR" ] && [ -n "$(ls -A "$INSTALL_DIR" 2>/dev/null)" ]; then
        # Directory exists and is not empty, but has no .git
        if [ -f "$INSTALL_DIR/CMakeLists.txt" ] && [ -d "$INSTALL_DIR/source" ]; then
            warn "Directory $INSTALL_DIR contains RTDink files but no .git directory."
            warn "Proceeding with existing files (no git pull possible)..."
            cd "$INSTALL_DIR"
        else
            error "Directory $INSTALL_DIR already exists and is not empty,"
            error "but does not appear to be an RTDink checkout."
            error "Please remove it or choose a different directory with --dir=PATH"
            exit 1
        fi
    else
        info "Cloning RTDink into $INSTALL_DIR ..."
        git clone https://github.com/SethRobinson/RTDink.git "$INSTALL_DIR"
        cd "$INSTALL_DIR"
    fi

    # Re-run this script from inside the repo, passing along all arguments
    exec bash "./linux_setup.sh" "$@"
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Offer to pull latest RTDink changes when running from inside an existing checkout
if [ -d ".git" ]; then
    if [ -t 0 ]; then
        # Interactive terminal — ask the user
        echo -en "${GREEN}[INFO]${NC} Git repo detected. Pull latest RTDink changes before building? [y/N] "
        read -r answer
        if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
            git pull || warn "git pull failed (local changes or network issue?), continuing with existing files..."
        else
            info "Skipping git pull, building with existing files."
        fi
    else
        info "Non-interactive mode — skipping git pull for local checkout."
    fi
fi

BIN_DIR="$SCRIPT_DIR/bin"

# ---------------------------------------------------------------------------
# Step 1: Install dependencies
# ---------------------------------------------------------------------------
info "Step 1: Checking dependencies..."
info "Detected package manager: $PKG_MANAGER"

BUILD_PACKAGES=$(get_build_packages)

if [ -z "$BUILD_PACKAGES" ]; then
    error "Could not determine packages for your system."
    error "Please install build dependencies manually (C/C++ toolchain, cmake, SDL2, SDL2_mixer, OpenGL, X11, libpng, zlib, bzip2, libcurl)."
    exit 1
fi

info "Installing build dependencies..."
pkg_install $BUILD_PACKAGES

# For game data extraction (optional, only needed if downloading game data)
if [ "$SKIP_DATA" = false ] && ! command -v 7z >/dev/null 2>&1; then
    info "Installing 7zip (needed to extract game data from Windows installer)..."
    pkg_install $(get_7zip_package)
fi

# ---------------------------------------------------------------------------
# Step 2: Clone Proton SDK
# ---------------------------------------------------------------------------
info "Step 2: Setting up Proton SDK..."

if [ -d "proton/.git" ]; then
    info "Proton SDK already cloned, pulling latest..."
    (cd proton && git pull) || warn "Proton git pull failed (local changes or network issue?), continuing with existing files..."
else
    info "Cloning Proton SDK..."
    git clone https://github.com/SethRobinson/proton.git
fi

# Fix case-sensitivity: Proton code includes "Addons" but directory is "addons"
if [ ! -e "proton/shared/Addons" ]; then
    info "Creating Addons symlink (case-sensitivity fix)..."
    ln -s addons proton/shared/Addons
fi

# ---------------------------------------------------------------------------
# Step 3: Build
# ---------------------------------------------------------------------------
info "Step 3: Building RTDink..."

mkdir -p build
cd build
cmake ..
make -j$(nproc)
cd ..

info "Build complete!"

# ---------------------------------------------------------------------------
# Step 4: Assemble bin/ directory
# ---------------------------------------------------------------------------
info "Step 4: Setting up bin/ directory..."

mkdir -p "$BIN_DIR"

# Copy the binary
cp build/RTDinkApp "$BIN_DIR/"

# ---------------------------------------------------------------------------
# Step 5: Download game data and compiled assets
# ---------------------------------------------------------------------------
if [ "$SKIP_DATA" = true ]; then
    info "Skipping game data download (--no-data flag)."
    echo ""
    info "To play, you need the dink/, interface/, and audio/ directories in: $BIN_DIR/"
    info "You can extract them from the Windows installer at: https://www.rtsoft.com/pages/dink.php"
    echo ""
    info "Then run:  cd $BIN_DIR && ./RTDinkApp"
    exit 0
fi

if [ -d "$BIN_DIR/dink" ] && [ -f "$BIN_DIR/dink/dink.dat" ]; then
    info "Game data already present in bin/dink/ directory."
else
    info "Step 5: Downloading Dink Smallwood HD game data and compiled assets..."

    INSTALLER_URL="https://www.rtsoft.com/dink/DinkSmallwoodHDInstaller.exe"
    TEMP_DIR=$(mktemp -d)

    if command -v wget >/dev/null 2>&1; then
        DOWNLOAD_CMD="wget -q --show-progress -O"
    elif command -v curl >/dev/null 2>&1; then
        DOWNLOAD_CMD="curl -L -o"
    else
        error "Neither wget nor curl found. Please install one and re-run."
        exit 1
    fi

    info "Downloading from $INSTALLER_URL ..."
    if $DOWNLOAD_CMD "$TEMP_DIR/dink_installer.exe" "$INSTALLER_URL"; then
        info "Extracting installer..."
        cd "$TEMP_DIR"
        7z x -y dink_installer.exe -oextracted >/dev/null 2>&1 || true
        cd "$SCRIPT_DIR"

        # Find the extracted root (NSIS extracts to $INSTDIR or directly)
        EXTRACT_ROOT=""
        if [ -d "$TEMP_DIR/extracted/dink" ]; then
            EXTRACT_ROOT="$TEMP_DIR/extracted"
        elif [ -d "$TEMP_DIR/extracted/\$INSTDIR/dink" ]; then
            EXTRACT_ROOT="$TEMP_DIR/extracted/\$INSTDIR"
        else
            # Search for dink.dat to find the root
            DINK_DAT=$(find "$TEMP_DIR/extracted" -name "dink.dat" -type f 2>/dev/null | head -1)
            if [ -n "$DINK_DAT" ]; then
                EXTRACT_ROOT=$(dirname "$(dirname "$DINK_DAT")")
            fi
        fi

        if [ -n "$EXTRACT_ROOT" ] && [ -d "$EXTRACT_ROOT/dink" ]; then
            # Copy game data and compiled assets directly into bin/
            for dir in dink interface audio; do
                if [ -d "$EXTRACT_ROOT/$dir" ]; then
                    info "Copying $dir/ to bin/..."
                    rm -rf "$BIN_DIR/$dir"
                    cp -r "$EXTRACT_ROOT/$dir" "$BIN_DIR/$dir"
                fi
            done
            info "Game data and assets installed successfully!"
        else
            warn "Could not locate game data in the downloaded installer."
            warn "The installer was saved to: $TEMP_DIR/dink_installer.exe"
            warn "Extract the dink/, interface/, and audio/ folders into: $BIN_DIR/"
        fi

        # Clean up temp files (but not if we failed to find data)
        if [ -d "$BIN_DIR/dink" ] && [ -f "$BIN_DIR/dink/dink.dat" ]; then
            rm -rf "$TEMP_DIR"
        fi
    else
        warn "Download failed. You can manually download the game data from:"
        warn "  https://www.rtsoft.com/pages/dink.php"
        warn "Extract the dink/, interface/, and audio/ folders into: $BIN_DIR/"
        rm -rf "$TEMP_DIR"
    fi
fi

# ---------------------------------------------------------------------------
# Done!
# ---------------------------------------------------------------------------
echo ""
if [ -d "$BIN_DIR/dink" ] && [ -f "$BIN_DIR/dink/dink.dat" ]; then
    info "Setup complete! Dink Smallwood HD is ready to play."
    echo ""
    echo "    cd $BIN_DIR && ./RTDinkApp"
    echo ""
else
    info "Build complete, but game data is missing."
    info "Download from https://www.rtsoft.com/pages/dink.php"
    info "Extract the dink/, interface/, and audio/ folders into: $BIN_DIR/"
    info "Then run:  cd $BIN_DIR && ./RTDinkApp"
fi
