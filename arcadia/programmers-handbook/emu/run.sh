#!/usr/bin/env bash
# run.sh -- run an Arcadia image from the FujiNet cartridge in MAME, against
# the book's bench (bench/up.sh).
#
#   emu/run.sh image.bin                     in a window
#   SNAP=name STEPS=... WANT=... emu/run.sh image.bin
#                                            headless, walked by emu/walk.lua;
#                                            snapshots go to build/snap/name
#   LUA=script.lua emu/run.sh image.bin      headless, another script
#
# MAME is ~/Workspace/mame with the FujiNet cartridge device grafted in by
# fujinet-firmware's pico/arcadia/emu/apply.sh. THROTTLE=1 runs in real
# time (needed against live servers: unthrottled, a wait burns emulated
# seconds while the network has not answered yet).
set -euo pipefail
HERE=$(cd "$(dirname "$0")/.." && pwd)
. "$HERE/bench/ports.env"
IMG=$(realpath "${1:?usage: emu/run.sh image.bin}")
MAME="${MAME:-$HOME/Workspace/mame}"
export FUJINET_TCP="${FUJINET_TCP:-127.0.0.1:$BOIP_PORT}"
mkdir -p "$HERE/build/nvram" "$HERE/build/cfg"
args=(arcadia -cartslot fujinet -cart "$IMG" -skip_gameinfo
      -nvram_directory "$HERE/build/nvram" -cfg_directory "$HERE/build/cfg")
if [ -n "${SNAP:-}${LUA:-}" ]; then
    snap=$HERE/build/snap/${SNAP:-lua}
    rm -rf "$snap"; mkdir -p "$snap"
    args+=(-snapshot_directory "$snap" -autoboot_script "${LUA:-$HERE/emu/walk.lua}"
           -video none -sound none -seconds_to_run "${SECS:-150}")
    [ -n "${THROTTLE:-}" ] || args+=(-nothrottle)
else
    args+=(-window -nomax)
fi
cd "$MAME"
exec ./mame "${args[@]}"
