#!/usr/bin/env python3
"""helpers.py LOG -- the little servers the book's programs talk to.

Started by rig_start beside fujinet-pc, so every example that reaches out to
the network reaches something local, answers the same way every time, and
leaves a record in LOG (one JSON line per event):

  7801  TCP   a test board: a greeting, then keys are echoed as they come
              and every line comes back in capitals; "BYE" (or 30 s of
              quiet) and it hangs up
  7802  HTTP  GET    (paths in any case) /hello.txt, /data.bin (3000 bytes: byte n = n mod 251),
                     /fuji.json, /iss-now.json, /astros.json (canned replies
                     in the shape of api.open-notify.org's)
              POST, PUT: logs the method and body, answers "GOT n BYTES"
              DELETE:    logs, answers "DELETED"
              every request's headers are logged
  7803        (FujiNet listens here) every second, try to connect and send
              "PING", read what comes back, hang up
  7804        (FujiNet's UDP port) a "PING" datagram every second from 7805;
              whatever comes back to 7805 is logged
"""
import http.server
import json
import socket
import sys
import threading
import time

LOG = open(sys.argv[1] if len(sys.argv) > 1 else "/dev/stdout", "a", buffering=1)
lock = threading.Lock()
T0 = time.time()


def log(**kw):
    kw["t"] = round(time.time() - T0, 3)
    with lock:
        LOG.write(json.dumps(kw) + "\n")


ISS_NOW = {"message": "success", "timestamp": 1760270400,
           "iss_position": {"latitude": "29.7604", "longitude": "-95.3698"}}
ASTROS = {"message": "success", "number": 7, "people": [
    {"craft": "ISS", "name": "Oleg Kononenko"},
    {"craft": "ISS", "name": "Nikolai Chub"},
    {"craft": "ISS", "name": "Tracy Caldwell Dyson"},
    {"craft": "ISS", "name": "Matthew Dominick"},
    {"craft": "ISS", "name": "Michael Barratt"},
    {"craft": "ISS", "name": "Jeanette Epps"},
    {"craft": "Tiangong", "name": "Li Guangsu"}]}
FUJI = {"name": "FujiNet", "machine": "H89", "ports": [208, 209, 210, 211]}
FILES = {
    "/hello.txt": (b"Hello from the test server.\r\nThis is the second line.\r\n", "text/plain"),
    "/data.bin": (bytes(i % 251 for i in range(3000)), "application/octet-stream"),
    "/fuji.json": (json.dumps(FUJI).encode(), "application/json"),
    "/iss-now.json": (json.dumps(ISS_NOW).encode(), "application/json"),
    "/astros.json": (json.dumps(ASTROS).encode(), "application/json"),
}


# ---- 7801: the test board -------------------------------------------------
def board():
    s = socket.socket()
    s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    s.bind(("127.0.0.1", 7801))
    s.listen(4)
    while True:
        c, a = s.accept()
        threading.Thread(target=board_conn, args=(c,), daemon=True).start()


def board_conn(c):
    log(srv="board", ev="connect")
    c.settimeout(30)
    c.sendall(b"\r\nFujiNet test board, 127.0.0.1 port 7801.\r\n"
              b"Type a line and it comes back in capitals; BYE hangs up.\r\n\r\n> ")
    line = b""
    try:
        while True:
            d = c.recv(256)
            if not d:
                break
            log(srv="board", ev="recv", hex=d.hex(" "))
            for ch in d:
                if ch in (13, 10):
                    if line.strip().upper() == b"BYE":
                        c.sendall(b"\r\nGoodbye.\r\n")
                        log(srv="board", ev="bye")
                        c.close()
                        return
                    c.sendall(b"\r\n" + line.upper() + b"\r\n> ")
                    line = b""
                elif ch in (8, 127):
                    if line:
                        line = line[:-1]
                        c.sendall(b"\b \b")
                elif ch >= 32:
                    line += bytes([ch])
                    c.sendall(bytes([ch]))        # echoed, as a board does
    except OSError:
        pass
    log(srv="board", ev="close")
    c.close()


# ---- 7802: HTTP -------------------------------------------------------------
class H(http.server.BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def log_message(self, *a):
        pass

    def body(self):
        n = int(self.headers.get("Content-Length", 0) or 0)
        if n:
            return self.rfile.read(n)
        if self.headers.get("Transfer-Encoding", "").lower() == "chunked":
            out = b""
            while True:
                size = int(self.rfile.readline().strip() or b"0", 16)
                if size == 0:
                    self.rfile.readline()
                    break
                out += self.rfile.read(size)
                self.rfile.readline()
            return out
        return b""

    def answer(self, code, data, ctype="text/plain"):
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(data)))
        self.send_header("X-Test-Server", "H89 book")
        self.end_headers()
        self.wfile.write(data)

    def note(self, data=b""):
        log(srv="http", method=self.command, path=self.path,
            headers=dict(self.headers.items()), body=data[:600].decode("latin-1"), bodylen=len(data))

    def do_GET(self):
        self.note()
        # paths in any case: HDOS and CP/M capitalise a typed command line
        f = FILES.get(self.path.split("?")[0].lower())
        if f:
            self.answer(200, f[0], f[1])
        else:
            self.answer(404, b"Not found\r\n")

    def do_POST(self):
        d = self.body()
        self.note(d)
        self.answer(200, b"GOT %d BYTES\r\n" % len(d))

    do_PUT = do_POST

    def do_DELETE(self):
        self.note()
        self.answer(200, b"DELETED\r\n")


def http_server():
    http.server.ThreadingHTTPServer.allow_reuse_address = True
    http.server.ThreadingHTTPServer(("127.0.0.1", 7802), H).serve_forever()


# ---- 7803: a client for FujiNet's TCP server ---------------------------------
def tcp_client():
    while True:
        time.sleep(1)
        try:
            c = socket.create_connection(("127.0.0.1", 7803), timeout=1)
        except OSError:
            continue
        log(srv="client", ev="connect")
        try:
            time.sleep(1.5)
            c.sendall(b"PING\r\n")
            log(srv="client", ev="sent", data="PING\\r\\n")
            c.settimeout(6)
            d = c.recv(256)
            log(srv="client", ev="recv", hex=d.hex(" "))
        except OSError as e:
            log(srv="client", ev="error", err=str(e))
        c.close()
        time.sleep(4)


# ---- 7804/7805: UDP -----------------------------------------------------------
def udp():
    u = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    u.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    u.bind(("127.0.0.1", 7805))
    u.settimeout(1)
    while True:
        try:
            u.sendto(b"PING", ("127.0.0.1", 7804))
        except OSError:
            pass
        try:
            d, a = u.recvfrom(512)
            log(srv="udp", ev="recv", frm="%s:%d" % a, hex=d.hex(" "))
        except OSError:
            pass


for fn in (board, http_server, tcp_client, udp):
    threading.Thread(target=fn, daemon=True).start()
log(srv="helpers", ev="ready")
while True:
    time.sleep(3600)
