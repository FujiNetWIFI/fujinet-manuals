#!/usr/bin/env bash
# games.sh -- the FujiNet games' screens, each game walked by emu/walk.lua
# (waiting for the game's own words before each key) against the book's local
# server for it (emu/bench.sh up games). The images are bench copies of the
# published ones with the server address pointed at localhost
# (tools/patchurl.py); nothing else differs. Snapshots are scaled 3x into
# images/screens/<name>.png.
#
#   emu/games.sh             all
#   emu/games.sh fcs-table ...
set -uo pipefail
cd "$(dirname "$0")/.."
. emu/ports.env
HB=../programmers-handbook
W=$HOME/Workspace
KEYS=$FNPC_DIR/SD/FujiNet
mkdir -p build/games build/tour images/screens

patch() {   # name, source image, public address, local port
    [ build/games/$1.a52 -nt "$2" ] || python3 tools/patchurl.py "$2" build/games/$1.a52 "$3" "http://127.0.0.1:$4/"
}
patch fcs $W/fcs-5200/r2r/atari5200/fcs.bin https://5card.carr-designs.com/ $FCS_PORT
patch th $W/th-5200/r2r/atari5200/texas.bin https://th.carr-designs.com/ $TH_PORT
patch bs $W/bs-5200/r2r/atari5200/fbs.bin https://battleship.carr-designs.com/ $BS_PORT
patch fz $W/fz-5200/r2r/atari5200/fujitzee.bin https://fujitzee.carr-designs.com/ $FZ_PORT
patch fk $W/fk-5200/r2r/atari5200/fujirkle.bin https://fujirkle.carr-designs.com/ $FK_PORT

# the player's name, kept by FujiNet for every game (none: the game asks);
# no saved table, so each game starts at its own table list
setname() {
    rm -f "$KEYS"/0001010?.key "$KEYS"/0001010a.key "$KEYS"/00010100.key
    if [ -n "$1" ]; then printf '%s' "$1" > "$KEYS/00010100.key"; fi
}

# g NAME GAME STEPS WANT
g() {
    local name=$1 game=$2 base
    case $game in fcs|fz|fk) base=0x3000 ;; th|bs) base=0x3400 ;; esac
    want "$name" || return 0
    echo "== $name"
    rm -f "$KEYS"/0001010[1-9a].key        # no saved table: start at the list
    emu/bench.sh restart ${game}server >/dev/null   # and fresh tables
    env SNAP="$name" SCRIPT=walk IMG="build/games/$game.a52" A52_SCREEN=$base A52_ROWS=26 \
        A52_GLYPHS=$([ $game = bs ] && echo bs) \
        STEPS="$3" WANT="$4" THROTTLE=1 SECS=300 emu/run.sh > "build/tour/$name.log" 2>&1
    grep -v '^$' "build/tour/$name.log" | grep -v '^fujinet:\|^Average' | tail -28
    if ! grep -q 'VERDICT PASS' "build/tour/$name.log"; then
        echo "games: $name FAILED" >&2; FAIL=1; return
    fi
    python3 $HB/tools/pngscale.py "$(ls build/snap/$name/a5200/*.png | sort | tail -1)" \
        "images/screens/$name.png" 3 >/dev/null
}
want() { [ ${#ONLY[@]} -eq 0 ] || [[ " ${ONLY[*]} " == *" $1 "* ]]; }
ONLY=("$@")
FAIL=0

anyof() { for n in "$@"; do want "$n" && return 0; done; return 1; }

# 5 Card Stud: the name screen, the tables, a hand, the table menu
if anyof fcs-name; then setname ""; g fcs-name fcs "wait=ENTER YOUR NAME;pause=0.5;shot" "ENTER YOUR NAME"; fi
setname ALEX
g fcs-tables fcs "wait=CHOOSE A TABLE;pause=0.5;shot" "CHOOSE A TABLE TO JOIN|THE BASEMENT"
T5="wait=CHOOSE A TABLE;pause=0.5;down;down;fire;wait=FOLD"
g fcs-table fcs "$T5;pause=0.4;shot" "FOLD|YOU"
g fcs-menu fcs "$T5;pause=1;top;wait=QUIT TABLE;pause=0.4;shot" "QUIT TABLE|HOW TO PLAY"

# Texas Hold'em: the tables, a hand after the flop ("-" draws as "}" here)
g th-tables th "wait=CHOOSE A TABLE;pause=0.5;shot" "CHOOSE A TABLE TO JOIN|THE BASEMENT"
g th-table th "wait=CHOOSE A TABLE;pause=0.5;down;down;fire;wait=FOLD;pause=1;fire;gone=FOLD;wait=FOLD;pause=0.6;shot" "FOLD|YOU"

# Battleship: the games, placing ships, the battle
g bs-tables bs "wait=CHOOSE A GAME TO JOIN;pause=0.5;shot" "CHOOSE A GAME TO JOIN|AI"
BJ="wait=CHOOSE A GAME TO JOIN;pause=0.8;down;down;down;down;fire;wait=WHEN READY;pause=0.5;fire;wait=PLACE YOUR"
g bs-place bs "$BJ;pause=1;fire;pause=2;fire;pause=2;shot" "PLACE YOUR"
g bs-battle bs "$BJ;pause=1;fire;pause=2;fire;pause=2;fire;pause=2;fire;pause=2;fire;gone=PLACE YOUR;pause=6;fire;pause=8;shot" ""

# Fujitzee: the games, the ready room, a turn
g fz-tables fz "wait=choose a game;pause=0.5;shot" "choose a game to join|ai room - 2 bots"
FZJ="wait=choose a game;pause=0.5;down;fire;wait=press fire to toggle"
g fz-ready fz "$FZJ;pause=0.5;shot" "ready up"
g fz-play fz "$FZJ;pause=0.5;fire;wait=your turn;pause=1;fire;pause=3;shot" "your turn"

# Fujirkle: the games, a turn
g fk-tables fk "wait=choose a game;pause=0.5;shot" "choose a game to join"
g fk-play fk "wait=choose a game;pause=0.5;down;fire;wait=press fire to toggle;pause=0.5;fire;wait=your turn;pause=1;fire;pause=3;shot" "your turn"
exit $FAIL
