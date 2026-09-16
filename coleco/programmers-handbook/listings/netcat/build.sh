#!/usr/bin/env bash
# build.sh -- assemble NETCAT into a 32768-byte ColecoVision cartridge.
#
#   ./build.sh
#
# This is the firmware testrom's build recipe (pico/coleco/build.sh), narrowed
# to one client. NETCAT builds in C with z88dk's +coleco target against the
# user's own OS7 binding library (os7lib) and the shared FujiNet client library
# from ../common. The link line's three FujiNet-specific additions are:
#   -Cz--romsize/--rombase   force exactly 32768 bytes based at $8000;
#   --code-fence/--data-fence  warn if anything reaches the mailbox pages;
#   CLIB_DEFAULT_SCREEN_MODE=-1  keep the crt0's VDP init out of OS7's way.
#
# Environment overrides:
#   Z88DK   z88dk root      (default ~/Workspace/z88dk)
#   OS7LIB  os7lib checkout (default ~/Workspace/os7lib)

set -euo pipefail
cd "$(dirname "$0")"

Z88DK=${Z88DK:-$HOME/Workspace/z88dk}
OS7LIB=${OS7LIB:-$HOME/Workspace/os7lib}
export ZCCCFG="$Z88DK/lib/config"
export PATH="$Z88DK/bin:$PATH"

WINDOW=32768
FENCE=0xF800
COMMON=../common

[ -x "$Z88DK/bin/zcc" ] || { echo "no zcc at $Z88DK/bin/zcc" >&2; exit 1; }
[ -f "$OS7LIB/os7.lib" ] || { echo "no os7.lib at $OS7LIB" >&2; exit 1; }

mkdir -p build

CFLAGS="+coleco -O2 -I$OS7LIB/src -I$COMMON -I."
LDFLAGS="+coleco -m -s \
  -pragma-define:CRT_ORG_BSS=0x702C \
  -pragma-define:CRT_COLECO_SPRITE_NAME_SIZE=128 \
  -pragma-define:CRT_COLECO_SPRITE_ORDER_SIZE=32 \
  -pragma-define:CRT_COLECO_BIOS_BUFFER_SIZE=32 \
  -pragma-define:CRT_COLECO_BIOS_CONTROLLER_SIZE=12 \
  -pragma-define:CRT_ENABLE_STDIO=0 \
  -pragma-define:REGISTER_SP=0x73B8 \
  -pragma-define:CLIB_FOPEN_MAX=0 \
  -pragma-define:fputc_cons=0 \
  -pragma-define:CLIB_DEFAULT_SCREEN_MODE=-1 \
  -Cz--romsize=$WINDOW -Cz--rombase=$WINDOW \
  -Cz--code-fence=$FENCE -Cz--data-fence=$FENCE \
  -L$OS7LIB -los7"

SHARED="$COMMON/fujilib.c $COMMON/fujidisp.c $COMMON/fujiin.c \
        $COMMON/fujiedit.c $COMMON/fujisnd.c"

rm -f build/netcat.bin
# shellcheck disable=SC2086
zcc $CFLAGS $LDFLAGS netcat.c netlib.c netterm.c $SHARED \
    -o build/netcat -create-app
mv build/netcat.rom build/netcat.bin 2>/dev/null || mv build/netcat build/netcat.bin

# Stamp the "FUJI" claim at offset 0x7CFC and check the layout. checkrom.py
# lives in the firmware tree; point CHECKROM at it, or drop a copy beside this.
CHECKROM=${CHECKROM:-$HOME/Workspace/fujinet-firmware/pico/coleco/tools/checkrom.py}
if [ -f "$CHECKROM" ]; then
    python3 "$CHECKROM" --stamp build/netcat.bin
else
    echo "warning: no checkrom.py at $CHECKROM -- image is unstamped" >&2
fi

echo "built build/netcat.bin"
