#!/usr/bin/env bash
# bench.sh up|down [games] -- the owner's manual's own fujinet-pc (emu/ports.env)
# and, with "games", the five FujiNet game servers built from
# FujiNetWIFI/servers (origin/main of ~/Workspace/servers, archived into
# build/servers, so the checkout itself is never touched), all on localhost.
# Never the public servers. Pidfiles and logs go in build/run.
set -euo pipefail
cd "$(dirname "$0")/.."
BOOK=$PWD
. emu/ports.env
RUN=$BOOK/build/run
SRV=$HOME/Workspace/servers
GS=$BOOK/build/servers/fujinet-game-system
if [ ! -d "$GS" ]; then
    mkdir -p "$BOOK/build/servers"
    git -C "$SRV" archive origin/main fujinet-game-system | tar -x -C "$BOOK/build/servers"
    git -C "$SRV" rev-parse --short origin/main > "$BOOK/build/servers/REV"
fi
mkdir -p "$RUN/bin"

alive() { [ -f "$RUN/$1.pid" ] && kill -0 "$(cat "$RUN/$1.pid")" 2>/dev/null; }
start() {   # name, dir, command...
    local name=$1 dir=$2; shift 2
    if alive "$name"; then echo "bench: $name already running"; return; fi
    (cd "$dir" && exec setsid "$@" > "$RUN/$name.log" 2>&1 < /dev/null) &
    echo $! > "$RUN/$name.pid"
    echo "bench: $name pid $(cat "$RUN/$name.pid")"
}
free() {    # refuse a port someone else holds
    for p in "$@"; do
        if [ -n "$(ss -ltnH "sport = :$p")" ]; then
            echo "bench: port $p is taken" >&2; exit 1
        fi
    done
}
server() {  # name, source dir, port
    local name=$1 src=$2 port=$3
    [ -x "$RUN/bin/$name" ] || (cd "$src" && go build -o "$RUN/bin/$name" .)
    alive "$name" || free "$port"
    start "$name" "$src" env -u GO_PROD PORT="$port" "$RUN/bin/$name"
}

case "${1:-}" in
up)
    if ! alive fnpc; then
        free "$BOIP_PORT" "$WEB_PORT"
        # every tour starts from the book's own settings: the three stock
        # hosts, a clean memory card
        cp "$FNPC_DIR/fnconfig.book.ini" "$FNPC_DIR/fnconfig.ini"
        find "$FNPC_DIR/SD" -maxdepth 1 -type f -delete
    fi
    start fnpc "$FNPC_DIR" ./run-fujinet -u "http://127.0.0.1:$WEB_PORT" -c fnconfig.ini -s SD
    if [ "${2:-}" = games ]; then
        server fcsserver "$GS/5cardstud/server" "$FCS_PORT"
        server thserver "$GS/texasholdem/server" "$TH_PORT"
        server bsserver "$GS/battleship" "$BS_PORT"
        server fzserver "$GS/fujitzee/server" "$FZ_PORT"
        server fkserver "$GS/fujirkle/server" "$FK_PORT"
    fi
    for _ in $(seq 50); do
        [ -n "$(ss -ltnH "sport = :$BOIP_PORT")" ] && break
        sleep 0.2
    done
    [ -n "$(ss -ltnH "sport = :$BOIP_PORT")" ] || { echo "bench: fujinet-pc never listened on $BOIP_PORT" >&2; exit 1; }
    echo "bench: up (BoIP $BOIP_PORT, web $WEB_PORT)" ;;
down)
    for f in "$RUN"/*.pid; do
        [ -e "$f" ] || continue
        kill -- -"$(cat "$f")" 2>/dev/null || kill "$(cat "$f")" 2>/dev/null || true
        rm -f "$f"
    done
    echo "bench: down" ;;
restart)    # one game server, with fresh tables
    f="$RUN/$2.pid"
    [ -f "$f" ] && { kill -- -"$(cat "$f")" 2>/dev/null || kill "$(cat "$f")" 2>/dev/null; rm -f "$f"; sleep 1; }
    case $2 in
        fcsserver) server fcsserver "$GS/5cardstud/server" "$FCS_PORT" ;;
        thserver) server thserver "$GS/texasholdem/server" "$TH_PORT" ;;
        bsserver) server bsserver "$GS/battleship" "$BS_PORT" ;;
        fzserver) server fzserver "$GS/fujitzee/server" "$FZ_PORT" ;;
        fkserver) server fkserver "$GS/fujirkle/server" "$FK_PORT" ;;
    esac
    sleep 1 ;;
*)  echo "usage: emu/bench.sh up|down [games] | restart <server>" >&2; exit 2 ;;
esac
