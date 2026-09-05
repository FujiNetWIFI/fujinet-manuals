#!/usr/bin/env bash
# build.sh -- compile the FUJINET C DEMO with z88dk's +astrocde target.
#
# Usage: ./build.sh
#
# Output: build/cdemo.bin, always exactly 8192 bytes: the compiled code,
# zero-padded, mailbox pages clear, "FUJI" claim signature at 0x1CFC so
# the mailbox stays alive when the image is booted over the network.
#
# Environment:
#   Z88DK=path      z88dk checkout (default ~/Workspace/z88dk); zcc is
#                   taken from $Z88DK/bin and ZCCCFG derived from it
#
# The +astrocde target is marked incomplete upstream: it ships a crt0 and
# HVGLIB.H but no target clib, so the build links the generic z80 clib and
# support.asm supplies the console-driver stub the runtime insists on.
# The pragmas place BSS at 0x4D00 (above the 80 visible scanlines) and the
# stack at 0x4FC0, and CRT_ENABLE_EIDI=1 makes the crt0 run DI first --
# the mailbox contract.

set -euo pipefail
cd "$(dirname "$0")"

WINDOW=8192
CLAIM_OFF=$((0x1CFC))
ROM_TOP=$((0x1B00))

Z88DK=${Z88DK:-$HOME/Workspace/z88dk}
export ZCCCFG="$Z88DK/lib/config"
export PATH="$Z88DK/bin:$PATH"
ZCC="$Z88DK/bin/zcc"
[ -x "$ZCC" ] || { echo "build.sh: no zcc at $ZCC; set Z88DK=" >&2; exit 1; }

mkdir -p build

"$ZCC" +astrocde main.c text.c fujinet.c support.asm \
    -o build/cdemo.raw -m \
    -pragma-define:CRT_ENABLE_EIDI=1 \
    -pragma-define:REGISTER_SP=0x4fc0 \
    -pragma-define:CRT_ORG_BSS=0x4d00 \
    -pragma-define:CRT_MODEL=1

size=$(wc -c < build/cdemo.raw)
if [ "$size" -gt "$ROM_TOP" ]; then
    echo "build.sh: cdemo is $size bytes, over the $ROM_TOP ROM top" >&2
    exit 1
fi

# BSS and stack must stay inside 0x4D00-0x4FBF.
bss_end=$(awk '/__BSS_END/ { print strtonum("0x" $3); exit }' \
    build/cdemo.map 2>/dev/null || echo 0)
if [ "$bss_end" -gt $((0x4FC0)) ]; then
    printf 'build.sh: BSS ends at %#x, past the 0x4FC0 stack floor\n' \
        "$bss_end" >&2
    exit 1
fi

# Pad to the full window, clear above ROM_TOP, stamp the claim.
{
    cat build/cdemo.raw
    head -c $((WINDOW - size)) /dev/zero
} > build/cdemo.bin
printf 'FUJI' | dd of=build/cdemo.bin bs=1 seek=$CLAIM_OFF \
    conv=notrunc status=none
rm -f build/cdemo.raw

python3 tools/checkrom.py build/cdemo.bin
echo "build.sh: code+data $size of $ROM_TOP bytes"
