#!/usr/bin/env bash
# verify.sh -- run every program in the FujiNet MAME cartridge model against
# the live fujinet-pc and check what each puts on the screen.
#
#   emu/verify.sh                 all 24
#   emu/verify.sh c/netget        one
#
# Needs: fujinet-pc serving bus-over-IP on $FUJINET_TCP (default
# 127.0.0.1:9986) with its SD card at $FNPC_SD, and the netget fixture served
# on 127.0.0.1:8765 (python3 -m http.server 8765 --bind 127.0.0.1
# --directory listings/fixtures). Results also go to build/verify.txt.
set -uo pipefail
cd "$(dirname "$0")/.."
BOOK="$PWD"
FNPC_SD="${FNPC_SD:-$HOME/Workspace/fnpc-7800-a78/SD}"

# The SD card: the fixtures, and the programs the dir and boot programs see.
mkdir -p "$FNPC_SD"
cp -r listings/fixtures/sd/. "$FNPC_SD/"
cp listings/asm/build/hello.bin "$FNPC_SD/a7800book/hello.bin"
cp listings/asm/build/netget.bin "$FNPC_SD/a7800book/netget.bin"

# program | seconds | text that must be on the screen
TABLE="
asm/hello    | 4  | HELLO, WORLD
asm/fujitest | 6  | DUMMY CAFE|127.0.0.1|ERR:    00
asm/netget   | 8  | HELLO FROM|OVER HTTP|CLOSED
asm/fujidir  | 8  | HELLO.BIN|NETGET.BIN|README.TXT
asm/fujiboot | 15 | HELLO, WORLD|M0: BOOT BLOCK
asm/appkey   | 8  | PLAYER 1|HELLO 7800
asm/clock    | 6  | LOCAL   20|UTC     20
asm/fujibank | 4  | BANK 00 00 DUMMY CAFE|BANK 01 00 DUMMY CAFE|BANK 02 00 DUMMY CAFE
c/hello      | 4  | HELLO, WORLD|A FUJINET CARTRIDGE ANSWERS|RUNNING AS AN APP
c/acfg       | 6  | DUMMY CAFE|127.0.0.1
c/netget     | 8  | HELLO FROM|OVER HTTP|CLOSED
c/dir        | 8  | HELLO.BIN|NETGET.BIN|README.TXT
c/boot       | 15 | HELLO, WORLD|M0: BOOT BLOCK
c/appkey     | 8  | PLAYER 1|HELLO 7800
c/clock      | 6  | LOCAL   20|UTC     20
c/bank       | 6  | BANK 0  OK  DUMMY CAFE|BANK 1  OK  DUMMY CAFE|BANK 2  OK  DUMMY CAFE
bas/hello    | 4  | HELLO, WORLD|A FUJINET CARTRIDGE ANSWERS|RUNNING AS AN APP
bas/acfg     | 6  | DUMMY CAFE|127.0.0.1
bas/netget   | 8  | HELLO FROM|OVER HTTP|CLOSED
bas/dir      | 8  | HELLO.BIN|NETGET.BIN|README.TXT
bas/boot     | 15 | HELLO, WORLD|M0: BOOT BLOCK
bas/appkey   | 8  | PLAYER 1|HELLO 7800
bas/clock    | 6  | LOCAL   20|UTC     20
bas/bank     | 6  | BANK 1  DUMMY CAFE|BANK 2  DUMMY CAFE|BANK 3  DUMMY CAFE
"

mkdir -p build
: > build/verify.txt
pass=0 fail=0
while IFS='|' read -r prog secs want; do
    prog=$(echo "$prog" | xargs)
    [ -n "$prog" ] || continue
    [ $# -eq 0 ] || [[ " $* " == *" $prog "* ]] || continue
    secs=$(echo "$secs" | xargs)
    want=$(echo "$want" | sed 's/^ *//; s/ *$//')
    lang=${prog%%/*} name=${prog#*/}
    out=$(SHOT_AT=$secs SECS=$((secs + 20)) TEXT_WANT="$want" \
          SNAP="$BOOK/build/snap/$lang-$name" \
          timeout 150 emu/run.sh "listings/$lang/build/$name.a78" screen 2>&1)
    v=$(echo "$out" | grep -m1 "^VERDICT" || echo "VERDICT FAIL: no verdict")
    s=$(echo "$out" | grep -m1 "^STATUS" || true)
    printf '%-14s %s   %s\n' "$prog" "$v" "$s" | tee -a build/verify.txt
    if [[ $v == "VERDICT PASS"* ]]; then pass=$((pass + 1)); else
        fail=$((fail + 1)); echo "$out" | grep -E "^ *[0-9]+ " | sed 's/^/    /'; fi
done <<< "$TABLE"
echo "verify: $pass passed, $fail failed" | tee -a build/verify.txt
[ $fail -eq 0 ]
