#!/usr/bin/env bash
# shots.sh -- the screens in images/screens, from emu/verify.sh's snapshots:
# each program's last snapshot, three times its size with hard pixels.
#
#   tools/shots.sh            after emu/verify.sh
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p images/screens
for d in build/snap/*/a5200; do
    name=$(basename "$(dirname "$d")")
    last=$(ls "$d"/*.png | sort | tail -1)
    python3 tools/pngscale.py "$last" "images/screens/$name.png" 3 >/dev/null
    echo "images/screens/$name.png"
done
