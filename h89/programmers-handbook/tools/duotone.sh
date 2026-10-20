#!/usr/bin/env bash
# The cover's picture: the KiCad render of the V1.1 card as a three-tone print in the
# 1979 Heathkit cover inks -- brown 6C3500, gold D0A846, yellow FEF069
# (eyedropped from the H88 Operation Manual's cover) -- with the paper
# behind the board knocked out to the page's gold.
#   tools/duotone.sh images/photo/board.jpg images/cover-board.png
set -euo pipefail
src="$1"; out="$2"; tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
magick xc:'#6C3500' xc:'#D0A846' xc:'#FEF069' -append "$tmp/clut.png"
# crop to the board, three tones by brightness
magick "$src" -crop 1335x770+10+9 +repage -colorspace Gray -auto-level -blur 0x0.6 \
    -fx 'u<0.20?0:(u<0.58?0.5:1)' "$tmp/post.png"
magick "$tmp/post.png" "$tmp/clut.png" -clut "$tmp/duo.png"
# the board's outline (with its connector tab); outside it, gold
magick -size 1335x770 xc:black -fill white \
    -draw "polygon 2,2 1333,2 1333,685 728,685 728,768 98,768 98,685 2,685" "$tmp/mask.png"
# the render's board is dark, so it prints gold: a brown line keeps its edge
magick -size 1335x770 xc:'#D0A846' "$tmp/duo.png" "$tmp/mask.png" -composite \
    -fill none -stroke '#6C3500' -strokewidth 5 \
    -draw "polygon 2,2 1333,2 1333,685 728,685 728,768 98,768 98,685 2,685" "$out"
echo "wrote $out"
