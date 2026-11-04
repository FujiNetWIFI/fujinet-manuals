#!/usr/bin/env bash
# games.sh -- Battleship and 5 Card Stud end to end, and CONFIG's first
# screens, from the bench copies listings/games.sh builds, against the
# bench's own servers (bench/up.sh games). Each is walked by emu/walk.lua in
# real time (THROTTLE=1: the servers answer in real time) and its last
# screen saved to images/screens.
#
#   bench/up.sh games; listings/games.sh; emu/games.sh [names...]
set -uo pipefail
cd "$(dirname "$0")/.."
SRC=bench/run/src
mkdir -p build/games images/screens
ONLY=("$@")
FAIL=0
want() { [ ${#ONLY[@]} -eq 0 ] || [[ " ${ONLY[*]} " == *" $1 "* ]]; }
shot() {    # NAME IMAGE ROWS STEPS WANT
    local name=$1
    want "$name" || return 0
    env SNAP="$name" ROWS="$3" STEPS="$4" WANT="$5" THROTTLE=1 SECS=300 WAITMAX=5400 \
        timeout 400 emu/run.sh "$2" > "build/games/$name.log" 2>&1
    if grep -q 'VERDICT PASS' "build/games/$name.log"; then
        echo "$name: PASS"
        local png
        png=$(find "build/snap/$name" -name '*.png' | sort | tail -1)
        python3 tools/scrscale.py "$png" "images/screens/$name.png" > /dev/null
    else
        echo "$name: FAIL ($(grep -m1 VERDICT "build/games/$name.log" || echo no verdict))"
        FAIL=1
    fi
}
fresh() {   # a game server, restarted: fresh tables for the next walk
    want "$2" || return 0
    local f=bench/run/$1.pid
    if [ -f "$f" ]; then
        kill -TERM -- "-$(cat "$f")" 2>/dev/null || kill -TERM "$(cat "$f")" 2>/dev/null
        rm -f "$f"; sleep 1
    fi
    bench/up.sh games > /dev/null
}
BS=$SRC/bs/arcadia/build/battleship.bin
FCS=$SRC/fcs/arcadia/build/5card.bin
CFG=$SRC/config/arcadia/build/config.bin

# CONFIG: its hosts, then the book's folder on the memory card
shot cfg-hosts "$CFG" 13 "wait=FUJINET HOSTS;pause=30;shot" "FUJINET HOSTS|SD"
shot cfg-browse "$CFG" 13 "wait=FUJINET HOSTS;fire;wait=ARCBOOK/;pause=20;shot" "ARCBOOK/"

# 5 Card Stud: the tables, then a hand against the robots
fresh fcsserver fcs-tables
shot fcs-tables "$FCS" 13 "wait=YOUR NAME;ent;wait=CHOOSE A TABLE;pause=30;shot" "CHOOSE A TABLE"
fresh fcsserver fcs-table
shot fcs-table "$FCS" 26 "wait=YOUR NAME;ent;wait=CHOOSE A TABLE;pause=30;ent;wait=POT;wait=1 FOLD;pause=30;shot" "POT|PURSE|1 FOLD"

# Battleship: the ships placed, then a shot fired and answered
fresh bsserver bs-place
shot bs-place "$BS" 26 "wait=YOUR NAME;ent;wait=CHOOSE A TABLE;pause=60;k5;wait=READY;fire;wait=PLACE YOUR SHIPS;pause=30;shot" "PLACE YOUR SHIPS"
fresh bsserver bs-battle
shot bs-battle "$BS" 26 "wait=YOUR NAME;ent;wait=CHOOSE A TABLE;pause=60;k5;wait=READY;fire;wait=PLACE YOUR SHIPS;fire;pause=30;fire;pause=30;fire;pause=30;fire;pause=30;fire;wait=YOUR TURN;right;right;down;down;fire;pause=240;wait=YOUR TURN;pause=30;shot" "YOUR TURN"
exit $FAIL
