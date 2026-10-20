#!/usr/bin/env bash
# contact.sh -- the pages in preview/, twelve to a sheet, for the eye.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p preview/sheet
rm -f preview/sheet/*.png
mapfile -t pages < <(find preview -maxdepth 1 -name 'p*.png' | sort)
n=0
for ((i = 0; i < ${#pages[@]}; i += 12)); do
    magick montage "${pages[@]:i:12}" -tile 3x -geometry 600x454+6+6 -background '#c8c4bc' \
        "preview/sheet/sheet$(printf %02d $n).png"
    n=$((n + 1))
done
echo "contact: $n sheets in preview/sheet/"
