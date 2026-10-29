#!/usr/bin/env bash
# games.sh -- the two games end to end against the bench's own servers
# (bench/up.sh games): a whole game of Battleship against three bots, and
# two hands of 5 Card Stud, then back to CONFIG; and CONFIG's screens. Real time: each takes
# minutes. The drive scripts are the games' own (Battleship's emu/bsdrive.lua)
# and the firmware's (5carddrive.lua), unchanged.
#
#   emu/games.sh                      all three
#   emu/games.sh battleship config    some (battleship, 5card, config)
set -uo pipefail
cd "$(dirname "$0")/.."
BOOK="$PWD"
. bench/ports.env
for p in $BS_PORT $FCS_PORT $BOIP_PORT; do
    [ -n "$(ss -ltnH "sport = :$p")" ] || { echo "games.sh: nothing on $p (bench/up.sh games)" >&2; exit 1; }
done
fail=0
run() {   # name image script secs
    rm -rf "build/snap/$1"
    mkdir -p "build/snap/$1"
    out=$(BS_SNAP_DIR="$BOOK/build/snap/$1" THROTTLE=1 SECS=$4 SNAP="$BOOK/build/snap/$1" \
          timeout $(( $4 + 60 )) emu/run.sh "$2" "$3" 2>&1)
    echo "$out" > "build/snap/$1/drive.log"
    v=$(echo "$out" | grep -m1 "^VERDICT" || echo "VERDICT FAIL: no verdict")
    echo "$1  $v" | tee -a build/verify.txt
    [[ $v == "VERDICT PASS"* ]] || fail=1
}
want() { local n=$1; shift; [ $# -eq 0 ] || [[ " $* " == *" $n "* ]]; }
if want battleship "$@"; then run battleship listings/build/battleship.st2 listings/battleship/emu/bsdrive.lua 900; fi
if want 5card "$@"; then run 5card listings/build/5card.st2 5carddrive 900; fi
if want config "$@"; then
    # CONFIG's browser shows /s2book/ with every program in it; verify.sh
    # puts the folder back as fujidir expects it
    cp listings/asm/build/*.st2 listings/build/5card.st2 listings/build/battleship.st2 \
       "$FNPC_DIR/SD/s2book/"
    run config listings/build/config.st2 cfgshots 90
fi
exit $fail
