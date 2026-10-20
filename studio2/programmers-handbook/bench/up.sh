#!/usr/bin/env bash
# up.sh -- start the book's bench: fujinet-pc (BoIP), the HTTP fixture and
# the netcat line server; with "games", the two game servers as well.
# Every process is remembered in bench/run/*.pid; down.sh stops them.
set -euo pipefail
cd "$(dirname "$0")/.."
BOOK=$PWD
. bench/ports.env
RUN=$BOOK/bench/run
mkdir -p "$RUN"

alive() { [ -f "$RUN/$1.pid" ] && kill -0 "$(cat "$RUN/$1.pid")" 2>/dev/null; }
start() {   # name, dir, command...
    local name=$1 dir=$2; shift 2
    if alive "$name"; then echo "up.sh: $name already running"; return; fi
    (cd "$dir" && exec setsid "$@" > "$RUN/$name.log" 2>&1 < /dev/null) &
    echo $! > "$RUN/$name.pid"
    echo "up.sh: $name pid $(cat "$RUN/$name.pid")"
}

alive fnpc || bench/ports.sh
start fnpc "$FNPC_DIR" ./run-fujinet -u "http://127.0.0.1:$WEB_PORT" -c fnconfig.ini -s SD
start http "$BOOK/listings/fixtures" python3 -m http.server "$HTTP_PORT" --bind 127.0.0.1
start ncserver "$BOOK" python3 -I listings/fixtures/ncserver.py "$NC_PORT" "$RUN/ncserver.log.txt"
if [ "${1:-}" = games ]; then
    start bsserver "$HOME/Workspace/servers/fujinet-game-system/battleship" env -u GO_PROD PORT="$BS_PORT" "$RUN/bin/bsserver"
    start fcsserver "$HOME/Workspace/servers/fujinet-game-system/5cardstud/server" env -u GO_PROD PORT="$FCS_PORT" "$RUN/bin/fcsserver"
fi
# wait for the BoIP listener
for _ in $(seq 50); do
    [ -n "$(ss -ltnH "sport = :$BOIP_PORT")" ] && break
    sleep 0.2
done
[ -n "$(ss -ltnH "sport = :$BOIP_PORT")" ] || { echo "up.sh: fujinet-pc never listened on $BOIP_PORT" >&2; exit 1; }
echo "up.sh: bench up (BoIP $BOIP_PORT, web $WEB_PORT, http $HTTP_PORT, nc $NC_PORT)"
