#!/usr/bin/env bash
# games.sh -- build Battleship, 5 Card Stud and CONFIG for the bench, from
# their pinned sources (git archive: the checkouts are never touched), with
# the cartridge firmware's tools at the book's pin. The games point at the
# bench's own servers (bench/ports.env); CONFIG is built as the firmware
# bakes it, and checked against the baked image byte for byte.
set -euo pipefail
cd "$(dirname "$0")/.."
BOOK=$PWD
. bench/ports.env
W=$HOME/Workspace
OUT=$BOOK/bench/run/src
FWREV=e3923e881
rm -rf "$OUT"; mkdir -p "$OUT/fw"
git -C "$W/fujinet-firmware" archive "$FWREV" pico/arcadia pico/common | tar -x -C "$OUT/fw"
get() {     # name repo rev
    mkdir -p "$OUT/$1"
    git -C "$W/$2" archive "$3" arcadia | tar -x -C "$OUT/$1"
    echo "$1 $2 $3" >> "$OUT/REVS"
}
get bs fujinet-battleship 3f2a548
get fcs fujinet-5cardstud d5db857
get config fujinet-config 6f0a60a
export FUJI_FIRMWARE=$OUT/fw
(cd "$OUT/bs/arcadia" && ENDPOINT="http://127.0.0.1:$BS_PORT/" ./build.sh > build.log 2>&1)
(cd "$OUT/fcs/arcadia" && ENDPOINT="http://127.0.0.1:$FCS_PORT/" ./build.sh > build.log 2>&1)
(cd "$OUT/config/arcadia" && ./build.sh > build.log 2>&1)
for f in bs/arcadia/build/battleship.bin fcs/arcadia/build/5card.bin config/arcadia/build/config.bin; do
    echo "games: $f $(stat -c %s "$OUT/$f") bytes"
done
# CONFIG as baked: the header's bytes, against the build's
python3 - "$OUT/fw/pico/arcadia/firmware/baked/fujiconfigrom.h" "$OUT/config/arcadia/build/config.bin" <<'PY'
import re, sys
h = open(sys.argv[1]).read()
body = h[h.index("{"):h.rindex("}")]
baked = bytes(int(x, 16) for x in re.findall(r"0x([0-9A-Fa-f]{2})", body))
built = open(sys.argv[2], "rb").read()
print("games: CONFIG", "matches the baked image" if baked == built
      else f"DIFFERS from the baked image ({len(baked)} vs {len(built)} bytes)")
sys.exit(0 if baked == built else 1)
PY
