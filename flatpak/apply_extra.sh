#!/bin/bash
# Extract game data from the Windows installer (NSIS format)
# This runs during Flatpak install after extra-data is downloaded

7z x -y dink_installer.exe -oextracted >/dev/null 2>&1 || true

# Find the dink directory in the extracted files
EXTRACT_ROOT=""
if [ -d "extracted/dink" ]; then
    EXTRACT_ROOT="extracted"
elif [ -d 'extracted/$INSTDIR/dink' ]; then
    EXTRACT_ROOT='extracted/$INSTDIR'
else
    DINK_DAT=$(find extracted -name "dink.dat" -type f 2>/dev/null | head -1)
    if [ -n "$DINK_DAT" ]; then
        EXTRACT_ROOT=$(dirname "$(dirname "$DINK_DAT")")
    fi
fi

if [ -n "$EXTRACT_ROOT" ] && [ -d "$EXTRACT_ROOT/dink" ]; then
    mv "$EXTRACT_ROOT/dink" .
else
    echo "ERROR: Could not find game data in installer"
    exit 1
fi

# Clean up
rm -rf extracted dink_installer.exe
