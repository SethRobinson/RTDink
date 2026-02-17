#!/bin/bash
# Wrapper script for Dink Smallwood HD inside Flatpak sandbox
#
# The game expects dink/, interface/, audio/, and dmods/ directories
# next to the binary. This script sets up the data directory
# and launches the game from there.

DATA_DIR="$XDG_DATA_HOME/dink-smallwood-hd"
EXTRA_DATA="/app/extra"
APP_SHARE="/app/share/com.rtsoft.DinkSmallwoodHD"

# Create data directory and writable dmods directory
mkdir -p "$DATA_DIR"
mkdir -p "$DATA_DIR/dmods"

# Link game data from extra-data (downloaded installer)
if [ ! -f "$DATA_DIR/dink/dink.dat" ]; then
    if [ -d "$EXTRA_DATA/dink" ]; then
        ln -sf "$EXTRA_DATA/dink" "$DATA_DIR/dink"
    else
        echo "ERROR: Game data not found. Please reinstall the application."
        exit 1
    fi
fi

# Link interface and audio from the app bundle
if [ ! -e "$DATA_DIR/interface" ]; then
    ln -sf "$APP_SHARE/interface" "$DATA_DIR/interface"
fi

if [ ! -e "$DATA_DIR/audio" ]; then
    ln -sf "$APP_SHARE/audio" "$DATA_DIR/audio"
fi

# Link the binary
if [ ! -e "$DATA_DIR/RTDinkApp" ]; then
    ln -sf "/app/bin/RTDinkApp" "$DATA_DIR/RTDinkApp"
fi

cd "$DATA_DIR"
exec ./RTDinkApp "$@"
