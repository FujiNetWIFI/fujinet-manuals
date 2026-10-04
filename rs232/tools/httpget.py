#!/usr/bin/env python3
"""Fetch a URL through the FujiNet N: device (OPEN/STATUS/READ/CLOSE)."""
import sys, time
from fujibus import Bus

def get(b, url, unit=0x71, mode=12, verbose=False):
    d, c, pl = b.call(unit, 0x4F, [(1, mode), (1, 0)], url.encode() + b"\0")
    if c != 0x06:
        raise RuntimeError("OPEN NAK")
    out = b""
    while True:
        d, c, st = b.call(unit, 0x53)
        avail, conn, err = st[0] | st[1] << 8, st[2], st[3]
        if verbose: print("status", avail, conn, err)
        if avail:
            d, c, data = b.call(unit, 0x52, [(2, min(avail, 512))])
            out += data
        elif err == 136 or not conn:
            break
        else:
            time.sleep(0.05)
    b.call(unit, 0x43)
    return out

if __name__ == "__main__":
    b = Bus(port=1985)
    r = get(b, sys.argv[1], verbose=True)
    print(len(r)); print(r[:600])
