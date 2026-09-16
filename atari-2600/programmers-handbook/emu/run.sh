#!/usr/bin/env bash
# run.sh -- run a client image in the FujiNet-patched MAME.
#
#   emu/run.sh <image.bin> [lua-script]      (script = basename in emu/)
#
# With a script it runs headless and exits; without one it opens a window.
# The MAME tree must have had fn-2600/pico/atari-2600/emu/apply.sh run against
# it, and for anything that touches the network a fujinet-pc must be listening
# on BoIP 127.0.0.1:9995 -- which takes ONE client, so a stray MAME starves
# the next run and the symptom is a hang. Kill strays first.
#   - MAME must run FROM ITS OWN TREE or -autoboot_script is silently ignored.
#   - SDL_VIDEODRIVER=dummy is required wherever there is no DISPLAY.
#   - THROTTLED unless FAST=1: servers with wall-clock timers need real time.
set -euo pipefail
ROM=$(realpath "${1:?usage: run.sh image.bin [script]}")
cd "$(dirname "$0")"
HERE=$(pwd)
SCRIPT=${2:-}
MAME=${MAME:-$HOME/Workspace/mame}
SNAP=${SNAP:-$HERE/../build/snap}
mkdir -p "$SNAP"
pkill -f "^[.]/mame a2600" 2>/dev/null && sleep 1 || true   # anchored: never our own shell
sleep "${SETTLE:-1}"   # let fujinet-pc's one-client BoIP listener come back
args=(a2600 -cartslot "${SLOT:-fujinet}" -cart "$ROM" -snapshot_directory "$SNAP")
export A2600_EMU="$HERE"
export FN2600_EMU="${FN2600:-$HOME/Workspace/fn-2600/pico/atari-2600}/emu"
export DRIVE_EXPECT="${DRIVE_EXPECT:-$HERE/../build/expect.txt}"
if [ -n "$SCRIPT" ]; then
    args+=(-autoboot_script "$HERE/$SCRIPT.lua" -video none -sound none
           -seconds_to_run "${SECS:-10}")
    [ -n "${FAST:-}" ] && args+=(-nothrottle)
fi
[ -n "${DISPLAY:-}" ] || export SDL_VIDEODRIVER=dummy
export FUJINET_TCP="${FUJINET_TCP:-127.0.0.1:9995}"
cd "$MAME"
exec ./mame "${args[@]}"
