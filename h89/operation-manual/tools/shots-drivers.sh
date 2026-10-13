#!/usr/bin/env bash
# Capture the FNDISK chapter's sessions from the real thing on FujiNet Go
# H89's headless machine: putting FN.DVD on a stock HDOS 2.0 disk, using
# FN0:-FN7:, FNDISK on a 64K and on a 62K CP/M, making the 62K system.
# Writes build/shots/<name>.ppm and (through screenfix) screens/<name>.json.
#
#   tools/shots-drivers.sh
#
# Copyright (C) 2026 Thomas Cherryhomes
# SPDX-License-Identifier: GPL-3.0-or-later
set -euo pipefail
source "$(dirname "$0")/rig.sh"
SHOTS="$BOOK/build/shots"; mkdir -p "$SHOTS" "$BOOK/build/cells"
W="$BOOK/build/work-drivers"; rm -rf "$W"; mkdir -p "$W"
RIGCFG="$BOOK/build/rigcfg"          # CONFIG with ` for ESC (tools/rigcfg.sh)
cap() { printf '%s\n' --wait "${2:-1200}" --ppm "$SHOTS/$1.ppm"; }
slow() { local t="$1" i; for ((i = 0; i < ${#t}; i++)); do printf '%s\n' --type "${t:i:1}" --wait 250; done; }
run() {   # run LOG HOME ARGS... -- fails loudly
    local log="$1" home="$2"; shift 2
    "$RUN" --roms "$ROMS" --home "$home" --timeout 120 "$@" --screen > "$log" 2>&1 \
        || { grep -aE 'timed out' "$log" >&2; screen_of "$log" | tail -30 >&2; exit 1; }
}
sdhome() { mkdir -p "$1/data/fujinet/SD"; cp "$BOOK/tools/fnconfig-new.ini" "$1/data/fujinet/fnconfig.ini"; }

# --- disks ---------------------------------------------------------------
hdosfs convert "$G/tools/disks/boot/hdos-2.0.h17disk" "$W/hdos-stock.h8d" >/dev/null
hdosfs blank "$W/tools-hdos.h8d" --label "FujiNet for HDOS" >/dev/null
hdosfs put "$W/tools-hdos.h8d" "$RIGCFG/r2r/h89-hdos/config.abs" --name CONFIG.ABS >/dev/null
hdosfs put "$W/tools-hdos.h8d" "$FH/build/FN.DVD" --name FN.DVD >/dev/null
printf 'HELLO FROM A FUJINET DRIVE ON THE H89\nTHE SECOND LINE\n' > "$W/HELLO.TXT"
hdosfs blank "$W/demo-hdos.h8d" --label "FUJINET DEMO DISK" >/dev/null
hdosfs put "$W/demo-hdos.h8d" "$W/HELLO.TXT" --name HELLO.TXT >/dev/null
head -c 102400 /dev/zero > "$W/notdisk.img"
printf 'Hello from a FujiNet drive on the H89.\r\nThe second line.\r\n\032' > "$W/HELLO.TXT"
cpmdisk "$W/demo-cpm.h8d" "$BOOK/build/HI.COM" "$W/HELLO.TXT"
cpmdisk "$W/tools-cpm.h8d" "$RIGCFG/r2r/h89-cpm/config.com" "$FH/build/FNDISK.COM"

# --- HDOS: putting FN.DVD on the system disk -----------------------------
H="$W/hdos-install"; sdhome "$H"
cp "$W/hdos-stock.h8d" "$W/sy0.h8d"
mapfile -t BOOT < <(hdos_boot_steps)
S=(--type 'MOUNT SY1:\r' --wait 2000 --prompt '>')
S+=(--type 'COPY SY0:FN.DVD=SY1:FN.DVD\r' --wait 4000 --prompt '>'); mapfile -t -O ${#S[@]} S < <(cap hdos-copy-full 300)
S+=(--type 'DELETE SY0:DK.DVD\r' --wait 3000 --prompt '>')
S+=(--type 'COPY SY0:FN.DVD=SY1:FN.DVD\r' --wait 5000 --prompt '>'); mapfile -t -O ${#S[@]} S < <(cap hdos-install 300)
# SHIFT+RESET and boot again: HDOS now offers the date it already has
S+=(--key reset --wait 1500 --until 'H:' --type 'B\r' --until 'ACTION? <BOOT>' --wait 300 --type '\r')
S+=(--until 'DATE (' --wait 300 --type '\r' --prompt '>')
S+=(--type 'STAT\r' --wait 3000 --prompt '>'); mapfile -t -O ${#S[@]} S < <(cap hdos-stat 300)
run "$W/hdos-install.log" "$H" --disk "h17:1=$W/sy0.h8d" --disk "h17:2=$W/tools-hdos.h8d" "${BOOT[@]}" "${S[@]}"
cp "$W/sy0.h8d" "$W/hdos-fn.h8d"      # the system disk with FN.DVD, for the next session

# --- HDOS: using FN0:-FN7: -----------------------------------------------
H="$W/hdos-use"; sdhome "$H"
cp "$W/demo-hdos.h8d" "$H/data/fujinet/SD/FUJIDEMO.H8D"
cp "$W/demo-hdos.h8d" "$H/data/fujinet/SD/GAMES.H8D"
cp "$W/notdisk.img" "$H/data/fujinet/SD/NOTDISK.IMG"
cp "$W/hdos-fn.h8d" "$W/sy0b.h8d"
mapfile -t BOOT < <(hdos_boot_steps)
S=(--type 'MOUNT SY1:\r' --wait 2000 --prompt '>')
S+=(--type 'RUN SY1:CONFIG.ABS\r' --until 'Quit' --wait 2500)
# slot 1 FUJIDEMO read/write, slot 3 NOTDISK, slot 4 GAMES read only
S+=(--type '1' --wait 300 --type '\r' --until 'FUJIDEMO' --wait 2500)
# (after each mount CONFIG comes back to the list with the bar where it was)
pick() {  # pick PATTERN SLOT KEY -- filter to one image, put it in SLOT (KEY W or RETURN)
    printf '%s\n' --type 'F' --until 'matching' --key erase --wait 300 --type "$1\r" --wait 2500 \
        --type '\r' --until 'Put it in which' --wait 800 --type "$2" --wait 300 --type "$3" --wait 2500
}
mapfile -t -O ${#S[@]} S < <(pick 'FUJI*' 1 W)
mapfile -t -O ${#S[@]} S < <(pick 'NOT*' 3 '\r')
mapfile -t -O ${#S[@]} S < <(pick 'GAMES*' 4 '\r')
S+=(--type '`' --until 'Quit' --wait 1500 --type '`' --until 'FUJINET DRIVES' --prompt '>' --wait 500)
mapfile -t -O ${#S[@]} S < <(cap hdos-exit 300)
S+=(--type 'LOAD FN:\r' --wait 3000 --prompt '>')
S+=(--type 'MOUNT FN0:\r' --until 'MOUNTED ON FN0:' --prompt '>')
S+=(--type 'CAT FN0:\r' --until 'HELLO' --prompt '>')
S+=(--type 'TYPE FN0:HELLO.TXT\r' --until 'SECOND LINE' --prompt '>')
S+=(--type 'COPY FN0:PIP.ABS=SY0:PIP.ABS\r' --wait 4000 --prompt '>')
S+=(--type 'CAT FN0:\r' --until 'PIP' --prompt '>'); mapfile -t -O ${#S[@]} S < <(cap hdos-fn0 300)
S+=(--type 'DISMOUNT FN0:\r' --until 'DISMOUNTED' --prompt '>')
S+=(--type 'MOUNT FN1:\r' --wait 4000 --prompt '>')
S+=(--type 'MOUNT FN2:\r' --wait 4000 --prompt '>')
S+=(--type 'MOUNT FN3:\r' --until 'MOUNTED ON FN3:' --prompt '>')
S+=(--type 'COPY FN3:PIP.ABS=SY0:PIP.ABS\r' --wait 4000 --prompt '>')
S+=(--type 'DISMOUNT FN3:\r' --until 'DISMOUNTED' --prompt '>'); mapfile -t -O ${#S[@]} S < <(cap hdos-errors 300)
run "$W/hdos-use.log" "$H" --disk "h17:1=$W/sy0b.h8d" --disk "h17:2=$W/tools-hdos.h8d" "${BOOT[@]}" "${S[@]}"

# --- CP/M: FNDISK on the 64K system it can't share -----------------------
C="$W/cpm64"; sdhome "$C"
cp "$G/tools/disks/boot/cpm-2.2.04-64k.h8d" "$W/cpm64.h8d"
mapfile -t BOOT < <(cpm_boot_steps)
S=(--type 'B:FNDISK\r' --until 'SYSGEN' --prompt 'A>'); mapfile -t -O ${#S[@]} S < <(cap cpm-64k 300)
run "$W/cpm64.log" "$C" --disk "h17:1=$W/cpm64.h8d" --disk "h17:2=$W/tools-cpm.h8d" "${BOOT[@]}" "${S[@]}"

# --- CP/M: making the 62K system (MOVCPM17, SYSGEN) ----------------------
C="$W/cpm62make"; sdhome "$C"
cp "$G/tools/disks/boot/cpm-2.2.04-64k.h8d" "$W/cpm-make.h8d"
S=(--type 'MOVCPM17 62 *\r' --wait 15000 --prompt 'A>')
S+=(--type 'SYSGEN\r' --until 'SOURCE DRIVE NAME' --wait 500 --type '\r' --until 'DESTINATION DRIVE NAME' --wait 500)
S+=(--type 'A' --until 'DESTINATION ON A' --wait 500 --type '\r' --until 'FUNCTION COMPLETE' --wait 1500)
mapfile -t -O ${#S[@]} S < <(cap cpm-sysgen 500)
run "$W/cpm62make.log" "$C" --disk "h17:1=$W/cpm-make.h8d" "${BOOT[@]}" "${S[@]}"

# --- CP/M: FNDISK at work on the 62K system ------------------------------
C="$W/cpm-use"; sdhome "$C"
cp "$W/demo-cpm.h8d" "$C/data/fujinet/SD/CPMDEMO.H8D"
cp "$W/demo-cpm.h8d" "$C/data/fujinet/SD/WORDSTAR.H8D"
cp "$BOOK/build/disks/cpm62.h8d" "$W/cpm62.h8d"
S=(); mapfile -t -O 0 S < <(cap cpm-boot62 300)
S+=(--type 'B:CONFIG\r' --until 'Quit' --wait 2500)
S+=(--type '1' --wait 300 --type '\r' --until 'CPMDEMO' --wait 2500)
S+=(--type '\r' --until 'Put it in which' --wait 1000 --type '1' --wait 300 --type 'W' --until 'CPMDEMO' --wait 2500)
S+=(--key down --wait 400 --type '\r' --until 'Put it in which' --wait 1000 --type '2' --wait 300 --type '\r' --until 'WORDSTAR' --wait 2500)
S+=(--type '`' --until 'Quit' --wait 1500 --type '`' --until 'FujiNet drives' --prompt 'A>' --wait 500)
S+=(--type 'B:FNDISK\r' --until 'Installed' --prompt 'A>' --wait 800); mapfile -t -O ${#S[@]} S < <(cap cpm-fndisk 300)
S+=(--type 'DIR D:\r' --until 'HELLO' --prompt 'A>' --wait 500)
S+=(--type 'TYPE D:HELLO.TXT\r' --until 'second line' --prompt 'A>' --wait 500)
S+=(--type 'D:HI\r' --until 'Hello from a FujiNet drive on the H89!' --prompt 'A>' --wait 500)
S+=(--type 'PIP D:=B:FNDISK.COM\r' --prompt 'A>' --wait 800)
S+=(--type 'DIR D:\r' --until 'FNDISK' --prompt 'A>' --wait 500)
S+=(--type 'STAT D:\r' --until 'Bytes Remaining' --prompt 'A>' --wait 500); mapfile -t -O ${#S[@]} S < <(cap cpm-use 300)
S+=(--type 'DIR F:\r' --until 'Select' --wait 800); mapfile -t -O ${#S[@]} S < <(cap cpm-select 300)
S+=(--type '\r' --prompt 'A>' --wait 500)
S+=(--type 'B:FNDISK\r' --until 'Already installed' --prompt 'A>' --wait 500); mapfile -t -O ${#S[@]} S < <(cap cpm-again 300)
# last: a write to the read-only E: -- BDOS then waits for CTRL-C (give up) or
# any other key (retry), and the emulator can't type CTRL-C
S+=(--type 'PIP E:=B:FNDISK.COM\r' --until 'Bad Sector' --wait 800); mapfile -t -O ${#S[@]} S < <(cap cpm-readonly 300)
run "$W/cpm-use.log" "$C" --disk "h17:1=$W/cpm62.h8d" --disk "h17:2=$W/tools-cpm.h8d" "${BOOT[@]}" "${S[@]}"

for p in "$SHOTS"/hdos-*.ppm "$SHOTS"/cpm-*.ppm; do
    n="$(basename "$p" .ppm)"
    cells "$p" "$BOOK/build/cells/$n.json"
done
python3 "$BOOK/tools/screenfix.py" "$BOOK/build/cells" "$BOOK/screens"
echo done
