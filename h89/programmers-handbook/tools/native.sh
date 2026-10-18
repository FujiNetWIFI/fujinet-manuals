#!/usr/bin/env bash
# Chapter 5: the native programs, assembled ON the H89 by the assemblers that
# came with its systems -- Heath's ASM (HDOS 2.0 Software Tools, #104.06.00)
# and Digital Research's ASM 2.0 and LOAD (Heath CP/M 2.2.04) -- then run
# against the rig, and checked byte for byte against z88dk-z80asm -m8080.
#
#   tools/native.sh                  both: fnver fnverh
#   tools/native.sh fnverh fnver     some of them
#   tools/native.sh check            only the z80asm cross-check, on what
#                                    an earlier run left in build/native/
#
# Each program has one session on the headless H89, under the rig's lock:
# boot from the book's own boot disk (build/disks: hdos-fn.h8d / cpm62.h8d),
# assemble from a work disk in drive 2, keep the screen; run it, keep the
# screen. What it leaves:
#
#   screens/native-<name>-asm.json   the assembly (and LOAD), as typed
#   screens/native-<name>-run.json   the program's run
#   data/native/<NAME>.LST / .PRN    the assembler's listing, off the disk
#   data/native/timing.txt           emulated time each assembly took
#   data/native/xcheck.txt           the z80asm cross-check
#   build/native/<NAME>.ABS / .COM   the binaries (and .HEX), off the disk
#
# The work disks: for HDOS, a 100K data disk holding ASM.ABS, HOSDEF.ACM and
# ASCII.ACM from the Software Tools disk and the source as HDOS text (NL
# lines); for CP/M, one holding the source as CP/M text (CR LF, ^Z).
#
# Copyright (C) 2026 Thomas Cherryhomes
# SPDX-License-Identifier: GPL-3.0-or-later
set -uo pipefail
source "$(dirname "$0")/rig.sh"
NPY() { python3 "$BOOK/tools/native.py" "$@"; }
SRC="$BOOK/src/native" DATA="$BOOK/data/native" OUT="$BOOK/build/native"
WORK="$OUT/work"
mkdir -p "$DATA" "$OUT" "$WORK"
exec 9>"$BOOK/build/.rig.lock"

# ---- what goes on the work disks -------------------------------------------
TOOLS17="$G/tools/disks/images/HDOS_2_0_Software_Tools.h17disk"
hdosfs convert "$TOOLS17" "$WORK/tools.h8d" > /dev/null
for f in ASM.ABS HOSDEF.ACM ASCII.ACM; do hdosfs get "$WORK/tools.h8d" "$f" -o "$WORK/$f"; done

hdos_work() {   # OUT PROG -- the HDOS work disk
    NPY hdostext "$SRC/$2.ASM" "$WORK/$2.ASM"
    hdosdisk "$1" "NATIVE ASSEMBLY" "$WORK/ASM.ABS" "$WORK/HOSDEF.ACM" "$WORK/ASCII.ACM" "$WORK/$2.ASM"
}
cpm_work() {    # OUT PROG -- the CP/M work disk (appmake must start with a
                # program, so a one-byte STUB.COM goes first and is erased)
    local t; t="$(mktemp -d)"
    printf '\311' > "$t/STUB.COM"
    NPY cpmtext "$SRC/$2.ASM" "$t/$2.ASM"
    cpmdisk "$1" "$t/STUB.COM" "$t/$2.ASM"
    NPY cpmera "$1" STUB.COM
    rm -rf "$t"
}

# the 2 ms clock, as the debugger reads it from the emulated timer (it counts
# whether or not the CPU takes the interrupt, so disk I/O does not hide time)
clock_at() { grep -ao '2 ms clock: [0-9]*' "$1" | sed -n "${2}p" | grep -o '[0-9]*$'; }

keep() {        # RUNDIR NAME -- cells, then screens/NAME.json
    cells "$1/screen.ppm" "$1/screen.json" 2> /dev/null
    python3 "$BOOK/tools/keepscreen.py" "$(basename "$1")" "$2" \
        'Dummy Cafe=Workshop' 'DUMMY CAFE=WORKSHOP' 'TMA-3=FujiNet' '127.0.0.1=192.168.1.89'
}

