#!/usr/bin/env bash
# Build CONFIG for the capture rig: fujinet-config's HEAD with -DH89_RIG_KEYS
# (` stands in for ESC, which the emulator's typing can't send), into
# build/rigcfg -- nothing is written into fujinet-config.
set -euo pipefail
source "$(dirname "$0")/rig.sh"
R="$BOOK/build/rigcfg"; rm -rf "$R"; mkdir -p "$R"
(cd "$FC" && git archive HEAD) | tar -x -C "$R"
export ZCCCFG="$HOME/Workspace/z88dk/lib/config"
LIB="${FUJINET_LIB:-$HOME/Workspace/fujinet-lib}"
make -C "$R" FUJINET_LIB="$LIB" CFLAGS_EXTRA_H89-CPM="-DBUILD_H89 -DH89_RIG_KEYS" h89-cpm/r2r >/dev/null
make -C "$R" FUJINET_LIB="$LIB" CFLAGS_EXTRA_H89-HDOS="-DBUILD_H89 -DH89_RIG_KEYS" h89-hdos/r2r >/dev/null
ls -la "$R/r2r/h89-cpm/config.com" "$R/r2r/h89-hdos/config.abs"
