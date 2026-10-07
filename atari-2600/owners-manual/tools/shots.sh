#!/usr/bin/env bash
# shots.sh -- every raw MAME screenshot this manual takes itself, re-runnable.
#
#   tools/shots.sh [name ...]       default: every shot below, in order
#   tools/shots.sh offline          only the ones that never touch :9995
#   tools/shots.sh live             only the ones that do
#
# Each block builds what it needs (into the source repo's own gitignored
# build/, through that repo's own build script), runs the image headless in the
# FujiNet-patched MAME under a Lua harness in emu/ -- tour.lua (a step list in
# $TOUR), or 5cs.lua, dragster.lua, bs.lua where the shot has to wait on game
# state -- and copies MAME's native snapshot (176x223) to
# images/screens/raw/<name>.png. tools/scale.py makes the print copies from
# there; nothing here touches the other files already in raw/.
#
# Two kinds of run:
#   OFFLINE  FUJINET_TCP=127.0.0.1:1 -- the cartridge device still answers the
#            mailbox, but nothing is listening, so it reports no link. These
#            are -nothrottle and never touch the fujinet-pc on :9995.
#   LIVE     FUJINET_TCP=127.0.0.1:9995 -- the fujinet-pc-rs232 that is already
#            running. Its BoIP listener takes ONE client: never two MAMEs on it
#            at once, and sleep a second after each run so it frees. LIVE runs
#            are throttled (servers wait on wall clock) and READ ONLY: nothing
#            here writes a host slot, a setting or an appkey.
#
# Facts this wraps (each one cost somebody time):
#   - the ROM path is resolved BEFORE the cd into the MAME tree
#   - MAME must run FROM ITS OWN TREE or -autoboot_script is silently ignored
#   - SDL_VIDEODRIVER=dummy wherever there is no DISPLAY
#   - a stray-MAME pkill must be anchored (^[.]/mame a2600 ...) or it matches
#     the shell running it; this one matches only this script's snapshot dir
#   - FN2600 must be the fn-2600 tree (the one with emu/ and tools/); several
#     repos default to a firmware tree without them
set -euo pipefail
cd "$(dirname "$0")/.."
ROOT=$(pwd)
RAW=$ROOT/images/screens/raw
WORK=$ROOT/build/shots
MAME=${MAME:-$HOME/Workspace/mame}
export FN2600=${FN2600:-$HOME/Workspace/fn-2600/pico/atari-2600}
export FUJI_FIRMWARE=${FUJI_FIRMWARE:-$HOME/Workspace/fn-2600}
WS=${WS:-$HOME/Workspace}
OFFLINE=127.0.0.1:1
LIVE=127.0.0.1:9995
mkdir -p "$RAW" "$WORK"

