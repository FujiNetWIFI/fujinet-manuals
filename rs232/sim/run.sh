#!/bin/sh
# run.sh <program.bin> [term.py args...]
# Starts AltairZ80, bridges its port B to fujinet-pc's BoIP port
# (default 1985, override with FNPORT=), and drives port A (the
# terminal) with term.py.  fujinet-pc must already be running.
# Fresh TCP ports each run: simh cannot rebind a port in TIME_WAIT.
cd "$(dirname "$0")"
BIN=$1; shift
TP=$((20000 + $$ % 20000)); FP=$((TP + 1))
~/Workspace/simh/BIN/altairz80 altair.ini "$BIN" $TP $FP > sim.log 2>&1 &
SIM=$!
sleep 1
if [ -n "$FAULT" ]; then        # FAULT=n: damage every nth reply
  python3 ../tools/faultproxy.py $FP ${FNPORT:-1985} $FAULT >socat.log 2>&1 &
else
  ( until socat TCP:127.0.0.1:$FP TCP:127.0.0.1:${FNPORT:-1985}; do
      sleep 0.2; done ) 2>socat.log &
fi
BR=$!
python3 term.py --port $TP "$@"
kill $SIM $BR 2>/dev/null
pkill -P $BR 2>/dev/null
wait 2>/dev/null
