#!/usr/bin/env bash
# run.sh -- run one of this book's ROMs in the grafted MAME against a live
# fujinet-pc (BoIP on 127.0.0.1:9995), print the screen as text after SHOT_AT
# seconds and save a snapshot as images/screens/<name>.png.
#
#   emu/run.sh listings/build/c/hello.nes hello-c
#   SHOT_AT=8 KEYS="RIGHT A" emu/run.sh listings/build/netcat.nes netcat
#
# The cart device, nestext.lua and shot.lua come from the bring-up tree.
set -euo pipefail
ROM="$(realpath "$1")"; NAME="${2:-$(basename "$1" .nes)}"
HERE="$(cd "$(dirname "$0")/.." && pwd)"
MAME="${MAME:-$HOME/Workspace/mame}"
FN_NES="${FN_NES:-$HOME/Workspace/fn-nes/pico/nes}"
SNAP="$(mktemp -d)"
export NES_EMU_DIR="$FN_NES/emu" BOOK_EMU_DIR="$HERE/emu"
export SHOT_AT="${SHOT_AT:-5}"
SCRIPT="${SCRIPT:-$HERE/emu/shot.lua}"
cd "$MAME"
./mame nes -nes_slot fujinet -cart "$ROM" -snapshot_directory "$SNAP" \
    -autoboot_script "$SCRIPT" -video none -sound none -nothrottle \
    -seconds_to_run "${SECS:-120}" 2>&1 | sed '/^Average speed/d'
png="$(ls "$SNAP"/nes/*.png 2>/dev/null | tail -1 || true)"
if [ -n "$png" ]; then
    cp "$png" "$HERE/images/screens/$NAME.png"
    echo "snapshot: images/screens/$NAME.png"
fi
rm -rf "$SNAP"
