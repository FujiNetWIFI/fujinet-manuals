#!/usr/bin/env bash
# How much memory does HDOS need for the FujiNet? On a 48K H89, run CONFIG
# (a) before FN.DVD is loaded and (b) after LOAD FN:. The book's Specifications
# and Chapters 4 and 6 rest on the answer:
#   48K: (a) runs, (b) "?02 NOT ENOUGH RAM FOR THIS PROGRAM"
#   64K (HDOS says 56K): both run (fujinet-h89 tests/fn-hdos-e2e.sh)
set -uo pipefail
source "$(dirname "$0")/rig.sh"
try() {   # try NAME STEPS... -- run CONFIG after STEPS on a 48K machine
    local name="$1"; shift
    local W="$BOOK/build/work-48k-$name"; rm -rf "$W"; mkdir -p "$W/home/data/fujinet/SD"
    cp "$BOOK/tools/fnconfig-new.ini" "$W/home/data/fujinet/fnconfig.ini"
    hdosfs blank "$W/tools.h8d" --label "FujiNet for HDOS" >/dev/null
    hdosfs put "$W/tools.h8d" "$BOOK/build/rigcfg/r2r/h89-hdos/config.abs" --name CONFIG.ABS >/dev/null
    cp "$BOOK/build/disks/hdos-fn.h8d" "$W/boot.h8d"
    mapfile -t BOOT < <(hdos_boot_steps)
    "$RUN" --roms "$ROMS" --home "$W/home" --timeout 90 --set machine.memory=48 \
        --disk "h17:1=$W/boot.h8d" --disk "h17:2=$W/tools.h8d" "${BOOT[@]}" "$@" \
        --type 'MOUNT SY1:\r' --wait 2000 --prompt '>' \
        --type 'RUN SY1:CONFIG.ABS\r' --wait 30000 --screen > "$W/log" 2>&1 || true
    if screen_of "$W/log" | grep -aq "Quit"; then echo "$name: CONFIG runs"
    elif screen_of "$W/log" | grep -aq "NOT ENOUGH RAM"; then echo "$name: NOT ENOUGH RAM FOR THIS PROGRAM"
    else echo "$name: ?? see $W/log"; fi
}
try before-load
try after-load --type 'LOAD FN:\r' --wait 3000 --prompt '>'
