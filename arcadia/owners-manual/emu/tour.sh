#!/usr/bin/env bash
# tour.sh -- every CONFIG screen the book shows, captured from CONFIG running
# on the FujiNet cartridge in MAME against the owner's bench (emu/bench.sh up,
# emu/getsrc.sh). Each screen is one run of emu/walk.lua: a walk through the
# menus that waits for each screen's own words before the next key, a check
# that the screen says what the book quotes (WANT), and a snapshot, scaled
# 9 x 5 (tools/scrscale.py) into images/screens/<name>.png. The screen as
# text goes to build/tour/<name>.log, where tools/strcheck.py looks too.
#
#   emu/tour.sh            all of them
#   emu/tour.sh hosts info ...
set -uo pipefail
cd "$(dirname "$0")/.."
mkdir -p images/screens build/tour
SRC=build/src

# shot NAME STEPS WANT [SWAP] [POKES]   (THR=1 runs MAME at real speed;
# IMG= another image)
shot() {
    local name=$1
    echo "== $name"
    env SNAP="$name" STEPS="$2" WANT="$3" SWAP="${4:-}" POKES="${5:-}" \
        ${THR:+THROTTLE=1} ${IMGX:+IMG=$IMGX} ${ROWSX:+ROWS=$ROWSX} \
        emu/run.sh > "build/tour/$name.log" 2>&1
    grep '^|\|^VERDICT' "build/tour/$name.log" || true
    if ! grep -q 'VERDICT PASS' "build/tour/$name.log"; then
        echo "tour: $name FAILED" >&2
        return 1
    fi
    local png
    png=$(ls build/snap/"$name"/arcadia/*.png | sort | tail -1)
    python3 tools/scrscale.py "$png" "images/screens/$name.png" >/dev/null
}
want() { [ ${#ONLY[@]} -eq 0 ] || [[ " ${ONLY[*]} " == *" $1 "* ]]; }

# ---- the bench's memory card: some games, the Lobby, a text file --------
. emu/ports.env
SD=$FNPC_DIR/SD
ROMS="$HOME/Workspace/arcadia-roms/Emerson - Arcadia 2001"
mkdir -p "$SD/arcadia" "$SD/games"
cp "$SRC/lobby/arcadia/build/lobby.bin" "$SD/arcadia/lobby.bin"
# the bench copies of the games, which the Lobby's rooms boot (emu/rooms.sh)
cp "$SRC/fcs/arcadia/build/5card.bin" "$SRC/bs/arcadia/build/battleship.bin" \
   "$SRC/fz/arcadia/build/fujitzee.bin" "$SRC/th/arcadia/build/texas.bin" "$SD/arcadia/"
for g in "Alien Invaders (USA, Europe)" "Baseball (USA, Europe)" "Breakaway (USA, Europe)" \
         "Cat Trax (USA, Europe)" "Jungler (USA, Europe)" "Red Clash (USA, Europe)" \
         "Space Mission (USA, Europe)" "Space Vultures (USA, Europe)" "Tanks a Lot (USA, Europe)"; do
    cp "$ROMS/$g.bin" "$SD/games/"
done
cp "$HOME/Workspace/fujinet-multiplayer-mule/dist/arcadia/mule.bin" "$SD/games/mule.bin"
rm -f "$SD/games/Battleship.bin"           # the copy shots put it there
printf 'My Arcadia games.\n' > "$SD/readme.txt"

# ---- the invented neighbourhood ------------------------------------------
# fujinet-pc lists "Dummy Cafe 0-6", all at full strength; the book shows
# ordinary names, and the signal cells at three strengths (bar.inc SIGNAL:
# $FB strong, $F2 middling, $E0 weak)
NETS=(HOMENET UPSTAIRS SMITHFAMILY GARAGE "APT 3B" OURWIFI LIBRARY)
WIFI_SWAP=""
for i in $(seq 0 6); do WIFI_SWAP+="DUMMY CAFE $i=>${NETS[$i]}|"; done
SIG=(FB FB F2 F2 F2 E0 E0)
WIFI_POKES=""
for i in $(seq 0 6); do WIFI_POKES+="$((i + 1)),15,${SIG[$i]}|"; done
# this computer's own name and addresses, on INFO, become a home network's
INFO_SWAP="DUMMY CAFE=>HOMENET|TMA-3=>FUJINET|127.0.0.1=>192.168.1.73|0.0.0.0=>192.168.1.1"

H="wait=FUJINET HOSTS"                      # the hosts screen, drawn
NET="$H;k7;wait=OTHER NETWORK"              # the network list
# the password editor with "Fuji2001" typed: F, then small u j i, 2 0 0 1
PASS="$NET;fire;wait=PASSWORD;right;right;right;right;right;fire"
PASS+=";down;down;down;left;fire;up;right;right;right;right;right;fire;left;fire"
PASS+=";up;up;up;left;left;left;left;left;left;left;fire;left;left;fire;fire;right;fire"
# apps.irata.online, over the Internet (read-only TNFS): its top, then
# Arcadia, then !FUJINET
IRATA="$H;k8;k8;fire;wait=ARCADIA/"
ARC="$IRATA;k8;k8;fire;wait=3D BOWLING"
FN="$ARC;fire;wait=5 CARD STUD"

ONLY=("$@")
FAIL=0
run() { want "$1" || return 0; shot "$@" || FAIL=1; }
run hosts "$H;pause=20;shot" "FUJINET HOSTS|1 SD|1 RENAME 3 INFO|7 WIFI  9 LOBBY"
run wifi-pick "$NET;pause=20;shot" "SELECT NETWORK|OTHER NETWORK|FIRE PICK 0 SKIP" "$WIFI_SWAP" "$WIFI_POKES"
run wifi-pass "$PASS;pause=20;shot" "PASSWORD|8/63|FIRE ADD CLR DEL|ENTER OK  0 ESC"
run wifi-conn "$NET;fire;wait=PASSWORD;ent;wait=CONNECTING;shot" "CONNECTING|100%|ANY KEY CANCEL" \
    "DUMMY CAFE 0=>HOMENET"
run info "$H;k3;wait=VERSION;pause=20;shot" "FUJINET INFO|IP ADDRESS|ANY KEY BACK" "$INFO_SWAP"
run rename "$H;k8;k8;k8;k1;wait=HOST NAME;pause=20;shot" "HOST NAME|0/31"
run browse-sd "$H;fire;wait=README.TXT;pause=20;shot" "ARCADIA/|GAMES/|1 UP  4/6 PAGE"
run browse-games "$H;fire;wait=GAMES/;k8;fire;wait=JUNGLER;pause=20;shot" "/GAMES/|JUNGLER"
THR=1 run browse-irata "$IRATA;pause=20;shot" "ARCADIA/"
THR=1 run browse-arcadia "$ARC;pause=20;shot" "/ARCADIA/|FUJINET/|3D BOWLING"
THR=1 run browse-fujinet "$FN;pause=20;shot" "FUJINET/|5 CARD STUD.BI|BATTLESHIP.BIN"
# the filter: *JU* (the * is in the grid's top row)
FLT="$ARC;k7;wait=FILTER;up;up;right;right;right;right;right;right;right;right;right;fire"
FLT+=";down;down;fire;down;left;left;left;left;left;fire"
FLT+=";up;up;up;right;right;right;right;right;fire"
THR=1 run filter-edit "$FLT;pause=20;shot" "FILTER|4/15"
THR=1 run filter "$FLT;ent;wait=FLT:;wait=JUNGLER;pause=20;shot" "FLT:|JUNGLER|JUMP BUG"
# copying Battleship from the Internet to the memory card's games folder
COPY="$FN;k8;k5;wait=COPY TO HOST"
THR=1 run copy-to "$COPY;pause=20;shot" "COPY TO HOST|FIRE PICK DEST|CLR CANCEL COPY"
THR=1 run copy-here "$COPY;up;up;fire;wait=README.TXT;k8;fire;wait=JUNGLER;pause=20;shot" "5 COPY HERE|CLR CANCEL COPY"
THR=1 run copied "$COPY;up;up;fire;wait=README.TXT;k8;fire;wait=JUNGLER;k5;wait=COPIED;shot" "COPIED"
rm -f "$SD/games/Battleship.bin"
# loading M.U.L.E. (51,200 bytes; an 8K game arrives at once), caught
# part-way (a few tries)
if want booting; then
    for _ in 1 2 3 4 5 6; do
        THR=1 shot booting "$H;fire;wait=GAMES/;k8;fire;wait=JUNGLER;k8;k8;k8;k8;k8;fire;wait=BOOTING;wait=100%;shot" \
            "BOOTING|DO NOT POWER OFF" && break
    done || FAIL=1
fi
# the GAME LOBBY key, from the bench's CONFIG (its lobby is on the card)
# the GAME LOBBY key, from the bench's CONFIG (its Lobby is on the card):
# the first time, the Lobby asks for a name ("FUJI" typed), then lists rooms
rm -f "$SD/FujiNet/"*.key
LOB="$H;k9;wait=YOUR NAME"
NAME="$LOB;right;right;right;right;right;fire;down;left;fire;up;right;right;right;right;right;fire;left;fire"
IMGX=$SRC/config/bench/build/config.bin run lobby-name "$NAME;pause=20;shot" "YOUR NAME|4/8"
IMGX=$SRC/config/bench/build/config.bin run lobby-list "$NAME;ent;wait=5 CARD STUD;pause=60;shot" "LOBBY|5 CARD STUD|BATTLESHIP"
# a file that is not a game
run notcart "$H;fire;wait=README.TXT;k8;k8;fire;wait=NOT A CART;shot" "NOT A CART"
exit $FAIL
