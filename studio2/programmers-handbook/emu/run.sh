#!/usr/bin/env bash
# run.sh -- run a Studio II program in MAME's FujiNet cartridge model,
# against the bench's fujinet-pc.
#
#   emu/run.sh listings/asm/build/netget.st2            interactive
#   emu/run.sh listings/asm/build/netget.st2 screen     headless, checked
#
# The image is served from power-on as the cartridge would serve it after
# CONFIG booted it ($FUJINET_BOOT). fujinet-pc must be serving BoIP on
# $FUJINET_TCP (bench/up.sh); only one MAME may talk to it at a time.
# Snapshots go to $SNAP (default build/snap).
set -euo pipefail
BOOK=$(cd "$(dirname "$0")/.." && pwd)
. "$BOOK/bench/ports.env"

IMG=$(realpath "${1:?usage: run.sh image.st2 [script]}")
SCRIPT="${2:-}"
MAME="${MAME:-$HOME/Workspace/mame-studio2}"
BIN="${MAMEBIN:-./studio2-s2book}"
ROMS="${ROMS:-$HOME/Workspace/mame/roms}"
SNAP="${SNAP:-$BOOK/build/snap}"
[ -x "$MAME/$BIN" ] || { echo "run.sh: no $BIN in $MAME" >&2; exit 1; }

export S2_EMU_DIR="$BOOK/emu"
export FUJINET=1
export FUJINET_TCP="${FUJINET_TCP:-127.0.0.1:$BOIP_PORT}"   # never the 9995 default
export FUJINET_BOOT="$IMG"
mkdir -p "$SNAP" "$BOOK/build/mame/nvram" "$BOOK/build/mame/cfg"
args=(studio2 -rompath "$ROMS" -snapshot_directory "$SNAP"
      -nvram_directory "$BOOK/build/mame/nvram" -cfg_directory "$BOOK/build/mame/cfg"
      -skip_gameinfo)
if [ -n "$SCRIPT" ]; then
    # a bare name is one of the book's emu/ scripts; a path is any other
    case "$SCRIPT" in */*) LUA=$(realpath "$SCRIPT") ;; *) LUA="$BOOK/emu/$SCRIPT.lua" ;; esac
    args+=(-autoboot_script "$LUA" -video none -sound none
           -seconds_to_run "${SECS:-60}")
    [ -n "${THROTTLE:-}" ] || args+=(-nothrottle)
else
    args+=(-window -nomax)
fi
cd "$MAME"      # -autoboot_script needs MAME's own tree
exec "$BIN" "${args[@]}"
