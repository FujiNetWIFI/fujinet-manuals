#!/usr/bin/env bash
# build.sh -- build the C programs into build/<name>.bin with cc65,
# fujinet-lib's atari5200 target and MekkoGX's crt0 and linker config.
#
#   ./build.sh hello acfg ...     the named programs
#   FNLIB=... MEKKO=... ./build.sh hello
#
# FNLIB is a fujinet-lib tree with the atari5200 target built in it
# (make atari5200); MEKKO is MekkoGX's mekkogx/ directory.
set -euo pipefail
cd "$(dirname "$0")"
BOOK=$(cd ../.. && pwd)

FNLIB=${FNLIB:-$HOME/Workspace/a5book-fw/fujinet-lib}
MEKKO=${MEKKO:-$HOME/Workspace/a5book-fw/MekkoGX/mekkogx}
LIB=$FNLIB/r2r/atari5200/fujinet.atari5200.lib
[ -f "$LIB" ] || { echo "build.sh: no $LIB (make atari5200 in $FNLIB)" >&2; exit 1; }

CFLAGS=(-t atari5200 -O --cpu 6502 -I "$FNLIB/include" -I "$FNLIB/bus/atari5200" -I .)
# The top 1K of RAM is the screen (antic.c). The crt0 comes first on the
# link line, so it, not cc65's, is __STARTUP__.
LDFLAGS=(-t atari5200 -Wl "-D,__RESERVED_MEMORY__=${RESERVE:-0x400}")

mkdir -p build/obj
python3 "$BOOK/tools/mkfont.py" > build/obj/font.inc
cl65 -t atari5200 --asm-include-dir build/obj -c -o build/obj/antic_dl.o antic_dl.s
cl65 "${CFLAGS[@]}" -c -o build/obj/antic.o antic.c

# bank: a 64K Super Cart. bank.cfg writes bank 0's own 4K to its own file;
# it goes over a copy of bank 1, and bank 0 goes first.
compose_bank() {
    python3 - "$1" build/obj/bank0.part <<'EOP'
import sys
b1 = open(sys.argv[1], "rb").read()
b0 = bytearray(b1)
b0[0x6000:0x7000] = open(sys.argv[2], "rb").read()
open(sys.argv[1], "wb").write(bytes(b0) + b1)
EOP
}

for name in "$@"; do
    objs=("build/obj/$name.o")
    cfg=$MEKKO/atari5200-fujinet.cfg
    if [ "$name" = bank ]; then
        cfg=bank.cfg
        cl65 "${CFLAGS[@]}" -c -o build/obj/bank0.o bank0.c
        cl65 -t atari5200 -c -o build/obj/supercart.o supercart.s
        objs+=(build/obj/bank0.o build/obj/supercart.o)
    fi
    cl65 "${CFLAGS[@]}" -c -o "build/obj/$name.o" "$name.c"
    cl65 "${LDFLAGS[@]}" -C "$cfg" -m "build/obj/$name.map" \
        -o "build/$name.bin" "$MEKKO/atari5200-crt0.s" "${objs[@]}" \
        build/obj/antic.o build/obj/antic_dl.o "$LIB"
    [ "$name" = bank ] && compose_bank "build/$name.bin"
    python3 "$MEKKO/atari5200-romstamp.py" --map "build/obj/$name.map" "build/$name.bin"
    python3 "$BOOK/tools/checkrom.py" --claim --map "build/obj/$name.map" "build/$name.bin"
done
