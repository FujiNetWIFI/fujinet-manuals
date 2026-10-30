#!/usr/bin/env bash
# ports.sh -- refuse to start the bench on a port something else holds, or
# one another rig's config names.
set -uo pipefail
cd "$(dirname "$0")"
. ./ports.env
bad=0
for v in BOIP_PORT WEB_PORT HTTP_PORT NC_PORT BS_PORT FCS_PORT; do
    p=${!v}
    if [ -n "$(ss -ltnH "sport = :$p")" ]; then
        # ours, if the pid file says so
        echo "ports.sh: $v $p is in use"; bad=1
    fi
done
for f in "$HOME"/Workspace/fnpc-*/fnconfig.ini; do
    [ "$f" = "$FNPC_DIR/fnconfig.ini" ] && continue
    if awk '/^\[BOIP\]/{b=1;next} /^\[/{b=0} b && /^port=/' "$f" | grep -qx "port=$BOIP_PORT"; then
        echo "ports.sh: BoIP $BOIP_PORT is also named in $f"; bad=1
    fi
done
exit $bad
