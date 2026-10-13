#!/usr/bin/env python3
"""tap.py LISTEN_PORT FUJINET_PORT LOG.jsonl

A logging bridge between FujiNet Go H89's card and a standalone fujinet-pc.
The emulated card dials LISTEN_PORT (11512); tap.py accepts it, connects to
the fujinet-pc BoIP port, passes every byte both ways unchanged, and writes
each SLIP frame it sees to LOG as a JSON line:

    {"t": seconds, "dir": "h89" | "fn", "hex": "C0 70 E8 ... C0"}

"h89" is a request (H89 -> FujiNet), "fn" a reply. Bytes outside a frame
(the modem's unframed output) are logged as {"dir": "fn", "raw": "..."}.
The book's byte strips for the H89 programs, and xcheck.py, read this log.
"""
import json
import socket
import sys
import threading
import time

lport, fport, logpath = int(sys.argv[1]), int(sys.argv[2]), sys.argv[3]
log = open(logpath, "a", buffering=1)
lock = threading.Lock()
T0 = time.time()


def emit(rec):
    rec["t"] = round(time.time() - T0, 3)
    with lock:
        log.write(json.dumps(rec) + "\n")


def pump(src, dst, who):
    buf = bytearray()
    inframe = False
    while True:
        try:
            d = src.recv(4096)
        except OSError:
            d = b""
        if not d:
            break
        try:
            dst.sendall(d)
        except OSError:
            break
        for b in d:
            if b == 0xC0:
                if inframe and len(buf) > 0:
                    emit({"dir": who, "hex": " ".join("%02X" % x for x in [0xC0] + list(buf) + [0xC0])})
                    buf.clear()
                    inframe = False         # every sender opens a frame with its own END
                elif buf:
                    emit({"dir": who, "raw": " ".join("%02X" % x for x in buf)})
                    buf.clear()
                    inframe = True
                else:
                    inframe = True
            else:
                buf.append(b)
                if not inframe and len(buf) >= 64:
                    emit({"dir": who, "raw": " ".join("%02X" % x for x in buf)})
                    buf.clear()
        if not inframe and buf:             # bytes between frames: log them as they come
            emit({"dir": who, "raw": " ".join("%02X" % x for x in buf)})
            buf.clear()
    if buf:
        emit({"dir": who, "raw": " ".join("%02X" % x for x in buf)})
    for s in (src, dst):
        try:
            s.shutdown(socket.SHUT_RDWR)
        except OSError:
            pass


srv = socket.socket()
srv.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
srv.bind(("127.0.0.1", lport))
srv.listen(4)
print("tap: listening on", lport, "->", fport, flush=True)
while True:
    card, _ = srv.accept()
    for _ in range(100):
        try:
            fn = socket.create_connection(("127.0.0.1", fport))
            break
        except OSError:
            time.sleep(0.1)
    else:
        card.close()
        continue
    emit({"dir": "tap", "event": "connect"})
    threading.Thread(target=pump, args=(card, fn, "h89"), daemon=True).start()
    threading.Thread(target=pump, args=(fn, card, "fn"), daemon=True).start()
