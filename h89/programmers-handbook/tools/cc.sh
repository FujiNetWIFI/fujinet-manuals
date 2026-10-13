#!/usr/bin/env bash
# Build one of the book's C programs for the H89 with z88dk, the way the
# book says to (Chapter 6).
#
#   tools/cc.sh OS NAME SOURCE... [-- MORE ZCC OPTIONS]
#
#   OS      hdos | cpm
#   NAME    the program's name, upper case: build/bin/<os>/c/NAME.ABS or .COM
#   SOURCE  C files, relative to the book; src/c/common is on the include path, and fujinet-lib
#           (build/fnlib) is linked
#
# Copyright (C) 2026 Thomas Cherryhomes
# SPDX-License-Identifier: GPL-3.0-or-later
set -euo pipefail
BOOK="$(cd "$(dirname "$0")/.." && pwd)"
export PATH="$HOME/Workspace/z88dk/bin:$PATH" ZCCCFG="$HOME/Workspace/z88dk/lib/config"
os="$1" name="$2"; shift 2
srcs=() more=()
while [[ $# -gt 0 && "$1" != "--" ]]; do srcs+=("$1"); shift; done
[[ $# -gt 0 ]] && { shift; more=("$@"); }

cd "$BOOK"
FNLIB="$BOOK/build/fnlib"
out="$BOOK/build/bin/$os/c"; mkdir -p "$out"
work="$BOOK/build/cc/$os/$name"; rm -rf "$work"; mkdir -p "$work"
case "$os" in
  hdos) zcc +hdos -startup=3 -Cz--abs -create-app -D__H89__ \
            -pragma-define:CRT_ORG_CODE=0x2A80 -pragma-define:REGISTER_SP=0x2A80 \
            -pragma-define:CRT_ENABLE_COMMANDLINE=0 \
            -pragma-define:CLIB_DISABLE_FGETS_CURSOR=1 \
            -I"$BOOK/src/c/common" -I"$FNLIB/include" \
            -L"$FNLIB/r2r/h89-hdos" -lfujinet.h89-hdos.lib \
            -m -o "$work/$name" "${srcs[@]}" "${more[@]}"
        cp "$work/$name.abs" "$out/$name.ABS" ;;
  cpm)  zcc +cpm -create-app -D__H89__ \
            -I"$BOOK/src/c/common" -I"$FNLIB/include" \
            -L"$FNLIB/r2r/h89-cpm" -lfujinet.h89-cpm.lib \
            -m -o "$work/$name" "${srcs[@]}" "${more[@]}"
        cp "$work/$name.com" "$out/$name.COM" 2>/dev/null || cp "$work/${name}.COM" "$out/$name.COM" ;;
  *) echo "cc.sh: OS is hdos or cpm" >&2; exit 2 ;;
esac
echo "cc $os $name: $(stat -c %s "$out/$name".* | head -1) bytes"
