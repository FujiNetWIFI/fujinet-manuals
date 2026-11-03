#!/usr/bin/env bash
# getsrc.sh -- every Arcadia program the book shows, archived from its
# published ref into build/src (the checkouts themselves are never touched)
# and built there: CONFIG as fujinet-firmware bakes it, plus the bench copies
# of the Lobby and the four games, pointed at the bench's own servers.
# build/src/REVS records what was used.
set -euo pipefail
cd "$(dirname "$0")/.."
BOOK=$PWD
. emu/ports.env
W=$HOME/Workspace
S=$BOOK/build/src
mkdir -p "$S"
: > "$S/REVS"

get() {     # name repo ref
    local name=$1 repo=$2 ref=$3
    rm -rf "${S:?}/$name"
    mkdir -p "$S/$name"
    git -C "$W/$repo" archive "$ref" arcadia | tar -x -C "$S/$name"
    echo "$name $repo $ref $(git -C "$W/$repo" rev-parse --short "$ref")" >> "$S/REVS"
}

get config fujinet-config origin/main
get lobby fujinet-lobby origin/arcadia
get fcs fujinet-5cardstud origin/main
get bs fujinet-battleship origin/main
get fz fujinet-fujitzee origin/main
get th fujinet-texasHoldEm origin/add-arcadia
# Fujitzee's top file is caught by the repo's own .gitignore (fujitzee.*) and
# was never committed: the bench takes it from the working tree (errata G)
cp "$W/fujinet-fujitzee/arcadia/fujitzee.asm" "$S/fz/arcadia/"
echo "fz arcadia/fujitzee.asm from the working tree, md5 $(md5sum < "$S/fz/arcadia/fujitzee.asm" | cut -c1-8)" >> "$S/REVS"

# CONFIG, exactly as baked (checked against the firmware's header below)
(cd "$S/config/arcadia" && ./build.sh > build.log 2>&1)
# the bench's CONFIG: the same program, its GAME LOBBY key pointed at the
# memory card, where the bench keeps the Lobby (the real one is ec.tnfs.io)
cp -r "$S/config/arcadia" "$S/config/bench"
(cd "$S/config/bench" && LOBBY_HOST=SD LOBBY_PATH=/arcadia/lobby.bin ./build.sh > build.log 2>&1)

(cd "$S/lobby/arcadia" && ENDPOINT="http://127.0.0.1:$LOBBY_PORT/view" ./build.sh > build.log 2>&1)
(cd "$S/fcs/arcadia" && ENDPOINT="http://127.0.0.1:$FCS_PORT/" ./build.sh > build.log 2>&1)
(cd "$S/bs/arcadia" && ENDPOINT="http://127.0.0.1:$BS_PORT/" ./build.sh > build.log 2>&1)
(cd "$S/fz/arcadia" && ENDPOINT="http://127.0.0.1:$FZ_PORT/" ./build.sh > build.log 2>&1)
(cd "$S/th/arcadia" && ENDPOINT="http://127.0.0.1:$TH_PORT/" ./build.sh > build.log 2>&1)

# the CONFIG the book shows is the firmware's
want=$(git -C "$W/fujinet-firmware" show origin/master:pico/arcadia/firmware/baked/fujiconfigrom.h |
       python3 -c 'import sys,re,hashlib; s=sys.stdin.read().split("{",1)[1]; print(hashlib.md5(bytes(int(x,16) for x in re.findall(r"0x([0-9A-Fa-f]{2})",s))).hexdigest())')
have=$(md5sum < "$S/config/arcadia/build/config.bin" | cut -d' ' -f1)
echo "config $have (firmware origin/master bakes $want)" >> "$S/REVS"
[ "$want" = "$have" ] || { echo "getsrc: CONFIG differs from the baked one" >&2; exit 1; }
cat "$S/REVS"
ls -l "$S"/*/arcadia/build/*.bin "$S"/config/bench/build/config.bin
