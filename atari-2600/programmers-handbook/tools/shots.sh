#!/usr/bin/env bash
# shots.sh -- a screenshot of every example program, from the FujiNet MAME.
#
#   tools/shots.sh [name ...]      default: every program in the table below
#
# Each program runs headless against the live fujinet-pc long enough for its
# transactions to finish, MAME snapshots the screen, and the PNG lands in
# images/screens/<kind>-<name>.png, scaled 3x with hard pixels for print.
set -euo pipefail
cd "$(dirname "$0")/.."
HERE=$(pwd)
mkdir -p images/screens build/snap
# name : image : frames-before-the-shot : extra env
TABLE="
asm-hello    listings/asm/build/hello.bin     120
asm-acfg     listings/asm/build/fujitest.bin  120
asm-netget   listings/asm/build/netget.bin    120
asm-dir      listings/asm/build/fujidir.bin   240
asm-boot     listings/asm/build/fujiboot.bin  60
asm-appkey   listings/asm/build/appkey.bin    120
asm-clock    listings/asm/build/clock.bin     120
bas-hello    listings/bas/build/hello.bin     120
bas-arm      listings/bas/build/arm.bin       120
bas-text     listings/bas/build/text.bin      240
bas-netget   listings/bas/build/netget.bin    400
bas-dir      listings/bas/build/dir.bin       600
bas-boot     listings/bas/build/boot.bin      90
bas-appkey   listings/bas/build/appkey.bin    400
bas-clock    listings/bas/build/clock.bin     300
"
want=("$@")
while read -r name img frames; do
    [ -z "$name" ] && continue
    if [ ${#want[@]} -gt 0 ]; then
        case " ${want[*]} " in *" $name "*) ;; *) continue;; esac
    fi
    [ -f "$img" ] || { echo "shots: $img missing, skipped"; continue; }
    rm -rf build/snap/a2600
    SNAP="$HERE/build/snap" SHOT_FRAMES=$frames FAST=1 SECS=60 emu/run.sh "$img" shot >/dev/null 2>&1 || true
    png=$(ls build/snap/a2600/*.png 2>/dev/null | head -1)
    if [ -z "$png" ]; then echo "shots: $name: no snapshot"; continue; fi
    python3 tools/pngscale.py "$png" "images/screens/$name.png" 3
    echo "shots: images/screens/$name.png"
done <<< "$TABLE"
