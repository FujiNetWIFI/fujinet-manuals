#!/usr/bin/env bash
# shots.sh -- the newest snapshot of each verified program becomes its
# screen in images/screens/<name>.png. The PNG stays as MAME took it, the
# 1861's whole field at 100 x 246: the book's crt() stretches it to 4:3 with
# its pixels kept hard.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p images/screens
# A drive script takes several. When its log (drive.log) names each with a
# "SNAP tag" line, they are named prefix-tag, in order; otherwise by SERIES.
declare -A PREFIX=([battleship]=bs [bsdrive]=bs [5card]=5card [config]=cfg)
declare -A SERIES=(
    [netcat]="netcat-url netcat-greet netcat-typed netcat-echo"
)
for d in build/snap/*/; do
    name=$(basename "$d")
    mapfile -t all < <(find "$d" -name '*.png' | sort)
    [ ${#all[@]} -gt 0 ] || continue
    if [ -f "$d/drive.log" ] && grep -q "SNAP " "$d/drive.log"; then
        i=0
        while read -r tag; do
            tag=$(echo "$tag" | tr ' /' '--' | tr -cd 'A-Za-z0-9-')
            n="${PREFIX[$name]:-$name}-$tag"
            [ $i -lt ${#all[@]} ] && cp "${all[$i]}" "images/screens/$n.png" && echo "shots: $n"
            i=$((i + 1))
        done < <(grep -o "SNAP .*" "$d/drive.log" | sed 's/^SNAP //')
    elif [ -n "${SERIES[$name]:-}" ]; then
        i=0
        for n in ${SERIES[$name]}; do
            [ $i -lt ${#all[@]} ] && cp "${all[$i]}" "images/screens/$n.png" && echo "shots: $n"
            i=$((i + 1))
        done
    else
        cp "${all[-1]}" "images/screens/$name.png"
        echo "shots: $name"
    fi
done

# the index lib.typ's crt() reads
python3 - <<'EOP'
import json, os
d = "images/screens"
names = sorted(f[:-4] for f in os.listdir(d) if f.endswith(".png"))
json.dump(names, open(os.path.join(d, "index.json"), "w"))
print("shots: %d screens indexed" % len(names))
EOP
