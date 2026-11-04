#!/usr/bin/env bash
# verify.sh -- run every program in MAME against the bench and check its
# screen. PASS or FAIL each, into build/verify.txt.
#
#   emu/verify.sh              every program
#   emu/verify.sh netget dir   just those
#
# Each program is walked by emu/walk.lua: wait for the words it ends on,
# then check WANT. The programs are copied onto the bench's memory card
# first, so fujiboot and fujidir find them. One MAME at a time.
set -uo pipefail
cd "$(dirname "$0")/.."
BOOK=$PWD
. bench/ports.env
BIN=listings/asm/build
mkdir -p build "$FNPC_DIR/SD/arcbook"
cp -r listings/fixtures/sd/. "$FNPC_DIR/SD/"
cp "$BIN"/*.bin "$FNPC_DIR/SD/arcbook/"
OUT=build/verify.txt
: > "$OUT.new"
U="/-_:>*^ "            # fujidisp.inc's eight characters

# name | steps | want | extra environment
table() {
cat <<EOT
hello|pause=30;shot|HELLO FUJINET|
fujitest|wait=127.0.0.1;pause=5;shot|FUJITEST|DUMMY CAFE|127.0.0.1|
pads|wait=PADS;k5;up;start;pause=4;shot|LAST KEY   5|LAST DISC  UP|LAST START|
netget|wait=CLOSED;pause=5;shot|HELLO FROM|THE FUJINET|OVER HTTP|CLOSED|
netcat|wait=NETCAT SAYS HI;down;down;down;down;down;down;down;fire;down;fire;ent;wait=ECHO HI;pause=5;shot|NETCAT SAYS HI|ECHO HI|THROTTLE=1
fujidir|wait=CLOSED;pause=5;shot|APPKEY.BIN|HELLO.BIN|PADS.BIN|CLOSED|
fujiboot|wait=HELLO FUJINET;pause=10;shot|HELLO FUJINET|
appkey|wait=HELLO ARCADIA;pause=5;shot|PLAYER 1|HELLO ARCADIA|
clock|wait=UTC;pause=5;shot|LOCAL|UTC|
sprites|wait=SPRITE HIT;wait=BOX HIT;pause=2;shot|COLOURS|X|
EOT
}

run_one() {   # name steps want extra
    local name=$1 steps=$2 want=$3 extra=$4 log=build/verify-$1.log
    [ -f "$BIN/$name.bin" ] || { echo "$name: FAIL (not built)" | tee -a "$OUT.new"; return; }
    env UDCS="$U" SNAP="$name" STEPS="$steps" WANT="$want" SECS=60 $extra \
        timeout 120 emu/run.sh "$BIN/$name.bin" > "$log" 2>&1
    if grep -q "^VERDICT PASS" "$log"; then
        echo "$name: PASS" | tee -a "$OUT.new"
    else
        echo "$name: FAIL ($(grep -m1 VERDICT "$log" || echo no verdict))" | tee -a "$OUT.new"
    fi
}

want=("$@")
while IFS= read -r line; do
    [ -n "$line" ] || continue
    name=${line%%|*}; rest=${line#*|}
    steps=${rest%%|*}; rest=${rest#*|}
    extra=${rest##*|}; want_s=${rest%|*}
    if [ ${#want[@]} -gt 0 ] && [[ ! " ${want[*]} " == *" $name "* ]]; then continue; fi
    run_one "$name" "$steps" "$want_s" "$extra"
done < <(table)
# protocol 2: fujibank checks itself; the firmware's bankprobe.lua judges it
if [ ${#want[@]} -eq 0 ] || [[ " ${want[*]} " == *" fujibank "* ]]; then
    LUA=$BOOK/listings/runtime/emu/bankprobe.lua SECS=60 timeout 120 \
        emu/run.sh "$BIN/fujibank.bin" > build/verify-fujibank.log 2>&1
    if grep -q "bankprobe: PASS" build/verify-fujibank.log; then
        echo "fujibank: PASS" | tee -a "$OUT.new"
    else
        echo "fujibank: FAIL ($(grep -m1 bankprobe: build/verify-fujibank.log || echo no verdict))" | tee -a "$OUT.new"
    fi
fi
if [ ${#want[@]} -eq 0 ]; then mv "$OUT.new" "$OUT"; else cat "$OUT.new" >> "$OUT"; rm "$OUT.new"; fi
echo "verify: $(grep -c ': PASS' "$OUT") PASS, $(grep -c ': FAIL' "$OUT") FAIL"
