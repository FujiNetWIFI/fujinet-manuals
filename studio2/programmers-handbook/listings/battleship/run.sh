#!/usr/bin/env bash
# run.sh -- Battleship for the RCA Studio II in MAME, against a live fujinet-pc.
#
#   ./run.sh                  a window; play with the keypads
#   ./run.sh shot             headless, emu/shot.lua (make demo first)
#   ./run.sh bsdrive          headless, emu/bsdrive.lua: a whole game
#
# MAME is the single-driver build with the FujiNet cart grafted in by the
# firmware tree's pico/studio2/emu/apply.sh (default ~/Workspace/mame-studio2,
# binary ./studio2); it must run from its own tree or -autoboot_script is
# ignored. fujinet-pc must be serving BoIP on $FUJINET_TCP (default
# 127.0.0.1:9995, ~/Workspace/fnpc-studio2), and only one MAME may talk to it
# at a time. The harnesses load the firmware tree's emu/s2screen.lua.
set -euo pipefail
cd "$(dirname "$0")"
HERE="$PWD"

FUJI_FIRMWARE="${FUJI_FIRMWARE:-$HOME/Workspace/fujinet-firmware}"
MAME="${MAME:-$HOME/Workspace/mame-studio2}"
BIN="${MAMEBIN:-./studio2}"
ROMS="${ROMS:-$HOME/Workspace/mame/roms}"
SCRIPT="${1:-}"

[ -x "$MAME/$BIN" ] || { echo "run.sh: no $BIN in $MAME" >&2; exit 1; }
[ -f build/battleship.st2 ] || ./build.sh

export S2_EMU_DIR="$FUJI_FIRMWARE/pico/studio2/emu"
export BS_SNAP_DIR="$HERE/build/snap"
export FUJINET=1
export FUJINET_TCP="${FUJINET_TCP:-127.0.0.1:9995}"
export FUJINET_BOOT="$HERE/build/battleship.st2"
mkdir -p build/snap build/nvram build/cfg
args=(studio2 -rompath "$ROMS" -snapshot_directory "$HERE/build/snap"
      -nvram_directory "$HERE/build/nvram" -cfg_directory "$HERE/build/cfg" -skip_gameinfo)

if [ -n "$SCRIPT" ]; then
    export SDL_VIDEODRIVER="${SDL_VIDEODRIVER:-dummy}"
    args+=(-autoboot_script "$HERE/emu/$SCRIPT.lua"
           -video none -sound none -nothrottle -seconds_to_run "${SECS:-120}")
else
    args+=(-window -nomax)
fi

cd "$MAME"
exec "$BIN" "${args[@]}"
