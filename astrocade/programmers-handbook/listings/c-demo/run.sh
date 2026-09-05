#!/usr/bin/env bash
# run.sh -- run the built demo in MAME against a live fujinet-pc.
#
# Usage: ./run.sh [extra mame args...]
#
#   FUJINET_TCP=host:port   fujinet-pc BoIP listener (default 127.0.0.1:9995)
#   FUJINET_DEBUG=1         per-transaction stderr log (default on here)
#   MAME_DIR=path           MAME tree with the fujinet cart device applied
#                           (see fujinet-firmware pico/astrocade/emu/apply.sh)
#
# Expects the astrocde BIOS in $MAME_DIR/roms. At the on-screen menu, press
# keypad 1 to start the demo.

set -euo pipefail
cd "$(dirname "$0")"

MAME_DIR=${MAME_DIR:-$HOME/Workspace/mame}

[ -f build/cdemo.bin ] || ./build.sh

export FUJINET_TCP=${FUJINET_TCP:-127.0.0.1:9995}
export FUJINET_DEBUG=${FUJINET_DEBUG:-1}

exec "$MAME_DIR/mame" astrocde \
    -rompath "$MAME_DIR/roms" \
    -cartslot fujinet -cart "$PWD/build/cdemo.bin" \
    -window -nomax \
    "$@"
