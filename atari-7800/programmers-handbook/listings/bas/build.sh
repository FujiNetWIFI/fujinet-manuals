#!/usr/bin/env bash
# build.sh -- build a 7800basic program as a FujiNet app.
#
#   ./build.sh acfg            -> build/acfg.a78
#
# The 7800basic steps are 7800basic.native.sh's, run directly (that script
# runs the compiler under valgrind); then tools/basfix.py stamps the FujiNet
# claim at $FF70 and checks what the cartridge needs checked, and 7800header
# writes the .a78 header for the bank scheme 7800basic chose.
set -euo pipefail
cd "$(dirname "$0")"
HERE="$PWD"
BOOK="$(cd ../.. && pwd)"
export bas7800dir="${bas7800dir:-$HOME/Workspace/7800basic}"
export PATH="$bas7800dir:$PATH"

for p in "$@"; do
    B="build/$p"
    rm -rf "$B"; mkdir -p "$B"
    cp "$p.bas" "$B/"
    cp ./*.png ./fujinet.bas ./fujilib.bas "$B/"
    cp ./*.asm "$B/" 2>/dev/null || true
    (
        cd "$B"
        7800preprocess < "$p.bas" > "$p.bas.pre"
        7800basic -i "$bas7800dir" -b "$p.bas" -p "$p.bas.pre" > "$p.log"
        7800postprocess -i "$bas7800dir" > "$p.bas.asm"
        dasm "$p.bas.asm" -I"$bas7800dir/includes" -f3 -l"$p.bas.list.txt" -p20 \
             -s"$p.bas.symbol.txt" -o"$p.bas.bin" | 7800filter | tee dasm.log
    )
    python3 "$BOOK/tools/basfix.py" "$B/$p.bas.bin" "$B/$p.bas.list.txt" "$B/dasm.log"
    (cd "$B" && 7800header -o -f a78info.cfg "$p.bas.bin" > /dev/null)
    cp "$B/$p.bas.a78" "build/$p.a78"
done
