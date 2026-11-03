#!/usr/bin/env bash
# run.sh -- run CONFIG (or any Arcadia image) from the FujiNet cartridge in
# MAME, against the owner's bench (emu/bench.sh up).
#
#   emu/run.sh                          CONFIG, in a window
#   SNAP=hosts STEPS=... emu/run.sh     CONFIG, headless, emu/walk.lua
#   IMG=game.bin SNAP=... emu/run.sh    another image
#
# CONFIG is the one baked into the firmware: build/src/config (emu/getsrc.sh)
# built from fujinet-config main, the same 8192 bytes as fujinet-firmware
# master's pico/arcadia/firmware/baked/fujiconfigrom.h. Snapshots go to
# build/snap/$SNAP. MAME is ~/Workspace/mame, with the FujiNet cart device.
set -euo pipefail
HERE=$(cd "$(dirname "$0")/.." && pwd)
. "$HERE/emu/ports.env"

IMG=$(realpath "${IMG:-$HERE/build/src/config/arcadia/build/config.bin}")
MAME="${MAME:-$HOME/Workspace/mame}"
export FUJINET_TCP="${FUJINET_TCP:-127.0.0.1:$BOIP_PORT}"
mkdir -p "$HERE/build/nvram" "$HERE/build/cfg"
args=(arcadia -cartslot fujinet -cart "$IMG" -skip_gameinfo
      -nvram_directory "$HERE/build/nvram" -cfg_directory "$HERE/build/cfg")
if [ -n "${SNAP:-}" ]; then
    rm -rf "$HERE/build/snap/$SNAP"
    mkdir -p "$HERE/build/snap/$SNAP"
    args+=(-snapshot_directory "$HERE/build/snap/$SNAP"
           -autoboot_script "$HERE/emu/walk.lua" -video none -sound none
           -seconds_to_run "${SECS:-150}")
    [ -n "${THROTTLE:-}" ] || args+=(-nothrottle)
else
    args+=(-window -nomax)
fi
cd "$MAME"
exec ./mame "${args[@]}"
