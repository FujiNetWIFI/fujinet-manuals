#!/usr/bin/env python3
"""examples.py [port] -- capture every example exchange printed in the
manual from a running fujinet-pc (RS-232 build, BoIP port, default 1985)
and write examples.json beside manual.typ.

Each example is sent for real and the reply recorded byte for byte.  A
few commands are not sent (they reboot the adapter, rewrite its boot
slot, or need a cartridge on the far end); for those only the request
is computed and the entry is marked "sent": false.

The fujinet-pc SD directory must hold test/disk.img and test/readme.txt
(see README.md); local helper servers for the TCP-server, UDP and HTTP
examples are started by this script on 127.0.0.1.
"""
import json, os, socket, sys, threading, time, http.server
from fujibus import Bus, encode, annotate, decode, slip, raw_packet

PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 1985
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "examples.json")
pad = lambda s, n: s + b"\0" * (n - len(s))
U8 = lambda v: (1, v)
U16 = lambda v: (2, v)
U32 = lambda v: (4, v)

bus = Bus(port=PORT, timeout=20)
ex = {}


def frame_list(f):
    return [["%02X" % b, r] for b, r in annotate(f)]


def run(key, dev, cmd, params=(), payload=b"", send=True, reply=None,
        note=""):
    req = encode(dev, cmd, params, payload)
    rec = {"dev": dev, "cmd": cmd, "req": frame_list(req), "sent": send,
           "note": note, "paylen": len(payload)}
    if send:
        bus.send(req)
        rep = bus.recv_frame()
        d, c, p, pl = decode(rep)
        rec["rep"] = frame_list(rep)
        rec["ack"] = (c == 0x06)
        rec["replen"] = len(pl)
        rec["text"] = pl[:80].decode("latin1")
        ex[key] = rec
        return pl
    if reply is not None:                 # computed reply (not sent)
        rep = slip(raw_packet(dev, reply[0], (), reply[1]))
        rec["rep"] = frame_list(rep)
        rec["ack"] = reply[0] == 0x06
        rec["replen"] = len(reply[1])
    ex[key] = rec
    return None


def status(unit):
    return run("_st", unit, 0x53)


# --- helper servers --------------------------------------------------
def tcp_echo(port, banner=b"HELLO FROM 127.0.0.1\r\n"):
    s = socket.socket(); s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    s.bind(("127.0.0.1", port)); s.listen(1)
    def loop():
        c, _ = s.accept(); c.sendall(banner)
        while True:
            d = c.recv(100)
            if not d: break
            c.sendall(d.upper())
    threading.Thread(target=loop, daemon=True).start()


class H(http.server.BaseHTTPRequestHandler):
    def log_message(self, *a): pass
    def do_GET(self):
        body = b'{"name":"FujiNet","bus":"RS-232","ports":[1985,6502]}'
        self.send_response(200); self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body))); self.end_headers()
        self.wfile.write(body)
    def do_POST(self):
        n = int(self.headers.get("Content-Length", 0)); data = self.rfile.read(n)
        body = b"GOT " + data
        self.send_response(200); self.send_header("Content-Length", str(len(body)))
        self.end_headers(); self.wfile.write(body)


def http_server(port):
    srv = http.server.HTTPServer(("127.0.0.1", port), H)
    threading.Thread(target=srv.serve_forever, daemon=True).start()


tcp_echo(7801)
http_server(7802)
time.sleep(0.2)

# --- a known starting state, so every capture is the same ------------
HOSTS = [b"SD", b"fujinet.online", b"apps.irata.online", b"fujinet.diller.org",
         b"FujiNet.Atari8bit.net", b"atarionline.eu", b"fujinet.pl", b"ec.tnfs.io"]
bus.call(0x70, 0xF3, (), b"".join(pad(h, 32) for h in HOSTS))
for slot in range(8):
    bus.call(0x70, 0xE9, [U8(slot)])
    bus.call(0x70, 0xE2, [U8(slot), U8(0), U8(1)], pad(b"", 256))
bus.call(0x70, 0xE2, [U8(0), U8(7), U8(1)], pad(b"msdos/lobby.img", 256))

# ===================================================================
# Chapter 3: framing
# ===================================================================
run("first", 0x70, 0xFA)
run("esc", 0x71, 0x57, [U16(2)], bytes([0xC0, 0xDB]), send=False,
    reply=(0x06, b""), note="illustrative: shows both SLIP escapes")
run("multi", 0x70, 0xE2, [U8(1), U8(0), U8(1)], pad(b"/test/disk.img", 256))
run("descr", 0x31, 0x52, [U32(0)], send=False, reply=None)
run("unknown_dev", 0x60, 0x00)

