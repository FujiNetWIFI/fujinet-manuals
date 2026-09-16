#!/usr/bin/env bash
# build.sh -- assemble the pure-assembly ACFG demo into a 32768-byte cartridge.
#
#   ./build.sh
#
# Unlike the C clients this is hand-written assembly with its own header and
# VDP setup, assembled straight with z88dk-z80asm (no crt0, no linker script).
# z80asm emits only the bytes we wrote, from $8000 up, so build.sh pads the
# image out to a full 32768 bytes with $FF -- the same filler an unmapped
# cartridge address reads as -- and then stamps the "FUJI" claim and runs the
# layout check.
#
# Environment overrides:
#   Z88DK    z88dk root (default ~/Workspace/z88dk)
#   CHECKROM path to the firmware's checkrom.py

set -euo pipefail
cd "$(dirname "$0")"

Z88DK=${Z88DK:-$HOME/Workspace/z88dk}
export ZCCCFG="$Z88DK/lib/config"
export PATH="$Z88DK/bin:$PATH"
CHECKROM=${CHECKROM:-$HOME/Workspace/fujinet-firmware/pico/coleco/tools/checkrom.py}

command -v z88dk-z80asm >/dev/null || { echo "no z88dk-z80asm on PATH" >&2; exit 1; }

mkdir -p build

# Assemble to a raw binary based at the ORG. -b = binary output, -m = map.
z88dk-z80asm -b -m -obuild/acfg.bin acfg.asm

# z80asm writes build/acfg.bin. Pad to exactly 32768 bytes with 0xFF.
python3 - "build/acfg.bin" <<'PY'
import sys
p = sys.argv[1]
data = bytearray(open(p, "rb").read())
if len(data) > 0x8000:
    sys.exit("image is larger than 32768 bytes")
data += b"\xFF" * (0x8000 - len(data))
open(p, "wb").write(data)
PY

if [ -f "$CHECKROM" ]; then
    python3 "$CHECKROM" --stamp build/acfg.bin
else
    echo "warning: no checkrom.py at $CHECKROM -- image is unstamped" >&2
fi

echo "built build/acfg.bin"
