# Shared set-up for the capture scripts: sourced, not run.
#
# The book's screens and transcripts are taken from FujiNet Go H89's headless
# machine (VirtualH89 + the 82C55 card + the FujiNet firmware in-process),
# running the real HDOS 2.0 and Heath CP/M 2.2.04 with the real CONFIG and
# drivers. Nothing on a screen in the book is typed by hand.
#
# Copyright (C) 2026 Thomas Cherryhomes
# SPDX-License-Identifier: GPL-3.0-or-later

BOOK="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
G="${H89GO:-$HOME/Workspace/fujinet-go-h89-desktop}"     # the emulator
FH="${FUJINET_H89:-$HOME/Workspace/fujinet-h89}"         # FNDISK, FN.DVD, hdosfs
FC="${FUJINET_CONFIG:-$HOME/Workspace/fujinet-config}"   # CONFIG (r2r/h89-*)
export PATH="$HOME/Workspace/z88dk/bin:$PATH"
RUN="$G/build/core/h89_session_run"
ROMS="$G/tools/roms"
FONTROM="$BOOK/build/roms/2716_444-29_h19font.u420"

hdosfs() { python3 -I "$FH/tools/hdosfs.py" "$@"; }
cpmfix() { python3 -I "$FH/tools/cpm-dir-fixup.py" "$1"; }

# cpmdisk OUT FILE... -- a 100K H17 CP/M data disk holding FILEs
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

# cells PPM JSON -- the screen picture read back into characters
cells() { python3 "$BOOK/tools/ppm2cells.py" "$FONTROM" "$1" "$2"; }

# the screen text from a run's log
screen_of() { sed -n '/---- screen ----/,/^\(\[fujinet\] \)\?----------------$/p' "$1" | sed 's/^\[fujinet\] //' | sed '1d;$d'; }

# boot steps (printed one per line, for mapfile)
hdos_boot_steps() {   # SY0: boot disk in drive 1, SY1: in drive 2
    # HDOS 2.0 takes no year past 99; a disk booted before offers its last date
    printf '%s\n' --until 'H:' --type 'B\r' --wait 3000 --type ' ' --wait 500 --type ' ' \
        --prompt 'ACTION? <BOOT>' --type '\r' --until 'DATE (' --wait 500 --type '12-OCT-80\r' \
        --prompt '>'
}
cpm_boot_steps() {
    printf '%s\n' --until 'H:' --type 'B\r' --until 'A>' --wait 1000 --prompt 'A>'
}
