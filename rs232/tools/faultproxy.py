#!/usr/bin/env python3
"""faultproxy.py <sim-port> <fujinet-port> [every]
A bridge like socat, but it damages every Nth reply frame from the
FujiNet (flips a byte in the middle), to exercise a client's retry and
RESEND logic.  Prints what it did."""
import socket, sys, threading, time
sp, fp = int(sys.argv[1]), int(sys.argv[2])
every = int(sys.argv[3]) if len(sys.argv) > 3 else 3
for i in range(100):
    try:
        a = socket.create_connection(("127.0.0.1", sp)); break
    except OSError:
        time.sleep(0.1)
b = socket.create_connection(("127.0.0.1", fp))
def up():
    while True:
        d = a.recv(4096)
        if not d: break
        b.sendall(d)
threading.Thread(target=up, daemon=True).start()
buf, n = bytearray(), 0
while True:
    d = b.recv(4096)
    if not d: break
    buf += d
    while True:
        try:
            s = buf.index(0xC0); e = buf.index(0xC0, s + 1)
        except ValueError:
            break
        frame = bytearray(buf[s:e + 1]); del buf[:e + 1]
        n += 1
        if n % every == 0 and len(frame) > 8:
            frame[len(frame) // 2] ^= 0x55
            print("damaged reply", n, flush=True)
        a.sendall(frame)
