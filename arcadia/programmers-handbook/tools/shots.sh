#!/usr/bin/env bash
# shots.sh -- every program's screen into images/screens, at print size.
#
# emu/verify.sh leaves each program's last frame in build/snap/<name>; the
# extra pictures below are walked here. tools/scrscale.py scales each 9 x 5,
# MAME's 192 x 262 frame at 4:3 with hard pixels.
set -euo pipefail
cd "$(dirname "$0")/.."
U="/-_:>*^ "
BIN=listings/asm/build
# a held key, for the controller chapter
UDCS="$U" SNAP=pads-held STEPS="wait=PADS;hold=k5;hold=up;pause=12;shot" WANT="PADS" \
    SECS=30 timeout 60 emu/run.sh "$BIN/pads.bin" > build/shot-pads-held.log 2>&1
# netcat mid-line: HI sent and echoed, then F typed and G on the wheel
UDCS="$U" SNAP=netcat-typing THROTTLE=1 SECS=60 WANT="ECHO HI" \
    STEPS="wait=NETCAT SAYS HI;down;down;down;down;down;down;down;fire;down;fire;ent;wait=ECHO HI;up;up;up;fire;down;pause=10;shot" \
    timeout 120 emu/run.sh "$BIN/netcat.bin" > build/shot-netcat.log 2>&1
for d in build/snap/*/; do
    name=$(basename "$d")
    png=$(find "$d" -name '*.png' | sort | tail -1)
    [ -n "$png" ] || continue
    python3 tools/scrscale.py "$png" "images/screens/$name.png" > /dev/null
    echo "shots: $name"
done