timing() {      # PROG ASSEMBLER LOG N1 N2 [N3]
    local a b c; a="$(clock_at "$3" "$4")"; b="$(clock_at "$3" "$5")"
    local line
    line="$(printf '%-7s %-22s %6d ticks = %6.2f s' "$1" "$2" $((b - a)) "$(echo "($b - $a) * 0.002" | bc)")"
    if [[ $# -ge 6 ]]; then
        c="$(clock_at "$3" "$6")"
        line+="$(printf '   LOAD %5d ticks = %5.2f s' $((c - b)) "$(echo "($c - $b) * 0.002" | bc)")"
    fi
    sed -i "/^$1 /d" "$DATA/timing.txt" 2> /dev/null
    echo "$line" >> "$DATA/timing.txt"
    sort -o "$DATA/timing.txt" "$DATA/timing.txt"
    echo "  $line"
}

# ---- HDOS: Heath's ASM -----------------------------------------------------
hdos_native() { # prog
    local P="${1^^}" ra="$BOOK/build/runs/native-$1-asm" rr="$BOOK/build/runs/native-$1-run"
    rm -rf "$ra" "$rr"; mkdir -p "$ra" "$rr"
    hdos_work "$ra/data.h8d" "$P"
    cp "$BOOK/build/disks/hdos-fn.h8d" "$ra/boot.h8d"
    local BOOT RUNS
    mapfile -t BOOT < <(hdos_boot_steps)
    RUNS=(--type "SY1:$P\r" --wait 1500 --prompt '>')
    flock 9
    rig_start "$ra"
    emu "$ra" --timeout 300 --disk "h17:1=$ra/boot.h8d" --disk "h17:2=$ra/data.h8d" "${BOOT[@]}" \
        --type 'MOUNT SY1:\r' --wait 2000 --prompt '>' \
        --debug timer --type "SY1:ASM SY1:$P,SY1:$P=SY1:$P\r" --debug timer \
        --wait 1000 --prompt '>' --debug timer --wait 300 --screen --ppm "$ra/screen.ppm" \
        "${RUNS[@]}" --wait 300 --screen --ppm "$rr/screen.ppm" > "$ra/emu.log" 2>&1
    local rc=$?
    cp "$ra/tap.jsonl" "$rr/" 2> /dev/null
    rig_stop
    flock -u 9
    screen_of "$ra/emu.log" > "$ra/screen.txt"
    [[ $rc -ne 0 ]] && { echo "native $1: FAILED (rc $rc)"; tail -20 "$ra/screen.txt"; return 1; }
    hdosfs get "$ra/data.h8d" "$P.LST" -o "$OUT/$P.LST.raw"
    hdosfs get "$ra/data.h8d" "$P.ABS" -o "$OUT/$P.ABS"
    NPY text "$OUT/$P.LST.raw" "$DATA/$P.LST"; rm -f "$OUT/$P.LST.raw"
    keep "$ra" "native-$1-asm"
    keep "$rr" "native-$1-run"
    timing "$P" "Heath ASM (HDOS)" "$ra/emu.log" 2 3
}

# ---- CP/M: DRI's ASM and LOAD ----------------------------------------------
cpm_native() {  # prog
    local P="${1^^}" ra="$BOOK/build/runs/native-$1-asm" rr="$BOOK/build/runs/native-$1-run"
    rm -rf "$ra" "$rr"; mkdir -p "$ra" "$rr"
    cpm_work "$ra/data.h8d" "$P"
    cp "$BOOK/build/disks/cpm62.h8d" "$ra/boot.h8d"
    local BOOT ASMK LOADK RUNK RUNS
    mapfile -t BOOT < <(cpm_boot_steps)
    mapfile -t ASMK < <(slow "ASM B:$P")
    mapfile -t LOADK < <(slow "LOAD B:$P")
    mapfile -t RUNK < <(slow "B:$P")
    RUNS=("${RUNK[@]}" --type '\r' --wait 1500 --prompt 'A>')
    flock 9
    rig_start "$ra"
    emu "$ra" --timeout 300 --disk "h17:1=$ra/boot.h8d" --disk "h17:2=$ra/data.h8d" "${BOOT[@]}" \
        --debug timer "${ASMK[@]}" --type '\r' --debug timer \
        --until 'END OF ASSEMBLY' --wait 300 --prompt 'A>' --debug timer \
        "${LOADK[@]}" --type '\r' --until 'RECORDS WRITTEN' --wait 300 --prompt 'A>' --debug timer \
        --wait 300 --screen --ppm "$ra/screen.ppm" \
        "${RUNS[@]}" --wait 300 --screen --ppm "$rr/screen.ppm" > "$ra/emu.log" 2>&1
    local rc=$?
    cp "$ra/tap.jsonl" "$rr/" 2> /dev/null
    rig_stop
    flock -u 9
    screen_of "$ra/emu.log" > "$ra/screen.txt"
    [[ $rc -ne 0 ]] && { echo "native $1: FAILED (rc $rc)"; tail -20 "$ra/screen.txt"; return 1; }
    for x in PRN HEX COM; do NPY cpmget "$ra/data.h8d" "$P.$x" "$OUT/$P.$x"; done
    NPY text "$OUT/$P.PRN" "$DATA/$P.PRN"
    keep "$ra" "native-$1-asm"
    keep "$rr" "native-$1-run"
    # LOAD's time is the third reading to the fourth
    timing "$P" "DRI ASM 2.0 (CP/M)" "$ra/emu.log" 2 3 4
}

# ---- the cross-check: z88dk-z80asm, 8080 mode, Intel mnemonics -------------
xcheck() {
    local z="$OUT/z80asm" rc=0 p
    mkdir -p "$z"
    {
        echo "z88dk-z80asm -m8080 cross-check ($(z88dk-z80asm 2>&1 | head -1))"
        for p in FNVER; do
            [[ -f "$OUT/$p.COM" ]] || continue
            NPY z80 dri "$SRC/$p.ASM" "$z/$p.asm"
            z88dk-z80asm -m8080 -b -l -o="$z/$p.bin" "$z/$p.asm" || rc=1
            NPY compare-cpm "$OUT/$p.HEX" "$OUT/$p.COM" "$z/$p.bin" || rc=1
        done
        for p in FNVERH; do
            [[ -f "$OUT/$p.ABS" ]] || continue
            NPY z80 heath "$SRC/$p.ASM" "$z/$p.asm" "$WORK"
            z88dk-z80asm -m8080 -b -l -m -o="$z/$p.bin" "$z/$p.asm" || rc=1
            NPY compare-abs "$OUT/$p.ABS" "$z/$p.bin" "$z/$p.map" 2280 || rc=1
        done
    } | tee "$DATA/xcheck.txt"
    return $rc
}

progs=("$@")
[[ ${#progs[@]} -eq 0 ]] && progs=(fnver fnverh)
fail=0
for p in "${progs[@]}"; do
    case "$p" in
      fnver)   echo "native $p: CP/M ASM + LOAD"; cpm_native "$p" || fail=1 ;;
      fnverh)  echo "native $p: HDOS ASM"; hdos_native "$p" || fail=1 ;;
      check)         ;;
      *) echo "native.sh: no program $p" >&2; exit 2 ;;
    esac
done
xcheck || fail=1
exit $fail
