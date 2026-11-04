#!/usr/bin/env bash
# up.sh -- start the book's bench: fujinet-pc (BoIP), the HTTP fixture and
# the netcat line server; with "games", the Battleship and 5 Card Stud
# servers as well (FujiNetWIFI/servers at $SERVERS_REF, archived, so the
# checkout is never touched; GO_PROD unset, so they never tell the public
# lobby). Every process is remembered in bench/run/*.pid; down.sh stops them.
#
# Each start resets fujinet-pc to the book's settings (fnconfig.book.ini)
# and its memory card to listings/fixtures/sd plus the built programs.
set -euo pipefail
cd "$(dirname "$0")/.."
BOOK=$PWD
. bench/ports.env
RUN=$BOOK/bench/run
mkdir -p "$RUN/bin"

alive() { [ -f "$RUN/$1.pid" ] && kill -0 "$(cat "$RUN/$1.pid")" 2>/dev/null; }
start() {   # name, dir, command...
    local name=$1 dir=$2; shift 2
    if alive "$name"; then echo "up.sh: $name already running"; return; fi
    (cd "$dir" && exec setsid "$@" > "$RUN/$name.log" 2>&1 < /dev/null) &
    echo $! > "$RUN/$name.pid"
    echo "up.sh: $name pid $(cat "$RUN/$name.pid")"
}
server() {  # name, dir under fujinet-game-system, port
    local name=$1 src=$RUN/servers/fujinet-game-system/$2 port=$3
    if [ ! -d "$RUN/servers" ]; then
        mkdir -p "$RUN/servers"
        git -C "$HOME/Workspace/servers" archive "$SERVERS_REF" fujinet-game-system \
            | tar -x -C "$RUN/servers"
    fi
    [ -x "$RUN/bin/$name" ] || (cd "$src" && go build -o "$RUN/bin/$name" .)
    start "$name" "$src" env -u GO_PROD PORT="$port" "$RUN/bin/$name"
}

if ! alive fnpc; then
    bench/ports.sh
    cp "$FNPC_DIR/fnconfig.book.ini" "$FNPC_DIR/fnconfig.ini"
    rm -rf "$FNPC_DIR/SD"
    mkdir -p "$FNPC_DIR/SD"
    cp -r listings/fixtures/sd/. "$FNPC_DIR/SD/"
    # the programs the book boots and lists
    for b in listings/asm/build/*.bin; do
        [ -e "$b" ] && cp "$b" "$FNPC_DIR/SD/arcbook/"
    done
fi
start fnpc "$FNPC_DIR" ./run-fujinet -u "http://127.0.0.1:$WEB_PORT" -c fnconfig.ini -s SD
start http "$BOOK/listings/fixtures" python3 -m http.server "$HTTP_PORT" --bind 127.0.0.1
start ncserver "$BOOK" python3 -I listings/fixtures/ncserver.py "$NC_PORT" "$RUN/ncserver.log.txt"
if [ "${1:-}" = games ]; then
    server bsserver battleship "$BS_PORT"
    server fcsserver 5cardstud/server "$FCS_PORT"
fi
for _ in $(seq 50); do
    [ -n "$(ss -ltnH "sport = :$BOIP_PORT")" ] && break
    sleep 0.2
done
[ -n "$(ss -ltnH "sport = :$BOIP_PORT")" ] || { echo "up.sh: fujinet-pc never listened on $BOIP_PORT" >&2; exit 1; }
echo "up.sh: bench up (BoIP $BOIP_PORT, web $WEB_PORT, http $HTTP_PORT, nc $NC_PORT)"
