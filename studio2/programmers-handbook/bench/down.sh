#!/usr/bin/env bash
# down.sh -- stop what up.sh started, by pid (and its process group).
set -uo pipefail
cd "$(dirname "$0")/.."
RUN=$PWD/bench/run
for f in "$RUN"/*.pid; do
    [ -f "$f" ] || continue
    pid=$(cat "$f")
    if kill -0 "$pid" 2>/dev/null; then
        kill -TERM -- "-$pid" 2>/dev/null || kill -TERM "$pid"
        echo "down.sh: stopped $(basename "$f" .pid) ($pid)"
    fi
    rm -f "$f"
done
