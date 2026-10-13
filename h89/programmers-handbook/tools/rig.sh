# Shared set-up for the build, capture and verification scripts: sourced,
# not run.
#
# The book's programs run on FujiNet Go H89's headless machine (VirtualH89 +
# the 82C55 card) with its in-process FujiNet switched OFF: the card dials
# 127.0.0.1:11512 instead (fujinet-go-h89-desktop core/src/session.c:209), where
# tap.py logs every frame and passes it on to a standalone fujinet-pc built
# from the h89-disk-fixes firmware (fn-h89 7ab84ae64, RS232 target, PINMAP_H89)
# listening on 11514. So the programs talk to the firmware the book describes,
# and every byte they exchange is on record.
#
# Copyright (C) 2026 Thomas Cherryhomes
# SPDX-License-Identifier: GPL-3.0-or-later

BOOK="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
G="${H89GO:-$HOME/Workspace/fujinet-go-h89-desktop}"     # the emulator
FH="${FUJINET_H89:-$HOME/Workspace/fujinet-h89}"         # hdosfs, cpm-dir-fixup, boot scripts
export PATH="$HOME/Workspace/z88dk/bin:$PATH"
export ZCCCFG="$HOME/Workspace/z88dk/lib/config"
RUN="$G/build/core/h89_session_run"
ROMS="$G/tools/roms"
FONTROM="$BOOK/build/roms/2716_444-29_h19font.u420"
FNPC="$BOOK/build/fnpc/src/RS232/dist"                   # fujinet-pc (make rig)
FNLIB="$BOOK/build/fnlib"                                # fujinet-lib d08f584 (make rig)
TAP_PORT=11512
FNPC_PORT=11514

hdosfs() { python3 -I "$FH/tools/hdosfs.py" "$@"; }
cpmfix() { python3 -I "$FH/tools/cpm-dir-fixup.py" "$1"; }

# cpmdisk OUT FILE... -- a 100K H17 CP/M data disk; the first FILE must be a .COM
cpmdisk() {
    local out="$1"; shift
    local tmp; tmp="$(mktemp -d)"
    local first=1 args=()
    for f in "$@"; do
        cp "$f" "$tmp/$(basename "$f")"
        if [[ $first == 1 ]]; then args+=(-b "$(basename "$f")"); first=0
        else args+=(-a "$(basename "$f")"); fi
    done
    (cd "$tmp" && z88dk-appmake +cpmdisk -f hz89 --container raw --no-com-file "${args[@]}" -o disk >/dev/null)
    cpmfix "$tmp/disk" >/dev/null
    cp "$tmp/disk" "$out"
    rm -rf "$tmp"
}
# hdosdisk OUT LABEL FILE... -- a 100K HDOS data disk
hdosdisk() {
    local out="$1" label="$2"; shift 2
    hdosfs blank "$out" --label "$label" >/dev/null
    for f in "$@"; do hdosfs put "$out" "$f" --name "$(basename "$f" | tr a-z A-Z)" >/dev/null; done
}

cells() { python3 "$BOOK/tools/ppm2cells.py" "$FONTROM" "$1" "$2"; }
screen_of() { sed -n '/---- screen ----/,/^\(\[fujinet\] \)\?----------------$/p' "$1" | sed 's/^\[fujinet\] //' | sed '1d;$d'; }

# ---- the rig: fujinet-pc + tap, one run at a time --------------------------
# rig_start RUNDIR -- fresh fnconfig.ini and SD tree in RUNDIR, fujinet-pc on
# FNPC_PORT, the tap on TAP_PORT logging to RUNDIR/tap.jsonl, the helper
# servers (tools/helpers.py, 7801-7805) logging to RUNDIR/helpers.jsonl, and
# an emulator home in RUNDIR/home with its own FujiNet switched off.
rig_start() {
    local rd="$1"
    rig_stop
    mkdir -p "$rd/SD" "$rd/home/config"
    sed "s/@PORT@/$FNPC_PORT/" "$BOOK/tools/fnconfig-rig.ini" > "$rd/fnconfig.ini"
    cp -r "$BOOK/tools/sd/." "$rd/SD/" 2>/dev/null || true
    printf 'enable_fujinet=0\n' > "$rd/home/config/settings.ini"
    : > "$rd/tap.jsonl"
    (cd "$FNPC" && exec ./fujinet -c "$rd/fnconfig.ini" -s "$rd/SD" -u "http://127.0.0.1:11515" \
        > "$rd/fujinet.log" 2>&1) &
    echo $! > "$BOOK/build/.fnpc.pid"
    python3 "$BOOK/tools/tap.py" "$TAP_PORT" "$FNPC_PORT" "$rd/tap.jsonl" > "$rd/tap.log" 2>&1 &
    echo $! > "$BOOK/build/.tap.pid"
    python3 "$BOOK/tools/helpers.py" "$rd/helpers.jsonl" > "$rd/helpers.log" 2>&1 &
    echo $! > "$BOOK/build/.helpers.pid"
    local i
    for i in $(seq 1 100); do
        grep -q "accepting connections\|listening on" "$rd/fujinet.log" 2>/dev/null && break
        sleep 0.1
    done
    sleep 0.3
}
rig_stop() {
    local f
    for f in "$BOOK/build/.tap.pid" "$BOOK/build/.fnpc.pid" "$BOOK/build/.helpers.pid"; do
        [[ -f "$f" ]] && { kill "$(cat "$f")" 2>/dev/null; rm -f "$f"; }
    done
    pkill -f "^python3 $BOOK/tools/tap.py $TAP_PORT" 2>/dev/null
    pkill -f "^python3 $BOOK/tools/helpers.py" 2>/dev/null
    pkill -f "^./fujinet -c .*fnconfig.ini" 2>/dev/null
    pkill -f "^$RUN " 2>/dev/null           # an emulator left from an interrupted run
    sleep 0.3
}
# emu RUNDIR ARGS... -- the headless H89 against the rig
emu() {
    local rd="$1"; shift
    "$RUN" --roms "$ROMS" --home "$rd/home" "$@"
}

# boot steps (one per line, for mapfile)
hdos_boot_steps() {   # SY0: boot disk in drive 1; HDOS 2.0 takes no year past 99
    printf '%s\n' --until 'H:' --type 'B\r' --wait 3000 --type ' ' --wait 500 --type ' ' \
        --prompt 'ACTION? <BOOT>' --type '\r' --until 'DATE (' --wait 500 --type '12-OCT-80\r' \
        --prompt '>'
}
cpm_boot_steps() {
    printf '%s\n' --until 'H:' --type 'B\r' --until 'A>' --wait 1000 --prompt 'A>'
}
# slow TEXT -- one key at a time (Heath CP/M's BIOS keeps no type-ahead)
slow() { local t="$1" i; for ((i = 0; i < ${#t}; i++)); do printf '%s\n' --type "${t:i:1}" --wait 120; done; }
