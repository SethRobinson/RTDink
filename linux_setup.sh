#!/bin/bash
#
# Dink Smallwood HD - Linux Build & Setup Script
#
# This script will:
#   1. Clone RTDink (if not already in the repo)
#   2. Install required dependencies (apt-based distros)
#   3. Clone the Proton SDK
#   4. Build RTDink
#   5. Optionally download and extract the Dink Smallwood game data
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
# Parse arguments
# ---------------------------------------------------------------------------
SKIP_DATA=false
INSTALL_DIR="$HOME/DinkSmallwoodHD"
for arg in "$@"; do
    case $arg in
        --no-data) SKIP_DATA=true ;;
        --dir=*) INSTALL_DIR="${arg#*=}" ;;
        --help|-h)
            echo "Usage: $0 [--no-data] [--dir=PATH]"
            echo "  --no-data    Skip downloading game data (build only)"
            echo "  --dir=PATH   Install directory (default: ~/DinkSmallwoodHD)"
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
    info "Cloning RTDink into $INSTALL_DIR ..."

    # Make sure git is available
    if ! command -v git >/dev/null 2>&1; then
        info "Installing git..."
        sudo apt update && sudo apt install -y git
    fi

    if [ -d "$INSTALL_DIR/.git" ]; then
        info "RTDink already cloned at $INSTALL_DIR, pulling latest..."
        cd "$INSTALL_DIR"
        git pull
    else
        git clone https://github.com/SethRobinson/RTDink.git "$INSTALL_DIR"
        cd "$INSTALL_DIR"
    fi

    # Re-run this script from inside the repo, passing along all arguments
    exec bash "./linux_setup.sh" "$@"
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# ---------------------------------------------------------------------------
# Step 1: Install dependencies
# ---------------------------------------------------------------------------
info "Step 1: Checking dependencies..."

PACKAGES="build-essential cmake libgl1-mesa-dev libx11-dev libpng-dev zlib1g-dev libbz2-dev libcurl4-openssl-dev libsdl2-dev libsdl2-mixer-dev"

MISSING=""
for pkg in $PACKAGES; do
    if ! dpkg -s "$pkg" >/dev/null 2>&1; then
        MISSING="$MISSING $pkg"
    fi
done

if [ -n "$MISSING" ]; then
    info "Installing missing packages:$MISSING"
    sudo apt update
    sudo apt install -y $MISSING
else
    info "All dependencies already installed."
fi

# For game data extraction (optional, only needed if downloading game data)
if [ "$SKIP_DATA" = false ] && ! command -v 7z >/dev/null 2>&1; then
    info "Installing p7zip-full (needed to extract game data from Windows installer)..."
    sudo apt install -y p7zip-full
fi

# ---------------------------------------------------------------------------
# Step 2: Clone Proton SDK
# ---------------------------------------------------------------------------
info "Step 2: Setting up Proton SDK..."

if [ -d "proton/.git" ]; then
    info "Proton SDK already cloned, pulling latest..."
    cd proton && git pull && cd ..
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

info "Build complete! Binary is at build/RTDinkApp"

# ---------------------------------------------------------------------------
# Step 4: Game data
# ---------------------------------------------------------------------------
if [ "$SKIP_DATA" = true ]; then
    info "Skipping game data download (--no-data flag)."
    echo ""
    info "To play, you need to place the Dink Smallwood game data in the 'dink/' directory."
    info "You can get it from: https://www.rtsoft.com/pages/dink.php"
    echo ""
    info "Then run:  cd build && ./RTDinkApp"
    exit 0
fi

if [ -d "dink" ] && [ -f "dink/dink.dat" ]; then
    info "Game data already present in dink/ directory."
else
    info "Step 4: Downloading Dink Smallwood HD game data..."

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
        info "Extracting game data..."
        cd "$TEMP_DIR"
        7z x -y dink_installer.exe -odink_extracted >/dev/null 2>&1 || true
        cd "$SCRIPT_DIR"

        # Look for the dink/ game data directory in the extracted content
        DINK_DATA=""
        if [ -d "$TEMP_DIR/dink_extracted/dink" ]; then
            DINK_DATA="$TEMP_DIR/dink_extracted/dink"
        elif [ -d "$TEMP_DIR/dink_extracted/\$INSTDIR/dink" ]; then
            DINK_DATA="$TEMP_DIR/dink_extracted/\$INSTDIR/dink"
        else
            # Search for dink.dat anywhere in the extracted tree
            DINK_DAT=$(find "$TEMP_DIR/dink_extracted" -name "dink.dat" -type f 2>/dev/null | head -1)
            if [ -n "$DINK_DAT" ]; then
                DINK_DATA=$(dirname "$DINK_DAT")
            fi
        fi

        if [ -n "$DINK_DATA" ] && [ -d "$DINK_DATA" ]; then
            info "Found game data, copying to dink/ ..."
            cp -r "$DINK_DATA" "$SCRIPT_DIR/dink"
            info "Game data installed successfully!"
        else
            warn "Could not locate game data in the downloaded installer."
            warn "You may need to manually extract it. The installer was saved to: $TEMP_DIR/dink_installer.exe"
            warn "Extract the 'dink/' folder and place it in: $SCRIPT_DIR/dink/"
        fi

        # Clean up temp files (but not if we failed to find data)
        if [ -d "$SCRIPT_DIR/dink" ] && [ -f "$SCRIPT_DIR/dink/dink.dat" ]; then
            rm -rf "$TEMP_DIR"
        fi
    else
        warn "Download failed. You can manually download the game data from:"
        warn "  https://www.rtsoft.com/pages/dink.php"
        warn "Extract the 'dink/' folder and place it in: $SCRIPT_DIR/dink/"
        rm -rf "$TEMP_DIR"
    fi
fi

# ---------------------------------------------------------------------------
# Done!
# ---------------------------------------------------------------------------
echo ""
if [ -d "dink" ] && [ -f "dink/dink.dat" ]; then
    info "Setup complete! Dink Smallwood HD is ready to play."
    echo ""
    echo "    cd $SCRIPT_DIR/build && ./RTDinkApp"
    echo ""
else
    info "Build complete, but game data is missing."
    info "Download from https://www.rtsoft.com/pages/dink.php"
    info "Extract the 'dink/' folder to: $SCRIPT_DIR/dink/"
    info "Then run:  cd $SCRIPT_DIR/build && ./RTDinkApp"
fi
