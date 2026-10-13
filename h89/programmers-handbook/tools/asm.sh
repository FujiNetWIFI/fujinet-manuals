#!/usr/bin/env bash
# Assemble one of the book's Z80 programs for the H89 with z88dk-z80asm,
# the way Chapter 4 says to: one source, two systems.
#
#   tools/asm.sh OS NAME SOURCE      OS hdos | cpm
#     -> build/bin/<os>/asm/NAME.ABS (HDOS) or NAME.COM (CP/M), and a listing
#        NAME.lis beside it
#
# Copyright (C) 2026 Thomas Cherryhomes
# SPDX-License-Identifier: GPL-3.0-or-later
set -euo pipefail
BOOK="$(cd "$(dirname "$0")/.." && pwd)"
export PATH="$HOME/Workspace/z88dk/bin:$PATH" ZCCCFG="$HOME/Workspace/z88dk/lib/config"
os="$1" name="$2" src="$3"
cd "$BOOK"
out="build/bin/$os/asm"; mkdir -p "$out"
case "$os" in
  hdos) ext=ABS def=HDOS ;;
  cpm)  ext=COM def=CPM ;;
  *) echo "asm.sh: OS is hdos or cpm" >&2; exit 2 ;;
esac
z88dk-z80asm -b -l -D$def -Isrc/asm/inc -O="$out" -o="$out/$name.$ext" "$src"
lis="$out/${src%.asm}.lis"; [[ -f "$lis" ]] && mv "$lis" "$out/$name.lis"
rm -rf "$out/src" "$out/build"
echo "asm $os $name: $(stat -c %s "$out/$name.$ext") bytes"
