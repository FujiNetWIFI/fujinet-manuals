#!/usr/bin/env bash
# build.sh -- build the C programs: cc65's atari7800 target, fujinet-lib's
# atari7800 target (its crt0, linker config and romstamp), and the MARIA
# tile engine CONFIG and the games use.
#
#   ./build.sh acfg            -> build/acfg.bin (the cart's) and build/acfg.a78 (MAME's)
#   CFG=bank.cfg ./build.sh bank
#
# FNLIB is fujinet-lib with the atari7800 target built (`make atari7800`).
set -euo pipefail
cd "$(dirname "$0")"
BOOK="$(cd ../.. && pwd)"
FNLIB="${FNLIB:-$HOME/Workspace/fnlib-7800}"
LIB="$FNLIB/r2r/atari7800/fujinet.atari7800.lib"
CFG="${CFG:-$FNLIB/makefiles/atari7800-fujinet.cfg}"
CFLAGS=(-t atari7800 -O --cpu 6502 -I"$FNLIB/include" -I"$FNLIB/bus/atari7800")

mkdir -p build
[ build/tiles.s -nt font.txt ] || python3 mktiles.py font.txt build/tiles.s >/dev/null
cl65 -t atari7800 -c -o build/tiles.o build/tiles.s
cl65 -t atari7800 -c -o build/maria.o maria.s

for p in "$@"; do
    objs=()
    for src in "$p".c ${EXTRA:-}; do
        o="build/$(basename "${src%.*}").o"
        cl65 "${CFLAGS[@]}" -c -o "$o" "$src"
        objs+=("$o")
    done
    cl65 -t atari7800 -C "$CFG" -m "build/$p.map" -o "build/$p.bin" \
        "${objs[@]}" build/maria.o build/tiles.o "$LIB"
    if [ "$(stat -c %s "build/$p.bin")" -le 49152 ]; then
        python3 "$FNLIB/makefiles/atari7800-romstamp.py" --stamp --map "build/$p.map" "build/$p.bin"
        python3 "$BOOK/tools/checkrom.py" --claim --notia --map "build/$p.map" "build/$p.bin"
    else                                # banked: romstamp takes 48K at most
        python3 "$BOOK/tools/checkbanks.py" --map "build/$p.map" "build/$p.bin"
    fi
    python3 "$BOOK/tools/mka78.py" "build/$p.bin" "build/$p.a78" "$p"
done
