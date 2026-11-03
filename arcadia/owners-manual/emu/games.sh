#!/usr/bin/env bash
# games.sh -- the game screens the book shows: each FujiNet game's bench
# copy (emu/getsrc.sh, pointed at the bench's own servers) run from the
# FujiNet cartridge in MAME, walked by emu/walk.lua like the CONFIG tour,
# against fresh tables (each shot restarts its game's server). M.U.L.E.'s
# come from its own repo's screenshots.
#
#   emu/bench.sh up games; emu/games.sh [names...]
set -uo pipefail
cd "$(dirname "$0")/.."
mkdir -p images/screens build/tour
SRC=build/src

shot() {    # NAME IMAGE ROWS STEPS WANT
    local name=$1
    echo "== $name"
    env SNAP="$name" IMG="$2" ROWS="$3" STEPS="$4" WANT="$5" THROTTLE=1 SECS=300 WAITMAX=5400 \
        emu/run.sh > "build/tour/$name.log" 2>&1
    grep '^|\|^VERDICT' "build/tour/$name.log" | head -40 || true
    if ! grep -q 'VERDICT PASS' "build/tour/$name.log"; then
        echo "games: $name FAILED" >&2
        return 1
    fi
    local png
    png=$(ls build/snap/"$name"/arcadia/*.png | sort | tail -1)
    python3 tools/scrscale.py "$png" "images/screens/$name.png" >/dev/null
}
want() { [ ${#ONLY[@]} -eq 0 ] || [[ " ${ONLY[*]} " == *" $1 "* ]]; }
ONLY=("$@")
FAIL=0
run() { want "$1" || return 0; shot "$@" || FAIL=1; }
fresh() { want "$2" || return 0; emu/bench.sh restart "$1" > /dev/null; }

FCS=$SRC/fcs/arcadia/build/5card.bin
TH=$SRC/th/arcadia/build/texas.bin
BS=$SRC/bs/arcadia/build/battleship.bin
FZ=$SRC/fz/arcadia/build/fujitzee.bin

# ---- 5 Card Stud: the name, the tables, a hand against the robots -------
run fcs-name "$FCS" 13 "wait=YOUR NAME;pause=30;shot" "5 CARD STUD|YOUR NAME|DISC SPINS 4 6|ENTER ACCEPTS"
fresh fcsserver fcs-tables
run fcs-tables "$FCS" 13 "wait=YOUR NAME;ent;wait=CHOOSE A TABLE;wait=THE DEN;pause=30;shot" \
    "CHOOSE A TABLE|AI ROOM|ENTER JOINS|CLEAR RENAMES"
fresh fcsserver fcs-table
run fcs-table "$FCS" 26 "wait=YOUR NAME;ent;wait=THE DEN;ent;wait=POT;wait=1 FOLD;pause=30;shot" "POT|PURSE|1 FOLD"

# ---- Texas Hold'em: a hand, the board dealt ------------------------------
fresh thserver th-table
run th-table "$TH" 26 "wait=YOUR NAME;ent;wait=THE DEN;ent;wait=POT;wait=1 FOLD;pause=30;k2;gone=1 FOLD;wait=FLOP;wait=1 FOLD;pause=30;shot" "POT|FLOP|PURSE"

# ---- Battleship: hiding the ships, then battle ---------------------------
fresh bsserver bs-place
run bs-place "$BS" 26 "wait=YOUR NAME;ent;wait=CHOOSE A TABLE;wait=CAPE FUJI;pause=60;down;down;down;down;ent;wait=READY;fire;wait=PLACE YOUR SHIPS;pause=30;shot" \
    "PLACE YOUR SHIPS"
fresh bsserver bs-battle
run bs-battle "$BS" 26 "wait=YOUR NAME;ent;wait=CHOOSE A TABLE;wait=CAPE FUJI;pause=60;down;down;down;down;ent;wait=READY;fire;wait=PLACE YOUR SHIPS;fire;pause=30;fire;pause=30;fire;pause=30;fire;pause=30;fire;wait=YOUR TURN;right;right;down;down;fire;pause=240;wait=YOUR TURN;pause=30;shot" \
    "YOUR TURN"

# ---- Fujitzee: your turn, the dice rolled ---------------------------------
fresh fzserver fz-turn
run fz-turn "$FZ" 26 "wait=YOUR NAME;ent;wait=CHOOSE A TABLE;pause=60;ent;wait=FIRE TO READY;fire;wait=YOUR TURN;pause=60;fire;pause=180;shot" \
    "YOUR TURN"

# ---- M.U.L.E.: its own screenshots (fujinet-multiplayer-mule) ------------
if want mule; then
    M=$HOME/Workspace/fujinet-multiplayer-mule/screenshots/arcadia
    for n in 01-title:title 02-lobby:lobby 05-land-grant:land-grant 09-develop-map:develop-map \
             08-develop-town:develop-town 07-land-auction-bidding:auction; do
        python3 tools/scrscale.py "$M/${n%%:*}.png" "images/screens/mule-${n#*:}.png" >/dev/null
    done
    echo "== mule: $(git -C "$M" rev-parse --short HEAD) screenshots"
fi
exit $FAIL
