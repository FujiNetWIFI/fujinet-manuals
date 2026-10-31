#!/usr/bin/env python3
"""List folders on a TNFS server -- read only (MOUNT, OPENDIR, READDIR,
CLOSEDIR, UMOUNT; tnfsd/tnfs-protocol.md).

    python3 tools/tnfsls.py apps.irata.online /Atari_2600 /mule/atari-2600
    python3 tools/tnfsls.py --check apps.irata.online:/Atari_2600/battleship.bin ...

With --check, each host:/path names a file the book mentions; the script
lists its folder and fails if the file is not there.
"""
import socket
import struct
import sys


class Tnfs:
    def __init__(self, host, port=16384, timeout=2.0, tries=5):
        self.addr = (socket.gethostbyname(host), port)
        self.s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        self.s.settimeout(timeout)
        self.tries = tries
        self.sid = 0
        self.seq = 0

    def call(self, cmd, data=b""):
        pkt = struct.pack("<HBB", self.sid, self.seq, cmd) + data
        for _ in range(self.tries):
            self.s.sendto(pkt, self.addr)
            try:
                while True:
                    r, _ = self.s.recvfrom(1024)
                    if r[2] == self.seq and r[3] == cmd:
                        break
            except socket.timeout:
                continue
            self.seq = (self.seq + 1) & 0xFF
            return r
        raise IOError(f"no reply from {self.addr} to command {cmd:#x}")

    def mount(self, path="/"):
        r = self.call(0x00, b"\x02\x01" + path.encode() + b"\0\0\0")
        if r[4] != 0:
            raise IOError(f"MOUNT failed: {r[4]:#x}")
        self.sid = struct.unpack("<H", r[0:2])[0]

    def listdir(self, path):
        r = self.call(0x10, path.encode() + b"\0")
        if r[4] != 0:
            raise IOError(f"OPENDIR {path} failed: {r[4]:#x}")
        h = r[5]
        names = []
        try:
            while True:
                r = self.call(0x11, bytes([h]))
                if r[4] != 0:
                    break
                n = r[5:].split(b"\0")[0].decode("latin-1")
                if n not in (".", ".."):
                    names.append(n)
        finally:
            self.call(0x12, bytes([h]))
        return names

    def umount(self):
        try:
            self.call(0x01)
        except IOError:
            pass


def main(argv):
    check = argv[:1] == ["--check"]
    if check:
        bad = 0
        by_host = {}
        for a in argv[1:]:
            host, path = a.split(":", 1)
            by_host.setdefault(host, []).append(path)
        for host, paths in by_host.items():
            t = Tnfs(host)
            t.mount()
            for p in paths:
                d, f = p.rsplit("/", 1)
                ok = f in t.listdir(d or "/")
                print(("ok      " if ok else "MISSING ") + host + ":" + p)
                bad += not ok
            t.umount()
        return 1 if bad else 0
    host, paths = argv[0], argv[1:] or ["/"]
    t = Tnfs(host)
    t.mount()
    for p in paths:
        print(f"{host}:{p}")
        for n in sorted(t.listdir(p), key=str.lower):
            print("   ", n)
    t.umount()
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
