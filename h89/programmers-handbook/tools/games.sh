#!/usr/bin/env bash
# Build the three network games for the H89 from the trees the book lists:
# Texas Hold'em and Battleship from their add-h89 commits, Fujitzee from
# its add-h89 working tree (its H89 port is not committed yet -- see
# README.md). Each is copied into build/games/<game>, built for HDOS and
# CP/M against the book's fujinet-lib, and its .d files kept, so
# tools/mklistings.py can list exactly what was compiled.
#
#   tools/games.sh [GAME...]      texasHoldEm battleship fujitzee
#
# Copyright (C) 2026 Thomas Cherryhomes
# SPDX-License-Identifier: GPL-3.0-or-later
set -euo pipefail
BOOK="$(cd "$(dirname "$0")/.." && pwd)"
export PATH="$HOME/Workspace/z88dk/bin:$PATH" ZCCCFG="$HOME/Workspace/z88dk/lib/config"
declare -A COMMIT=([texasHoldEm]=6bad3aa [battleship]=0c86ed6 [fujitzee]=WORKTREE)
games=("$@"); [[ ${#games[@]} -eq 0 ]] && games=(texasHoldEm battleship fujitzee)
for g in "${games[@]}"; do
  src="$HOME/Workspace/fujinet-$g" dst="$BOOK/build/games/$g"
  rm -rf "$dst"; mkdir -p "$dst"
  if [[ ${COMMIT[$g]} == WORKTREE ]]; then
    (cd "$src" && git ls-files -co --exclude-standard) | grep -v '^_cache/\|^build/\|^r2r/' > "$dst.files"
    rsync -a --files-from="$dst.files" "$src/" "$dst/"
    echo "$g: working tree of $(git -C "$src" rev-parse --short HEAD) ($(git -C "$src" branch --show-current)) + $(git -C "$src" status --short | wc -l) changed files"
  else
    git -C "$src" archive "${COMMIT[$g]}" | tar -x -C "$dst"
    echo "$g: ${COMMIT[$g]}"
  fi
  for p in h89-hdos h89-cpm; do
    make -C "$dst" FUJINET_LIB="$BOOK/build/fnlib" PLATFORMS=$p $p > "$dst/build-$p.log" 2>&1 \
      || { echo "$g $p: BUILD FAILED (build/games/$g/build-$p.log)"; tail -5 "$dst/build-$p.log"; exit 1; }
    { ls -l "$dst"/r2r/$p/*.abs "$dst"/r2r/$p/*.com 2>/dev/null || true; } | awk -v g=$g -v p=$p '{print g, p, $5, $NF}'
  done
done
