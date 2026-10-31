#!/usr/bin/env bash
# run.sh -- run a 5200 image from the FujiNet cartridge in MAME, against the
# book's fujinet-pc (bench/up.sh).
#
#   emu/run.sh listings/asm/build/hello.bin           interactive
#   emu/run.sh listings/c/build/hello.bin shot        headless, emu/shot.lua
#   SNAP=name emu/run.sh image.bin shot               snapshots to build/snap/name
#
# A claimed 32K image becomes the cartridge's boot image, as if CONFIG had
# booted it. The text harnesses read the screen at $1000 (the assembly
# programs) or $3C00 (the C ones); a C image (listings/c/...) picks $3C00.
# MAME is the single-driver build in $MAME (default ~/Workspace/mame-a5200);
# it must run from its own tree or -autoboot_script is ignored.
set -euo pipefail
HERE=$(cd "$(dirname "$0")/.." && pwd)
. "$HERE/bench/ports.env"

IMG=$(realpath "${1:?usage: run.sh image.bin [script]}")
SCRIPT="${2:-}"
MAME="${MAME:-$HOME/Workspace/mame-a5200}"
BIN="${MAMEBIN:-./a5200}"
ROMS="${ROMS:-$HOME/Workspace/mame/roms}"
SYSTEM="${SYSTEM:-a5200}"
SNAP="${SNAP:-$(basename "$IMG" .bin)}"

[ -x "$MAME/$BIN" ] || { echo "run.sh: no $BIN in $MAME" >&2; exit 1; }

export A52_EMU_DIR="$HERE/emu"
export FUJINET_TCP="${FUJINET_TCP:-127.0.0.1:$BOIP_PORT}"
case "$IMG" in
    */listings/c/*) export A52_SCREEN="${A52_SCREEN:-0x3C00}" ;;
esac
mkdir -p "$HERE/build/snap/$SNAP" "$HERE/build/nvram" "$HERE/build/cfg"
args=("$SYSTEM" -rompath "$ROMS" -cartslot fujinet -cart "$IMG"
      -snapshot_directory "$HERE/build/snap/$SNAP"
      -nvram_directory "$HERE/build/nvram" -cfg_directory "$HERE/build/cfg" -skip_gameinfo)
[ -n "${BIOS:-}" ] && args+=(-bios "$BIOS")

if [ -n "$SCRIPT" ]; then
    args+=(-autoboot_script "$HERE/emu/$SCRIPT.lua" -video none -sound none
           -seconds_to_run "${SECS:-120}")
    [ -n "${THROTTLE:-}" ] || args+=(-nothrottle)
else
    args+=(-window -nomax)
fi

cd "$MAME"
exec "$BIN" "${args[@]}"
