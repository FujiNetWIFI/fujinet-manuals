#!/usr/bin/env python3
"""Drive the simulated terminal (88-2SIO port A on TCP 2300).
   term.py [--keys "text with \\r"] [--wait seconds] [--log file]
Keys are sent one by one; "{N}" in the key string pauses N seconds."""
import socket, sys, time, argparse, re
ap = argparse.ArgumentParser()
ap.add_argument("--keys", default="")
ap.add_argument("--wait", type=float, default=5)
ap.add_argument("--port", type=int, default=2300)
ap.add_argument("--quiet", type=float, default=0, help="stop after this many idle seconds")
a = ap.parse_args()
s = None
for i in range(100):
    try:
        s = socket.create_connection(("127.0.0.1", a.port)); break
    except OSError as e:
        err = e; time.sleep(0.1)
if s is None:
    sys.exit("term.py: cannot reach the simulated terminal: %s" % err)
s.settimeout(0.05)
out = bytearray()
def pump(t):
    end = time.time() + t
    while time.time() < end:
        try:
            d = s.recv(4096)
            if not d: return False
            out.extend(d); sys.stdout.write(d.decode("latin1")); sys.stdout.flush()
        except socket.timeout:
            pass
    return True
keys = a.keys.encode().decode("unicode_escape")
pump(0.5)
for tok in re.split(r"(\{[0-9.]+\})", keys):
    if tok.startswith("{"):
        pump(float(tok[1:-1])); continue
    for ch in tok:
        s.sendall(ch.encode("latin1")); pump(0.03)
pump(a.wait)