# ===================================================================
# Fuji device 70h
# ===================================================================
F = 0x70
run("fuji.reset", F, 0xFF, send=False, note="reboots; no reply")
run("fuji.get_ssid", F, 0xFE)
run("fuji.scan", F, 0xFD)
run("fuji.scan_result", F, 0xFC, [U8(0)])
run("fuji.set_ssid", F, 0xFB, (), pad(b"Dummy Cafe", 33) + pad(b"", 64))
run("fuji.wifi_status", F, 0xFA)
run("fuji.wifi_enabled", F, 0xEA)
run("fuji.adapter", F, 0xE8)
run("fuji.adapter_ext", F, 0xC4)
hosts = run("fuji.read_hosts", F, 0xF4)
run("fuji.write_hosts", F, 0xF3, (), hosts)
run("fuji.mount_host", F, 0xF9, [U8(0)])
run("fuji.open_dir", F, 0xF7, [U8(0)], pad(b"/test/", 256))
run("fuji.read_dir", F, 0xF6, [U8(36), U8(0)])
run("fuji.dir_pos", F, 0xE5)
run("fuji.set_dir_pos", F, 0xE4, [U16(0)])
run("fuji.read_dir_ext", F, 0xF6, [U8(48), U8(0x80)])
run("fuji.read_dir_end", F, 0xF6, [U8(36), U8(0)])
run("fuji.read_dir_end", F, 0xF6, [U8(36), U8(0)])
run("fuji.close_dir", F, 0xF5)
run("fuji.open_dir_pat", F, 0xF7, [U8(0)], pad(b"/test\0*.img", 256))
run("fuji.close_dir", F, 0xF5)
run("fuji.set_fullpath", F, 0xE2, [U8(1), U8(0), U8(1)], pad(b"/test/disk.img", 256))
run("fuji.get_fullpath", F, 0xDA, [U8(1)])
run("fuji.mount_image", F, 0xF8, [U8(1), U8(1)])
slots = run("fuji.read_slots", F, 0xF2)
run("fuji.write_slots", F, 0xF1, (), slots)
run("fuji.unmount_image", F, 0xE9, [U8(1)])
run("fuji.unmount_host_sd", F, 0xE6, [U8(0)])
run("_", F, 0xF9, [U8(7)])
run("fuji.unmount_host", F, 0xE6, [U8(7)])
run("fuji.set_prefix", F, 0xE1, [U8(0)], pad(b"/test", 256))
run("fuji.get_prefix", F, 0xE0, [U8(0)])
run("fuji.set_prefix_clr", F, 0xE1, [U8(0)], pad(b"", 256))
run("fuji.config_boot", F, 0xD9, [U8(1)])
try:
    os.remove(os.path.join(os.environ.get("FNSD", "."), "test", "copy.txt"))
except OSError:
    pass
run("fuji.copy_file", F, 0xD8, [U8(1), U8(1)], b"/test/readme.txt|/test/copy.txt\0")
run("fuji.mount_all", F, 0xD7)
run("fuji.boot_mode", F, 0xD6, [U8(0)], send=False, reply=(0x06, b""),
    note="not sent: it remounts disk slot 1")
run("fuji.new_disk", F, 0xE7, (),
    (720).to_bytes(2, "little") + (512).to_bytes(2, "little") + bytes([0, 2])
    + pad(b"/test/blank.img", 256))
run("fuji.random", F, 0xD3)
run("fuji.guid", F, 0xBB)
run("fuji.status", F, 0x53)
run("fuji.device_ready", F, 0x00)
run("fuji.bad_command", F, 0x01)
# app keys: creator 1234h, app 01, key 01
run("fuji.appkey_open_w", F, 0xDC, (), bytes([0x34, 0x12, 0x01, 0x01, 0x01, 0x00]))
run("fuji.appkey_write", F, 0xDE, (), b"HIGH SCORE 31337")
run("fuji.appkey_open_r", F, 0xDC, (), bytes([0x34, 0x12, 0x01, 0x01, 0x00, 0x00]))
run("fuji.appkey_read", F, 0xDD)
run("fuji.appkey_close", F, 0xDB)
# Base64
run("fuji.b64e_in", F, 0xD0, [U16(7)], b"FujiNet")
run("fuji.b64e_compute", F, 0xCF)
run("fuji.b64e_len", F, 0xCE)
run("fuji.b64e_out", F, 0xCD, [U16(12)])
run("fuji.b64d_in", F, 0xCC, [U16(12)], b"RnVqaU5ldA==")
run("fuji.b64d_compute", F, 0xCB)
run("fuji.b64d_len", F, 0xCA)
run("fuji.b64d_out", F, 0xC9, [U16(7)])
# Hash
run("fuji.hash_clear", F, 0xC2)
run("fuji.hash_in", F, 0xC8, [U16(3)], b"abc")
run("fuji.hash_compute", F, 0xC7, [U8(1)])
run("fuji.hash_len", F, 0xC6, [U8(1)])
run("fuji.hash_out", F, 0xC5, [U8(1)])
run("fuji.hash_in", F, 0xC8, [U16(3)], b"abc")
run("fuji.hash_compute_nc", F, 0xC3, [U8(0)])
run("fuji.hash_len_bin", F, 0xC6, [U8(0)])
run("fuji.hash_out_bin", F, 0xC5, [U8(0)])
# QR
url = b"https://fujinet.online/"
run("fuji.qr_in", F, 0xBC, [U16(len(url))], url)
run("fuji.qr_encode", F, 0xBD, [U8(3), U8(0), U8(0)])
qrlen = run("fuji.qr_len", F, 0xBE, [U8(0)])
run("fuji.qr_out", F, 0xBF, [U16(int.from_bytes(qrlen, "little"))])

