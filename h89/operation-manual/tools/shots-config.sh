#!/usr/bin/env bash
# Capture CONFIG's screens for Chapter 6 from the real program on FujiNet Go
# H89's headless machine: HDOS 2.0 or 3.0 (with FN.DVD) and CP/M 2.2.04 (62K),
# CONFIG from fujinet-config's r2r/h89-*. Writes build/shots/<name>.ppm and
# screens/<name>.json (the cells, via ppm2cells).
#
#   tools/shots-config.sh
#
# Copyright (C) 2026 Thomas Cherryhomes
# SPDX-License-Identifier: GPL-3.0-or-later
set -euo pipefail
source "$(dirname "$0")/rig.sh"
SHOTS="$BOOK/build/shots"; mkdir -p "$SHOTS" "$BOOK/screens"
W="$BOOK/build/work-config"; rm -rf "$W"; mkdir -p "$W"
# The emulator types only printable keys (its paste drops ESC), so the
# captures use CONFIG built with -DH89_RIG_KEYS, where ` stands in for ESC;
# nothing on screen differs. tools/rigcfg.sh builds it into build/rigcfg.
RIGCFG="$BOOK/build/rigcfg"

# --- the FujiNet's SD card and settings: a new card's hosts --------------
sdcard() {   # sdcard HOME
    local sd="$1/data/fujinet/SD"
    mkdir -p "$sd/HDOS" "$sd/CPM"
    cp "$BOOK/tools/fnconfig-new.ini" "$1/data/fujinet/fnconfig.ini"
    cp "$W/demo-hdos.h8d" "$sd/HDOS/FUJIDEMO.H8D"
    cp "$W/demo-hdos.h8d" "$sd/HDOS/GAMES.H8D"
    cp "$W/demo-hdos.h8d" "$sd/HDOS/BASIC.H8D"
    cp "$W/demo-cpm.h8d" "$sd/CPM/CPMDEMO.H8D"
    cp "$W/demo-cpm.h8d" "$sd/CPM/WORDSTAR.H8D"
    cp "$W/demo-hdos.h8d" "$sd/FUJIDEMO.H8D"
    cp "$W/demo-cpm.h8d" "$sd/CPMDEMO.H8D"
    cp "$W/blank.h8d" "$sd/BLANK.H8D"
}

# the disks
hdosfs blank "$W/tools-hdos.h8d" --label "FujiNet for HDOS" >/dev/null
hdosfs put "$W/tools-hdos.h8d" "$RIGCFG/r2r/h89-hdos/config.abs" --name CONFIG.ABS >/dev/null
hdosfs put "$W/tools-hdos.h8d" "$FH/build/FN.DVD" --name FN.DVD --flags C0 >/dev/null
printf 'HELLO FROM A FUJINET DRIVE ON THE H89\nTHE SECOND LINE\n' > "$W/HELLO.TXT"
hdosfs blank "$W/demo-hdos.h8d" --label "FUJINET DEMO DISK" >/dev/null
hdosfs put "$W/demo-hdos.h8d" "$W/HELLO.TXT" --name HELLO.TXT >/dev/null
hdosfs blank "$W/blank.h8d" --label "BLANK" >/dev/null
printf 'Hello from a FujiNet drive on the H89.\r\nThe second line.\r\n\032' > "$W/cpmhello.txt"
cp "$W/cpmhello.txt" "$W/HELLO.TXT"
cpmdisk "$W/demo-cpm.h8d" "$BOOK/build/HI.COM" "$W/HELLO.TXT"
cpmdisk "$W/tools-cpm.h8d" "$RIGCFG/r2r/h89-cpm/config.com" "$FH/build/FNDISK.COM"