# run <name> <image> <frames-cap secs> -- run one image under emu/tour.lua.
#   env: TOUR (the steps), NET (OFFLINE|LIVE), FAST=1, PORT1/PORT2 (joy|pad),
#        LUA (another harness: a basename in emu/, or an absolute path),
#        DRIVE_LUA (absolute; for harnesses that dofile it), KEEP (which snapshot,
#        1-based, becomes raw/<name>.png; default the last one taken; KEEP=log
#        instead names each one from the harness's "SNAP=<name>" lines),
#        NAMES ("a b c": snapshot 1 becomes raw/a.png, 2 raw/b.png, ...)
# The harness log is kept in build/shots/<name>.log.
run() {
    local name=$1 img secs=$3
    img=$(realpath "$2")
    local snap=$WORK/$name lua=${LUA:-tour}
    case "$lua" in /*) ;; *) lua=$ROOT/emu/$lua.lua ;; esac
    rm -rf "$snap"; mkdir -p "$snap/cfg"
    pkill -f "^[.]/mame a2600 .*owners-manual/build/shots" 2>/dev/null && sleep 1 || true
    local args=(a2600 -skip_gameinfo -cartslot "${SLOT:-fujinet}"
                -joyport1 "${PORT1:-joy}" -joyport2 "${PORT2:-joy}"
                -cart "$img" -snapshot_directory "$snap"
                -cfg_directory "$snap/cfg" -nvram_directory "$snap/cfg"
                -autoboot_script "$lua"
                -video none -sound none -seconds_to_run "$secs")
    [ -n "${FAST:-}" ] && args+=(-nothrottle)
    [ -n "${DISPLAY:-}" ] || export SDL_VIDEODRIVER=dummy
    ( cd "$MAME" &&
      A2600_EMU="$ROOT/emu" A2600_FWEMU="$FN2600/emu" \
      FUJINET_TCP="${NET:-$OFFLINE}" TOUR="${TOUR:-w180 snap}" \
      ./mame "${args[@]}" ) >"$WORK/$name.log" 2>&1 || true
    sleep 1                       # the one-client BoIP listener frees
    local pngs=("$snap"/a2600/*.png)
    if [ ! -f "${pngs[0]}" ]; then
        echo "shots: $name: no snapshot (see build/shots/$name.log)"; return 0
    fi
    if [ -n "${NAMES:-}" ]; then           # one name per snapshot, in order
        local i=0 s
        for s in $NAMES; do
            [ -f "${pngs[$i]:-}" ] || { echo "shots: $s: no snapshot #$((i + 1))"; break; }
            cp "${pngs[$i]}" "$RAW/$s.png"
            echo "shots: raw/$s.png"
            i=$((i + 1))
        done
        return 0
    fi
    if [ "${KEEP:-}" = log ]; then
        local i=0 s
        for s in $(grep -o 'SNAP=[A-Za-z0-9_-]*' "$WORK/$name.log" | cut -d= -f2); do
            [ -f "${pngs[$i]:-}" ] || break
            cp "${pngs[$i]}" "$RAW/$s.png"
            echo "shots: raw/$s.png"
            i=$((i + 1))
        done
        return 0
    fi
    local pick=${KEEP:-${#pngs[@]}}
    cp "${pngs[$((pick - 1))]}" "$RAW/$name.png"
    echo "shots: raw/$name.png  (${#pngs[@]} taken, kept #$pick)"
}

want=("$@")
on() {                            # on <offline|live> <name...>: run this block?
    [ ${#want[@]} -eq 0 ] && return 0
    local n
    for n in "$@"; do
        case " ${want[*]} " in *" $n "*) return 0;; esac
    done
    return 1
}

# ---------------------------------------------------------------------------
# lobby -- the Game Lobby's layout ROM: a hand-written page of rooms that never
# came from a server (LOBBY 1/2; 5 CARD STUD NORMAL/HIGHROL/BOTS; BATTLESHIP
# OPEN/PRIVATE; FUJITZEE TABLE 1; SEL=THOMC, RST=REFRESH). The real kernel,
# colours and geometry; it waits on nothing, so it runs fast and offline.
if on offline lobby; then
    L=$WS/fujinet-lobby/atari-2600
    make -C "$L" -s layout FN2600="$FN2600" >/dev/null
    TOUR="w180 snap" FAST=1 run lobby "$L/build/layout.bin" 20
fi

# ---------------------------------------------------------------------------
# 5cs-layout -- 5 Card Stud's layout ROM: a made-up table (THOM, ADA, BOT1,
# KAY, REX, MAE, IVY, ZED; FOLD/CHECK/BET 50/ALL-IN), offline and fast.
if on offline 5cs-layout; then
    C=$WS/fujinet-5cardstud/atari-2600
    ( cd "$C" && ./build.sh layout >/dev/null )
    TOUR="w180 snap" FAST=1 run 5cs-layout "$C/build/layout.bin" 20
fi

# ---------------------------------------------------------------------------
# 5cs-tables, 5cs-banner, 5cs-table, 5cs-purses, 5cs-menu -- LIVE, 5 Card Stud
# against https://5card.carr-designs.com/ through the fujinet-pc on :9995.
# emu/5cs.lua waits on the client's own state: the table list, then FIRE sits
# at the first table (AI ROOM - 6, six bots), then the shots on our turn,
# SELECT held for the purses, RESET for the table menu, and LEAVE TABLE so the
# seat is given back. It needs the shared username appkey already set (it
# reads it, never types one). 5cs-banner exists only if a hand ended before
# our turn came round. Throttled: the server's clocks are wall clock.
if on live 5cs-live 5cs-tables 5cs-banner 5cs-table 5cs-purses 5cs-menu; then
    C=$WS/fujinet-5cardstud/atari-2600
    ( cd "$C" && ./build.sh >/dev/null )
    rm -f "$RAW"/5cs-tables.png "$RAW"/5cs-banner.png "$RAW"/5cs-table.png \
          "$RAW"/5cs-purses.png "$RAW"/5cs-menu.png
    NET=$LIVE LUA=5cs KEEP=log run 5cs-live "$C/build/5card.bin" 180
fi

# ---------------------------------------------------------------------------
# The classic ports, OFFLINE. With no link the session bank's N: open fails at
# once: CONNECTING is up for a frame or two, then <TITLE> / NO NETWORK / LOCAL
# PLAY holds for 90 frames (1.5 s) and the unpatched game starts -- in its
# own select/attract state, so RESET starts play exactly as on the 1977-81
# cartridge. Snapshots of the status screen are taken 20 frames into it.
#
# MAME's TIA BLENDS each frame with the one before wherever they differ (its
# phosphor imitation, tia.cpp), so anything moving carries a half-tone trailing
# edge. The play frames below are picked to keep that to a car's or a ball's
# outline, or to none at all.
classic() { echo "$WS/fujinet-2600-$1"; }
need() {                          # need <repo> <image> <make target>
    [ -f "$1/build/$2" ] || make -C "$1" "$3" FUJI_FIRMWARE="$FUJI_FIRMWARE" >/dev/null
}

# combat-nonet, combat-play -- RESET, the left tank drives forward for a
# second, turns, and fires: the shell is in flight in the play frame.
if on offline combat combat-nonet combat-play; then
    G=$(classic combat); need "$G" combat.bin combat
    TOUR="until:LOCAL_PLAY@600 w20 snap w100 reset w60 hold:up w60 rel:up
          hold:right w12 rel:right w20 fire w6 snap" \
    NAMES="combat-nonet combat-play" FAST=1 run combat "$G/build/combat.bin" 30
fi

# dodgem-play -- Dodge 'Em has NO status screen (its boot bank has no text
# kernel wired up); it goes straight to the game. RESET, then two seconds of
# the computer's chase car after the player's.
if on offline dodgem dodgem-play; then
    G=$(classic dodgem); need "$G" dodgem.bin dodgem
    TOUR="w120 reset w120 snap" NAMES="dodgem-play" \
        FAST=1 run dodgem "$G/build/dodgem.bin" 30
fi

# dragster-nonet, dragster-play -- the play frame is emu/dragster.lua's run:
# staged, launched on green, shifted by the tachometer, and snapped seven
# seconds after the launch, when the top car has crossed the line (6.47, 4th
# gear) and the picture is still -- a race in progress ghosts everywhere.
if on offline dragster dragster-nonet dragster-play; then
    G=$(classic dragster); need "$G" dragster.bin dragster
    TOUR="until:LOCAL_PLAY@600 w20 snap" NAMES="dragster-nonet" \
        FAST=1 run dragster-nonet "$G/build/dragster.bin" 20
    LUA=dragster SNAPS=420 NAMES="dragster-play" \
        FAST=1 run dragster-play "$G/build/dragster.bin" 60
fi

# tennis-nonet, tennis-play -- RESET, and two seconds on: both players at
# their baselines, 0 0, pink to serve.
if on offline tennis tennis-nonet tennis-play; then
    G=$(classic tennis); need "$G" tennis.bin tennis
    TOUR="until:LOCAL_PLAY@600 w20 snap w100 reset w120 snap" \
    NAMES="tennis-nonet tennis-play" FAST=1 run tennis "$G/build/tennis.bin" 30
fi

# vo-nonet, vo-play -- Video Olympics on PADDLES (both ports; MAME defaults to
# joysticks and the game then reads nothing sensible). RESET, then a second of
# game 1 with the ball in play.
if on offline vo vo-nonet vo-play; then
    G=$(classic video-olympics); need "$G" vo.bin vo
    TOUR="pot:1x:100 until:LOCAL_PLAY@600 w20 snap w160 reset w60 snap" \
    PORT1=pad PORT2=pad NAMES="vo-nonet vo-play" FAST=1 run vo "$G/build/vo.bin" 30
fi

# ---------------------------------------------------------------------------
# config-hosts -- LIVE: CONFIG (fujinet-config/atari-2600) booted against the
# fujinet-pc on :9995, left on the FN HOSTS screen it starts on, read only:
# no button is pressed, so nothing is mounted, written or selected.
if on live config-hosts; then
    G=$WS/fujinet-config/atari-2600
    [ -f "$G/build/config.bin" ] || make -C "$G" FN2600="$FN2600" >/dev/null
    TOUR="until:FN_HOSTS@1800 until:SEL=MENU@1800 w60 text snap" \
    NET=$LIVE NAMES="config-hosts" run config-hosts "$G/build/config.bin" 60
fi

# ---------------------------------------------------------------------------
# bs-place -- LIVE: Battleship (fujinet-battleship/atari2600) against
# https://battleship.carr-designs.com/ through :9995. emu/bs.lua sits at
# "AI - 1 on 1", readies up, snapshots the placement screen once the rolled
# fleet is drawn, then RESET -> LEAVE TABLE. Throttled (wall-clock server).
if on live bs-place; then
    G=$WS/fujinet-battleship/atari2600
    [ -f "$G/build/battleship.bin" ] || ( cd "$G" && FUJI_FIRMWARE="$FUJI_FIRMWARE" ./build.sh >/dev/null )
    rm -f "$RAW/bs-place.png"
    NET=$LIVE LUA=bs KEEP=log run bs-place "$G/build/battleship.bin" 150
fi
