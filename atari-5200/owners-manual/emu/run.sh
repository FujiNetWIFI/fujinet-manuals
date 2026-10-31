#!/usr/bin/env bash
# run.sh -- run CONFIG (or any 5200 image) from the FujiNet cartridge in MAME,
# against the owner's bench (emu/bench.sh up).
#
#   emu/run.sh                          CONFIG, interactive
#   SNAP=hosts PRESS=... emu/run.sh     CONFIG, headless, emu/tour.lua
#   IMG=game.a52 SNAP=... emu/run.sh    another image
#
# The keys, the timetable and the screen check are the Programmer's
# Handbook's emu/drive.lua (PRESS, SHOT_AT, WANT); emu/tour.lua adds SWAP,
# the text it may put over the screen before the snapshot. Snapshots go to
# build/snap/$SNAP. MAME is the FujiNet single-driver build in $MAME.
set -euo pipefail
HERE=$(cd "$(dirname "$0")/.." && pwd)
. "$HERE/emu/ports.env"
HB=$(cd "$HERE/../programmers-handbook" && pwd)

IMG=$(realpath "${IMG:-$HOME/Workspace/a5book-fw/config/atari5200/build/config.bin}")
MAME="${MAME:-$HOME/Workspace/mame-a5200}"
BIN="${MAMEBIN:-./a5200}"
ROMS="${ROMS:-$HOME/Workspace/mame/roms}"
SYSTEM="${SYSTEM:-a5200}"

[ -x "$MAME/$BIN" ] || { echo "run.sh: no $BIN in $MAME" >&2; exit 1; }
export A52_EMU_DIR="$HB/emu"
export A52_SCREEN="${A52_SCREEN:-0x3C00}"
export FUJINET_TCP="${FUJINET_TCP:-127.0.0.1:$BOIP_PORT}"
mkdir -p "$HERE/build/nvram" "$HERE/build/cfg"
args=("$SYSTEM" -rompath "$ROMS" -cartslot fujinet -cart "$IMG"
      -nvram_directory "$HERE/build/nvram" -cfg_directory "$HERE/build/cfg" -skip_gameinfo)
if [ -n "${SNAP:-}" ]; then
    rm -rf "$HERE/build/snap/$SNAP"
    mkdir -p "$HERE/build/snap/$SNAP"
    args+=(-snapshot_directory "$HERE/build/snap/$SNAP"
           -autoboot_script "$HERE/emu/${SCRIPT:-tour}.lua" -video none -sound none
           -seconds_to_run "${SECS:-120}")
    [ -n "${THROTTLE:-}" ] || args+=(-nothrottle)
else
    args+=(-window -nomax)
fi
cd "$MAME"
exec "$BIN" "${args[@]}"
