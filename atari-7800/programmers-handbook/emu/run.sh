#!/usr/bin/env bash
# run.sh -- run a 7800 image in the FujiNet MAME cartridge model.
#
#   emu/run.sh build/asm/fujitest.a78            interactive
#   emu/run.sh build/asm/fujitest.a78 shot       headless, driven by emu/shot.lua
#   SYSTEM=a7800p emu/run.sh x.a78               a PAL console (default a7800, NTSC)
#   THROTTLE=1 emu/run.sh x.a78 script           headless, but in real time
#
# fujinet-pc must already be serving bus-over-IP on 127.0.0.1:9986 (the
# book's private copy; FUJINET_TCP overrides), and only one MAME may talk to
# it at a time. MAME is the single-driver build with the cart grafted in
# ($MAME, default ~/Workspace/mame-a7800, binary ./a7800); it must run from
# its own tree or -autoboot_script is ignored.
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
ROM="$(realpath "${1:?usage: run.sh image.a78 [script]}")"
SCRIPT="${2:-}"

MAME="${MAME:-$HOME/Workspace/mame-a7800}"
BIN="${MAMEBIN:-./a7800}"
ROMS="${ROMS:-$HOME/Workspace/mame/roms}"
SYSTEM="${SYSTEM:-a7800}"
SNAP="${SNAP:-$HERE/build/snap}"

[ -x "$MAME/$BIN" ] || { echo "run.sh: no $BIN in $MAME" >&2; exit 1; }
export A78_EMU_DIR="$HERE/emu"
export FUJINET_TCP="${FUJINET_TCP:-127.0.0.1:9986}"
[ -n "${IMAGE:-}" ] && export FUJINET_IMAGE="$IMAGE"
[ -n "${HSC:-}" ] && export FUJINET_HSC="$HSC"
[ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ] || export SDL_VIDEODRIVER=dummy
mkdir -p "$SNAP" "$HERE/build/nvram" "$HERE/build/cfg"

# one client per bus-over-IP listener: a stale MAME holds the port
pkill -f "^[.]/a7800 $SYSTEM .*-cart $HERE/" 2>/dev/null && sleep 1 || true

args=("$SYSTEM" -rompath "$ROMS" -cartslot fujinet -cart "$ROM"
      -snapshot_directory "$SNAP" -nvram_directory "$HERE/build/nvram"
      -cfg_directory "$HERE/build/cfg")
[ -n "${BIOS:-}" ] && args+=(-bios "$BIOS")
if [ -n "$SCRIPT" ]; then
    args+=(-autoboot_script "$HERE/emu/$SCRIPT.lua"
           -video none -sound none -seconds_to_run "${SECS:-120}")
    # a game server counts real seconds: THROTTLE=1 runs at the console's speed
    [ -n "${THROTTLE:-}" ] || args+=(-nothrottle)
else
    args+=(-window -nomax)
fi
cd "$MAME"
exec "$BIN" "${args[@]}"
