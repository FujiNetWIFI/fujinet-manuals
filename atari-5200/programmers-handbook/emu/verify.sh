#!/usr/bin/env bash
# verify.sh -- run every program in the book against the bench (bench/up.sh)
# and judge its screen; the snapshots land in build/snap/<lang>-<prog>/ for
# tools/shots.sh.
#
#   emu/verify.sh                 everything
#   emu/verify.sh asm-netget ...  just those
#
# A row is: name | image | emu/drive.lua settings | what must be on screen.
# The boot programs' images come from the SD card: fixtures are copied to
# the bench's SD first. Results go to build/verify.txt.
set -uo pipefail
cd "$(dirname "$0")/.."
. bench/ports.env
SD=$FNPC_DIR/SD

# the SD card's fixtures: the boot targets are the two hello programs
mkdir -p "$SD/a5200book" "$SD/FujiNet"
cp listings/fixtures/sd/a5200book/readme.txt "$SD/a5200book/"
cp listings/fixtures/sd/FujiNet/00010100.key "$SD/FujiNet/"
cp listings/asm/build/hello.bin "$SD/a5200book/hello.a52"
cp listings/c/build/hello.bin "$SD/a5200book/helloc.a52"

STICK='PRESS=1=x=20+y=C0+fire+top+k5;2=-k5 SHOT_AT=3'
PADS='STICK X        32|STICK Y       192|BOTTOM BUTTON DOWN|TOP BUTTON    DOWN|KEYPAD        5|SOUND         ON'
TYPE='THROTTLE=1 PRESS=4=fire;4.3=-fire;4.6=right;4.9=-x;5.2=fire;5.5=-fire;5.8=k1;6.1=-k1;6.4=k2;6.7=-k2;7=hash;7.3=-hash SHOT_AT=10'
TABLE=(
"asm-hello   | asm/build/hello.bin    | SHOT_AT=4  | FUJINET ATARI 5200 M0|CART  FN OK"
"asm-acfg    | asm/build/fujitest.bin | SHOT_AT=6  | SSID  Dummy Cafe|IP    127.0.0.1|ERR:    00"
"asm-pads    | asm/build/pads.bin     | $STICK     | $PADS"
"asm-netget  | asm/build/netget.bin   | SHOT_AT=8  | HELLO FROM THE FUJINET|OVER HTTP, TO THE ATARI 5200|CLOSED"
"asm-netcat  | asm/build/netcat.bin   | $TYPE      | NETCAT SAYS HI|ECHO AB12"
"asm-dir     | asm/build/fujidir.bin  | SHOT_AT=6  | DIRECTORY OF SD:/A5200BOOK/|hello.a52|readme.txt"
"asm-boot    | asm/build/fujiboot.bin | SHOT_AT=20 | FUJINET ATARI 5200 M0|CART  FN OK"
"asm-appkey  | asm/build/appkey.bin   | SHOT_AT=8  | PLAYER 1|HELLO 5200"
"asm-clock   | asm/build/clock.bin    | SHOT_AT=6  | LOCAL   20|UTC     20"
"asm-bank    | asm/build/bank.bin     | SHOT_AT=6  | BANK 0    Dummy Cafe|BACK FROM BANK 0: BANK 1|DONE"
"c-hello     | c/build/hello.bin      | SHOT_AT=4  | FUJINET ATARI 5200 C|CART  FN OK"
"c-acfg      | c/build/acfg.bin       | SHOT_AT=6  | SSID  Dummy Cafe|IP    127.0.0.1"
"c-pads      | c/build/pads.bin       | $STICK     | $PADS"
"c-netget    | c/build/netget.bin     | SHOT_AT=8  | HELLO FROM THE FUJINET|OVER HTTP, TO THE ATARI 5200|CLOSED"
"c-netcat    | c/build/netcat.bin     | $TYPE      | NETCAT SAYS HI|ECHO AB12"
"c-dir       | c/build/dir.bin        | SHOT_AT=6  | DIRECTORY OF SD:/A5200BOOK/|hello.a52|readme.txt"
"c-boot      | c/build/boot.bin       | SHOT_AT=20 | FUJINET ATARI 5200 C|CART  FN OK"
"c-appkey    | c/build/appkey.bin     | SHOT_AT=8  | PLAYER 1|HELLO 5200"
"c-clock     | c/build/clock.bin      | SHOT_AT=6  | LOCAL   20|UTC     20"
"c-bank      | c/build/bank.bin       | SHOT_AT=6  | BANK 0    Dummy Cafe|BACK FROM BANK 0: BANK 1|DONE"
)

trim() { local s=$1; s=${s#"${s%%[![:space:]]*}"}; echo "${s%"${s##*[![:space:]]}"}"; }

mkdir -p build
out=build/verify.txt
: > "$out"
pass=0 total=0
for row in "${TABLE[@]}"; do
    IFS='|' read -r name img settings want <<< "$row"
    name=$(trim "$name"); img=$(trim "$img"); settings=$(trim "$settings")
    want=$(trim "${row#*|*|*|}")
    if [ $# -gt 0 ] && [[ " $* " != *" $name "* ]]; then continue; fi
    total=$((total + 1))
    rm -rf "build/snap/$name"
    verdict=$(env $settings SNAP="$name" WANT="$want" SECS=60 \
        timeout 150 emu/run.sh "listings/$img" drive 2>&1 | grep '^VERDICT' | tail -1)
    [ -n "$verdict" ] || verdict="VERDICT FAIL: no verdict"
    case $verdict in "VERDICT PASS"*) pass=$((pass + 1)) ;; esac
    printf '%-12s %s\n' "$name" "$verdict" | tee -a "$out"
    sleep 1                     # one client at a time on the BoIP port
done
echo "verify: $pass/$total PASS" | tee -a "$out"
[ "$pass" = "$total" ]
