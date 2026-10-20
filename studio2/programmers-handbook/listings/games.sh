#!/usr/bin/env bash
# games.sh -- build the three vendored clients against the bench.
#
#   ./games.sh                 CONFIG, 5 Card Stud, Battleship (+ DEMO)
#
# CONFIG brings its own tools. The games look for the firmware's
# pico/studio2/tools under $FUJI_FIRMWARE; a shim points that at the
# handbook's vendored copy in runtime/tools, so nothing outside the book is
# read. The servers are the bench's own (bench/up.sh games).
set -euo pipefail
cd "$(dirname "$0")"
HERE=$PWD
. ../bench/ports.env
HOST=${HOST:-127.0.0.1}

mkdir -p build/fw/pico/studio2
ln -sfn "$HERE/runtime/tools" build/fw/pico/studio2/tools
export FUJI_FIRMWARE="$HERE/build/fw"

(cd config && ./build.sh)
(cd 5cardstud && ENDPOINT="http://$HOST:$FCS_PORT/" ./build.sh)
(cd battleship && ENDPOINT="http://$HOST:$BS_PORT/" ./build.sh)
cp battleship/build/battleship.st2 build/battleship.st2
(cd battleship && DEMO=1 ./build.sh)
cp battleship/build/battleship.st2 build/bsdemo.st2
cp build/battleship.st2 battleship/build/battleship.st2
cp config/build/config.st2 5cardstud/build/5card.st2 build/
ls -l build/*.st2
