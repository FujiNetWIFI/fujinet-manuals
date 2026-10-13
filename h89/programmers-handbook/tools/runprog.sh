#!/usr/bin/env bash
# Run one of the book's programs on the headless H89 against the rig, and
# keep everything it did: the screen (text and picture), the frames on the
# bus (tap.jsonl), and fujinet-pc's log.
#
#   tools/runprog.sh NAME OS UNTIL COMMAND [FILE...] [-- EXTRA STEPS...]
#
#   NAME     the run's name: build/runs/<NAME>/
#   OS       hdos | cpm | cpm64
#   UNTIL    text the screen must show when the program is done
#   COMMAND  what to type, e.g. "RUN SY1:FNHELLO.ABS" or "B:FNHELLO"
#   FILE     files for the data disk (SY1: / B:); for CP/M the first is a .COM
#   EXTRA    more h89_session_run steps after UNTIL (typing, waits, --screen)
#
# Copyright (C) 2026 Thomas Cherryhomes
# SPDX-License-Identifier: GPL-3.0-or-later
set -uo pipefail
source "$(dirname "$0")/rig.sh"
name="$1" os="$2" until="$3" cmd="$4"; shift 4
files=() extra=()
while [[ $# -gt 0 && "$1" != "--" ]]; do files+=("$1"); shift; done
[[ $# -gt 0 ]] && { shift; extra=("$@"); }

# one run at a time: the emulated card always dials 127.0.0.1:11512, and the
# helper servers have fixed ports, so runs started together wait their turn
exec 9>"$BOOK/build/.rig.lock"
flock 9

RD="$BOOK/build/runs/$name"; rm -rf "$RD"; mkdir -p "$RD"
case "$os" in
  hdos)  hdosdisk "$RD/data.h8d" "BOOK PROGRAMS" "${files[@]}"
         cp "$BOOK/build/disks/hdos-fn.h8d" "$RD/boot.h8d"
         mapfile -t BOOT < <(hdos_boot_steps)
         PRE=(--type 'MOUNT SY1:\r' --wait 2000 --prompt '>')
         TYPE=(--type "$cmd"'\r')
         PROMPT='>' ;;
  cpm|cpm64)
         cpmdisk "$RD/data.h8d" "${files[@]}"
         if [[ $os == cpm ]]; then cp "$BOOK/build/disks/cpm62.h8d" "$RD/boot.h8d"
         else cp "$BOOK/build/disks/cpm64.h8d" "$RD/boot.h8d"; fi
         mapfile -t BOOT < <(cpm_boot_steps)
         PRE=()
         mapfile -t TYPE < <(slow "$cmd"); TYPE+=(--type '\r')
         PROMPT='A>' ;;
  *) echo "runprog: OS is hdos, cpm or cpm64" >&2; exit 2 ;;
esac

rig_start "$RD"
emu "$RD" --timeout "${RUN_TIMEOUT:-120}" --disk "h17:1=$RD/boot.h8d" --disk "h17:2=$RD/data.h8d" \
    "${BOOT[@]}" "${PRE[@]}" "${TYPE[@]}" --until "$until" --wait "${RUN_SETTLE:-800}" \
    "${extra[@]}" --screen --ppm "$RD/screen.ppm" > "$RD/emu.log" 2>&1
rc=$?
rig_stop
screen_of "$RD/emu.log" > "$RD/screen.txt"
cells "$RD/screen.ppm" "$RD/screen.json" 2>/dev/null
[[ $rc -ne 0 ]] && { echo "runprog $name: FAILED (rc $rc)"; grep -a "timed out" "$RD/emu.log" | head -3; tail -15 "$RD/screen.txt"; exit 1; }
echo "runprog $name: ok ($(grep -c '"hex"' "$RD/tap.jsonl") frames)"
