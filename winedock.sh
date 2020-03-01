#!/bin/bash -e

# Create a symbolic link to this file from the $PATH and invoke as:
#   winedock.sh </path/to/local/steam/data/directory>
# or
#   winedock32.sh </path/to/local/steam/data/directory>
#
# set the environment variable STEAM_SKIP to
#   - "yes" to simply skip steam and execute local launch.rc scripts
#   - "shell" to skip steam and get a bash shell
#   - "cfg" to skip steam and run winecfg instead
#   - "wait" to skip steam and leave the container on stand-by

BINDIR=$(dirname "$(readlink -f "$0")")
export WINE_DATADIR="$1"
export STEAM_UID=$(id -ru)

case $(basename $0) in
    winedock32*)
        export WINE_BITS=32
        ;;
    *)
        export WINE_BITS=64
        ;;
esac

if [ -z "$WINE_DATADIR" -o ! -d "$WINE_DATADIR" ]; then
    echo "Usage: $(basename "$0") </path/to/local/steam/data/directory>"
    echo "ERROR: Missing or invalid steam directory path: \"$WINE_DATADIR\""
    exit 1
fi

echo "Launching Wine Steam Docker from: $BINDIR"
echo "- User: $STEAM_UID ($(id -un $STEAM_UID))"
echo "- Data: $WINE_DATADIR"
echo "- Bits: $WINE_BITS"

(cd $BINDIR && docker-compose --verbose up)

