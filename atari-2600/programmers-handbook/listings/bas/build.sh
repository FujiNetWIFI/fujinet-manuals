#!/usr/bin/env bash
# build.sh -- build a batari Basic FujiNet client.
#
#   ./build.sh prog          listings/bas/prog.bas -> build/prog.bin (4096 bytes)
#
# batari Basic's native toolchain (bB=...) and dasm on PATH. The program is
# compiled in build/ so bB's intermediates stay out of the source tree; the
# library files are reached through symlinks so `include fujilib.asm` and a
# project-local default.inc resolve from the build directory.
set -euo pipefail
cd "$(dirname "$0")"
HERE=$(pwd)
export bB="${bB:-$HOME/Workspace/batari-Basic}"
export PATH="$HOME/.local/bin:$PATH"
FN2600="${FN2600:-$HOME/Workspace/fn-2600/pico/atari-2600}"
export FN2600
PROG=${1:?usage: build.sh prog}

mkdir -p build
for f in fujinet.h fujibas.h netdefs.h devdefs.h fujilib.asm fujidisp.asm vcs2600.h; do
    ln -sf "../../dasm/$f" "build/$f"
done
for f in fujitext.asm default.inc; do
    [ -f "$f" ] && ln -sf "../$f" "build/$f"
done
[ -f build/fujitail.bin ] || dasm fujitail.asm -f3 -obuild/fujitail.bin -lbuild/fujitail.lst
# The BASIC half of the header goes in front of the program: batari Basic
# has no BASIC-level include, and a value it has not seen as a `const` is
# compiled as a memory reference. (Error line numbers are offset by its length.)
cat fujiconst.bas "$PROG.bas" > "build/$PROG.bas"
cd build
rm -f "$PROG.bas.bin"
"$bB/2600basic.native.sh" "$PROG.bas" 2>&1 | grep -v "^  basic version\|^  dasm version\|^$\|relocateBB"
[ -f "$PROG.bas.bin" ] || { echo "build.sh: no $PROG.bas.bin produced" >&2; exit 1; }
python3 "$HERE/../../tools/bbfix.py" "$PROG.bas.bin" fujitail.bin "$PROG.bin"
grep -o "[0-9]* bytes of ROM space left" "$PROG.bas.lst" | tail -1 || true
