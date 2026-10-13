#!/usr/bin/env bash
# The cover's picture: Thom's photo of the card as a three-tone print in the
# 1979 Heathkit cover inks -- brown 6C3500, gold D0A846, yellow FEF069
# (eyedropped from the H88 Operation Manual's cover) -- with the paper
# behind the board knocked out to the page's gold.
#   tools/duotone.sh images/photo/board.jpg images/cover-board.png
set -euo pipefail
src="$1"; out="$2"; tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
magick xc:'#6C3500' xc:'#D0A846' xc:'#FEF069' -append "$tmp/clut.png"
# crop to the board, three tones by brightness
magick "$src" -crop 1100x660+110+50 +repage -colorspace Gray -auto-level -blur 0x0.6 \
    -fx 'u<0.50?0:(u<0.84?0.5:1)' "$tmp/post.png"
magick "$tmp/post.png" "$tmp/clut.png" -clut "$tmp/duo.png"
# the board's outline (with its two edge connectors); outside it, gold
magick -size 1100x660 xc:black -fill white \
    -draw "polygon 4,6 1090,6 1090,562 590,562 590,650 74,650 74,562 4,562" "$tmp/mask.png"
magick -size 1100x660 xc:'#D0A846' "$tmp/duo.png" "$tmp/mask.png" -composite "$out"
echo "wrote $out"