# ===================================================================
# Disk 31h-38h  (disk.img in disk slot 2 = device 32h, read/write)
# ===================================================================
run("_", F, 0xE2, [U8(1), U8(0), U8(2)], pad(b"/test/disk.img", 256))
run("_", F, 0xF8, [U8(1), U8(2)])
D = 0x32
run("disk.read", D, 0x52, [U32(0)])
run("disk.write", D, 0x57, [U32(1)], bytes(range(256)) * 2)
run("disk.put", D, 0x50, [U32(1)], bytes(range(256)) * 2)
run("disk.read_far", D, 0x52, [U32(100000)])
run("disk.status", D, 0x53, [U32(0)], note="mapped to WRITE; no payload, so NAK")
run("disk.format", D, 0x21)
run("disk.percom_r", D, 0x4E)
run("disk.percom_w", D, 0x4F, (), bytes(12))
run("disk.empty", 0x38, 0x52, [U32(0)])
run("_", F, 0xE9, [U8(1)])

# ===================================================================
# Network 71h-78h
# ===================================================================
N = 0x71
run("net.open_http", N, 0x4F, [U8(12), U8(0)], b"N:HTTP://127.0.0.1:7802/fuji.json\0")
time.sleep(0.3)
run("net.status", N, 0x53)
run("net.set_parser", N, 0xFC, [U8(0), U8(1)])
run("net.parse", N, 0x50)
run("net.query", N, 0x51, (), b"/name")
run("net.status_q", N, 0x53)
run("net.read_q", N, 0x52, [U16(8)])
run("net.query2", N, 0x51, (), b"/ports/0")
run("net.status_q2", N, 0x53)
run("net.read_q2", N, 0x52, [U16(5)])
run("net.set_param_eol", N, 0xFB, [U8(1), U8(0)])
run("net.close", N, 0x43)
run("net.open_get", N, 0x4F, [U8(12), U8(0)], b"N:HTTP://127.0.0.1:7802/fuji.json\0")
time.sleep(0.3)
st = run("net.status_get", N, 0x53)
run("net.read", N, 0x52, [U16(st[0] | st[1] << 8)])
run("net.status_eof", N, 0x53)
run("net.tell", N, 0x26)
run("net.seek", N, 0x25, [U32(10)])
run("_", N, 0x43)
# POST
run("net.open_post", N, 0x4F, [U8(13), U8(0)], b"N:HTTP://127.0.0.1:7802/score\0")
run("net.http_mode_post", N, 0x4D, [U8(0), U8(4)])
run("net.write_post", N, 0x57, [U16(9)], b"ALTAIR=42")
run("net.http_mode_body", N, 0x4D, [U8(0), U8(0)])
time.sleep(0.3)
st = run("net.status_post", N, 0x53)
run("net.read_post", N, 0x52, [U16(st[0] | st[1] << 8)])
run("_", N, 0x43)
# TCP client
run("net.open_tcp", N, 0x4F, [U8(12), U8(0)], b"N:TCP://127.0.0.1:7801/\0")
time.sleep(0.3)
st = run("net.status_tcp", N, 0x53)
run("net.read_tcp", N, 0x52, [U16(st[0] | st[1] << 8)])
run("net.write_tcp", N, 0x57, [U16(4)], b"hi\r\n")
time.sleep(0.3)
run("_", N, 0x43)
# TCP server on unit 2
N2 = 0x72
run("net.open_listen", N2, 0x4F, [U8(12), U8(0)], b"N:TCP://:7803/\0")
c = socket.create_connection(("127.0.0.1", 7803)); time.sleep(0.5)
run("net.status_listen", N2, 0x53)
run("net.accept", N2, 0x41)
c.sendall(b"PING\r\n"); time.sleep(0.3)
st = run("net.status_acc", N2, 0x53)
run("net.read_acc", N2, 0x52, [U16(st[0] | st[1] << 8)])
run("net.close_client", N2, 0x63)
c.close()
run("_", N2, 0x43)
# UDP on unit 3: listen on 7804, answer whoever wrote
N3 = 0x73
run("net.open_udp", N3, 0x4F, [U8(12), U8(0)], b"N:UDP://:7804/\0")
u = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
u.bind(("127.0.0.1", 7805))
u.sendto(b"PING", ("127.0.0.1", 7804)); time.sleep(0.4)
run("net.status_udp", N3, 0x53)
run("net.read_udp", N3, 0x52, [U16(64)])
run("net.get_remote", N3, 0x72)
run("net.set_dest", N3, 0x44, (), b"N:127.0.0.1:7805\0")
run("net.write_udp", N3, 0x57, [U16(4)], b"PONG")
u.settimeout(2); u.recvfrom(100)
run("_", N3, 0x43)
# filesystem ops on SD
N4 = 0x74
run("net.open_dir", N4, 0x4F, [U8(6), U8(0)], b"N:SD:/test/\0")
time.sleep(0.2)
st = run("net.status_dir", N4, 0x53)
run("net.read_dir", N4, 0x52, [U16(min(200, st[0] | st[1] << 8))])
run("_", N4, 0x43)
run("net.open_w", N4, 0x4F, [U8(8), U8(0)], b"N:SD:/test/note.txt\0")
run("net.write_file", N4, 0x57, [U16(6)], b"HELLO\n")
run("_", N4, 0x43)
run("net.rename", N4, 0x20, [U8(0), U8(0)], b"N:SD:/test/note.txt,memo.txt\0")
run("net.delete", N4, 0x21, [U8(0), U8(0)], b"N:SD:/test/memo.txt\0")
run("net.mkdir", N4, 0x2A, [U8(0), U8(0)], b"N:SD:/test/sub\0")
run("net.rmdir", N4, 0x2B, [U8(0), U8(0)], b"N:SD:/test/sub\0")
run("net.chdir", N4, 0x2C, (), b"N:TNFS://ec.tnfs.io/msdos/\0")
run("net.getcwd", N4, 0x30)
run("net.username", N4, 0xFD, (), b"altair\0")
run("net.password", N4, 0xFE, (), b"8800\0")
run("net.translation", N4, 0x54, [U8(0), U8(3)])
run("net.set_eol", N4, 0x4C, (), b"\r\n")
run("net.int_rate", N4, 0x5A, [U8(100)])
run("net.open_bad", N4, 0x4F, [U8(4), U8(0)], b"N:HTTP://127.0.0.1:1/\0")
run("net.status_bad", N4, 0x53)
run("net.bad_command", N4, 0x45)