cap() { printf '%s\n' --wait "${2:-1500}" --ppm "$SHOTS/$1.ppm"; }
# slow TEXT: one key at a time -- Heath CP/M's BIOS keeps no type-ahead, so
# keys typed while CONFIG redraws would be lost (HDOS buffers them)
slow() { local t="$1" i; for ((i = 0; i < ${#t}; i++)); do printf '%s\n' --type "${t:i:1}" --wait 250; done; }

# --- HDOS: one long CONFIG session ---------------------------------------
H="$W/hdos"; mkdir -p "$H"; sdcard "$H"
cp "$BOOK/build/disks/hdos-fn.h8d" "$W/boot-hdos.h8d"
mapfile -t BOOT < <(hdos_boot_steps)
S=()
S+=(--type 'MOUNT SY1:\r' --wait 2000 --prompt '>')
# "Contacting FujiNet..." and "Connecting to" flash by too fast to catch whole;
# the book quotes them
S+=(--type 'RUN SY1:CONFIG.ABS\r' --until 'Contacting FujiNet')
S+=(--until 'Quit' --wait 2500); mapfile -t -O ${#S[@]} S < <(cap hosts)
# edit host slot 4
S+=(--type '4' --wait 500 --type 'E' --until 'Host name, or SD' --type 'TNFS.MYHOUSE.NET'); mapfile -t -O ${#S[@]} S < <(cap host-edit 3000)
S+=(--type '\r' --wait 1500)
# browse the SD card
S+=(--type '1' --wait 500 --type '\r' --until 'FUJIDEMO' --wait 2500); mapfile -t -O ${#S[@]} S < <(cap browse-sd)
S+=(--key down --wait 300 --type '\r' --until 'GAMES' --wait 2500); mapfile -t -O ${#S[@]} S < <(cap browse-folder)
S+=(--type 'F' --until 'matching' --type 'F*'); mapfile -t -O ${#S[@]} S < <(cap filter 800)
S+=(--type '\r' --wait 2500); mapfile -t -O ${#S[@]} S < <(cap filtered)
S+=(--type '\r' --until 'Put it in which' --wait 1000); mapfile -t -O ${#S[@]} S < <(cap mount-image)
S+=(--type '1' --wait 300 --type 'W' --wait 2500)
S+=(--type 'F' --until 'matching' --key erase --wait 300 --type '\r' --wait 2500)
S+=(--key down --wait 300 --key down --wait 300 --type '\r' --until 'Put it in which' --wait 1000 --type '2' --wait 300 --type '\r' --wait 2500)
S+=(--type 'N' --until 'how big'); mapfile -t -O ${#S[@]} S < <(cap newdisk-size 800)
S+=(--type '`' --wait 1000)
S+=(--type 'C' --until 'which host' --wait 1000); mapfile -t -O ${#S[@]} S < <(cap copy-host)
S+=(--type '`' --wait 1500)
S+=(--until 'Quit' --wait 500 --type '\t' --wait 1500); mapfile -t -O ${#S[@]} S < <(cap drives)
S+=(--type 'C' --until 'Firmware' --wait 1500); mapfile -t -O ${#S[@]} S < <(cap info)
S+=(--type 'S' --until 'Choose a network' --wait 1500); mapfile -t -O ${#S[@]} S < <(cap wifi-scan)
S+=(--key down --wait 300 --key down --wait 300 --type '\r' --until 'Password' --type 'swordfish'); mapfile -t -O ${#S[@]} S < <(cap wifi-password 2500)
S+=(--type '\r' --until 'Connecting to')
S+=(--until 'Quit' --wait 2000)
S+=(--type '`' --until ' OK ' --wait 100); mapfile -t -O ${#S[@]} S < <(cap mounting 100)
S+=(--prompt '>' --wait 1000); mapfile -t -O ${#S[@]} S < <(cap exit-hdos 300)
"$RUN" --roms "$ROMS" --home "$H" --timeout 90 \
    --disk "h17:1=$W/boot-hdos.h8d" --disk "h17:2=$W/tools-hdos.h8d" \
    "${BOOT[@]}" "${S[@]}" --screen > "$W/hdos.log" 2>&1 \
    || { grep -E 'timed out' "$W/hdos.log" >&2; screen_of "$W/hdos.log" | tail -30 >&2; exit 1; }

# --- CP/M: CONFIG's first screen and its exit ----------------------------
C="$W/cpm"; mkdir -p "$C"; sdcard "$C"
cp "$BOOK/build/disks/cpm62.h8d" "$W/boot-cpm.h8d"
mapfile -t BOOT < <(cpm_boot_steps)
S=()
S+=(--type 'B:CONFIG\r' --until 'Quit' --wait 2500); mapfile -t -O ${#S[@]} S < <(cap hosts-cpm)
S+=(--type '1' --wait 300 --type '\r' --until 'CPMDEMO' --wait 2500)
S+=(--key down --wait 500 --key down --wait 500 --key down --wait 500)
S+=(--type '\r' --until 'Put it in which' --wait 1000 --type '1' --wait 300 --type 'W' --wait 2500)
S+=(--type '`' --until 'Quit' --wait 1500)
S+=(--type '`' --until 'FujiNet drives' --prompt 'A>' --wait 800); mapfile -t -O ${#S[@]} S < <(cap exit-cpm 300)
"$RUN" --roms "$ROMS" --home "$C" --timeout 90 \
    --disk "h17:1=$W/boot-cpm.h8d" --disk "h17:2=$W/tools-cpm.h8d" \
    "${BOOT[@]}" "${S[@]}" --screen > "$W/cpm.log" 2>&1 \
    || { grep -E 'timed out' "$W/cpm.log" >&2; screen_of "$W/cpm.log" | tail -30 >&2; exit 1; }

mkdir -p "$BOOK/build/cells"
for p in "$SHOTS"/*.ppm; do
    n="$(basename "$p" .ppm)"
    cells "$p" "$BOOK/build/cells/$n.json"
done
python3 "$BOOK/tools/screenfix.py" "$BOOK/build/cells" "$BOOK/screens"
ls "$BOOK/screens"
