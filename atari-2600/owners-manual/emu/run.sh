#!/usr/bin/env bash
# run.sh -- run one cartridge image headless in the FujiNet-patched MAME,
# driven by a Lua harness, for the owner's manual screenshots.
#
#   emu/run.sh <image.bin> [harness]      harness = basename in emu/ (tour)
#
# Environment:
#   SNAP         snapshot directory (MAME adds a2600/ under it)
#   SECS         -seconds_to_run (default 30)
#   FAST=1       -nothrottle; ONLY for screens that wait on nothing -- anything
#                that talks to a server waits on wall clock
#   FUJINET_TCP  the BoIP endpoint (default 127.0.0.1:9995, the fujinet-pc that
#                is already running). 127.0.0.1:1 = no network: the cartridge
#                device still answers the mailbox but reports no link
#   PORT1/PORT2  controller in each port (default joy; pad = paddles)
#   TOUR         the step list tour.lua plays (see emu/tour.lua)
#
# Facts this wraps (each one cost somebody time):
#   - the ROM path is resolved BEFORE the cd into the MAME tree
#   - MAME must run FROM ITS OWN TREE or -autoboot_script is silently ignored
#   - SDL_VIDEODRIVER=dummy wherever there is no DISPLAY
#   - fujinet-pc's BoIP listener takes ONE client: a stray MAME starves the next
#     run. Only OUR strays are killed (anchored on ./mame, matched on this
#     manual's snapshot directory) so other 2600 sessions are left alone, and
#     the pattern can never match the shell running this script.
set -euo pipefail
ROM=$(realpath "${1:?usage: run.sh image.bin [harness]}")
HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/.." && pwd)
SCRIPT=${2:-tour}
MAME=${MAME:-$HOME/Workspace/mame}
SNAP=${SNAP:-$ROOT/build/snap}
FN2600=${FN2600:-$HOME/Workspace/fn-2600/pico/atari-2600}

pkill -f "^[.]/mame a2600 .*owners-manual/build" 2>/dev/null && sleep 1 || true
sleep "${SETTLE:-1}"              # let the one-client listener come back
mkdir -p "$SNAP" "$ROOT/build/mamecfg"

args=(a2600 -skip_gameinfo -cartslot "${SLOT:-fujinet}"
      -joyport1 "${PORT1:-joy}" -joyport2 "${PORT2:-joy}"
      -cart "$ROM" -snapshot_directory "$SNAP"
      -cfg_directory "$ROOT/build/mamecfg" -nvram_directory "$ROOT/build/mamecfg"
      -autoboot_script "$HERE/$SCRIPT.lua"
      -video none -sound none -seconds_to_run "${SECS:-30}")
[ -n "${FAST:-}" ] && args+=(-nothrottle)

export A2600_EMU="$HERE"
export A2600_FWEMU="$FN2600/emu"
export FUJINET_TCP="${FUJINET_TCP:-127.0.0.1:9995}"
[ -n "${DISPLAY:-}" ] || export SDL_VIDEODRIVER=dummy

cd "$MAME"
exec ./mame "${args[@]}"
