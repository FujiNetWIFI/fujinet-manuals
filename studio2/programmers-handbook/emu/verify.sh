#!/usr/bin/env bash
# verify.sh -- run every program in the FujiNet MAME cartridge model against
# the bench's fujinet-pc and check what each puts on the screen.
#
#   emu/verify.sh                 all of them
#   emu/verify.sh netget clock    some
#
# Needs the bench (bench/up.sh): fujinet-pc on BoIP, the HTTP fixture and
# the netcat line server. Results go to build/verify.txt, snapshots to
# build/snap/<program>/, raster dumps to build/raster/<program>.hex.
set -uo pipefail
cd "$(dirname "$0")/.."
BOOK="$PWD"
. bench/ports.env
[ -n "$(ss -ltnH "sport = :$BOIP_PORT")" ] || { echo "verify.sh: the bench is down (bench/up.sh)" >&2; exit 1; }

# The SD card: the fixtures, and the programs the dir and boot programs see.
# /s2book/ holds exactly the fixtures and two programs: fujidir lists it.
SD="$FNPC_DIR/SD"
rm -rf "$SD/s2book"
mkdir -p "$SD/s2book"
cp -r listings/fixtures/sd/. "$SD/"
cp listings/asm/build/hello.st2 listings/asm/build/netget.st2 "$SD/s2book/"

# program | seconds | keys | what must be on the screen
TABLE="
hello    | 4  |           | HELLO STUDIO II|FRAME
fujitest | 6  |           | SEQ 01|ERR 00|DUMMY CAFE|127.0.0.1
netget   | 8  |           | HELLO FROM|OVER HTTP|CLOSED
fujidir  | 8  |           | hello.st2|netget.st2|readme.txt
fujiboot | 25 |           | HELLO STUDIO II|\$swaps=1
appkey   | 8  |           | PLAYER 1|HELLO STUDIO II
clock    | 6  |           | LOCAL|UTC|20
keys     | 6  | A5@2 B9@3 | @3,3=i|@4,14=i|B9
glyphs   | 4  |           | @2,8=80|@2,9=81|@3,8=82|@3,9=83|%5,6=222211|@7,7=05|@8,0=i
pages    | 4  |           | 0C|14|D4|ALL OK
netcat   | 40 | drive:ncdrive | heard 'hi'
"

mkdir -p build/raster
: > build/verify.txt
pass=0 fail=0
while IFS='|' read -r prog secs keys want; do
    prog=$(echo "$prog" | xargs)
    [ -n "$prog" ] || continue
    [ $# -eq 0 ] || [[ " $* " == *" $prog "* ]] || continue
    secs=$(echo "$secs" | xargs)
    keys=$(echo "$keys" | xargs)
    want=$(echo "$want" | sed 's/^ *//; s/ *$//')
    rm -rf "build/snap/$prog"
    if [[ $keys == drive:* ]]; then
        # a drive script talks to a live server: real time, and the
        # server's log must show what the program sent
        log=bench/run/ncserver.log.txt
        before=$(wc -l < "$log")
        out=$(THROTTLE=1 SECS=$secs SNAP="$BOOK/build/snap/$prog" \
              timeout 150 emu/run.sh "listings/asm/build/$prog.st2" "${keys#drive:}" 2>&1)
        v=$(echo "$out" | grep -m1 "^VERDICT" || echo "VERDICT FAIL: no verdict")
        if [[ $v == "VERDICT PASS"* ]] && ! tail -n +$((before + 1)) "$log" | grep -qF "$want"; then
            v="VERDICT FAIL: the server never logged: $want"
        fi
    else
        out=$(SHOT_AT=$secs SECS=$((secs + 20)) TEXT_WANT="$want" KEYS="$keys" \
              SNAP="$BOOK/build/snap/$prog" RASTER="$BOOK/build/raster/$prog.hex" \
              timeout 150 emu/run.sh "listings/asm/build/$prog.st2" screen 2>&1)
        v=$(echo "$out" | grep -m1 "^VERDICT" || echo "VERDICT FAIL: no verdict")
    fi
    s=$(echo "$out" | grep -m1 "^STATUS" || true)
    printf '%-10s %s   %s\n' "$prog" "$v" "$s" | tee -a build/verify.txt
    if [[ $v == "VERDICT PASS"* ]]; then pass=$((pass + 1)); else
        fail=$((fail + 1)); echo "$out" | grep -E "^ *[0-9]+\|" | sed 's/^/    /'; fi
done <<< "$TABLE"
echo "verify: $pass passed, $fail failed" | tee -a build/verify.txt
[ $fail -eq 0 ]