# ===================================================================
# Clock 45h
# ===================================================================
C = 0x45
run("clock.gettime", C, 0x93, [U8(0)])
run("clock.gettztime", C, 0x9A, [U8(0)])
run("clock.simple", C, 0x54, [U8(0)])
run("clock.hundredths", C, 0x4D, [U8(0)])
run("clock.prodos", C, 0x50, [U8(0)])
run("clock.sos", C, 0x53, [U8(0)])
run("clock.iso_local", C, 0x49, [U8(0)])
run("clock.iso_utc", C, 0x5A, [U8(0)])
run("clock.general", C, 0x47, [U8(0)])
run("clock.tzlen", C, 0x4C, [U8(0)])
run("clock.settz", C, 0x99, [U8(0)], b"CST6CDT,M3.2.0,M11.1.0\0")
run("clock.iso_alt", C, 0x49, [U8(1)])
run("clock.settz_alt", C, 0x74, [U8(0)], b"UTC0\0", send=False, reply=(0x06, b""),
    note="not sent: it changes the saved time zone")
run("clock.atari", C, 0x41, [U8(0)])

# ===================================================================
# Printer 40h, modem 50h, RESEND
# ===================================================================
run("printer.write", 0x40, 0x57, (), b"HELLO FROM THE ALTAIR\r")
run("printer.status", 0x40, 0x53, [U8(0)])
prev = run("resend.before", F, 0xFA)
run("resend", F, 0x05, send=False, reply=(0x06, prev),
    note="answered by fujinet-pc rs232-resend; current firmware NAKs it")
run("resend.nak", F, 0x05)

json.dump(ex, open(OUT, "w"), indent=0)
print("wrote", len(ex), "examples to", os.path.abspath(OUT))
