#!/usr/bin/env python3
"""Minimal FujiBus (FEP-004) client used to verify the manual's byte streams.

    encode(dev, cmd, params=[(size, value), ...], payload=b"") -> bytes
    decode(frame) -> (dev, cmd, params, payload)
    Bus(host, port).call(dev, cmd, params, payload) -> (dev, cmd, payload)

Algorithms transcribed from fujinet-firmware lib/bus/rs232/FujiBusPacket.cpp.
"""
import socket, struct, sys, time

END, ESC, ESC_END, ESC_ESC = 0xC0, 0xDB, 0xDC, 0xDD
FIELD_SIZE = [0, 1, 1, 1, 1, 2, 2, 4]
NUM_FIELDS = [0, 1, 2, 3, 4, 1, 2, 1]


def checksum(buf):
    chk = 0
    for b in buf:
        chk += b
        chk = (chk >> 8) + (chk & 0xFF)
    return chk & 0xFF


def descriptors(params):
    """Group params as the firmware serializer does: a new descriptor when
    the size changes or a descriptor is full (4 bytes)."""
    groups = []
    for size, val in params:
        if groups and groups[-1][0] == size and \
           (len(groups[-1][1]) + 1) * size <= 4 and \
           not (size == 4) and not (size == 2 and len(groups[-1][1]) == 2):
            groups[-1][1].append(val)
        else:
            groups.append((size, [val]))
    descs, data = [], b""
    for size, vals in groups:
        if size == 1:
            d = len(vals)
        elif size == 2:
            d = 4 + len(vals)
        else:
            d = 7
        descs.append(d)
        fmt = {1: "B", 2: "<H", 4: "<I"}[size]
        for v in vals:
            data += struct.pack(fmt, v)
    if not descs:
        descs = [0]
    for i in range(len(descs) - 1):
        descs[i] |= 0x80
    return descs, data


def raw_packet(dev, cmd, params=(), payload=b""):
    descs, pdata = descriptors(list(params))
    body = bytes(descs[1:]) + pdata + bytes(payload)
    length = 6 + len(body)
    pkt = bytearray([dev, cmd, length & 0xFF, length >> 8, 0, descs[0]]) + body
    pkt[4] = checksum(pkt)
    return bytes(pkt)


def slip(pkt):
    out = bytearray([END])
    for b in pkt:
        if b == END:
            out += bytes([ESC, ESC_END])
        elif b == ESC:
            out += bytes([ESC, ESC_ESC])
        else:
            out.append(b)
    out.append(END)
    return bytes(out)


def encode(dev, cmd, params=(), payload=b""):
    return slip(raw_packet(dev, cmd, params, payload))


def unslip(frame):
    assert frame[0] == END and frame[-1] == END, frame.hex()
    out, i = bytearray(), 1
    while i < len(frame) - 1:
        b = frame[i]
        if b == ESC:
            i += 1
            out.append(END if frame[i] == ESC_END else ESC)
        else:
            out.append(b)
        i += 1
    return bytes(out)


def decode(frame):
    pkt = unslip(frame)
    dev, cmd, length, chk, d0 = pkt[0], pkt[1], pkt[2] | pkt[3] << 8, pkt[4], pkt[5]
    assert length == len(pkt), (length, len(pkt))
    z = bytearray(pkt); z[4] = 0
    assert checksum(z) == chk, "bad checksum"
    descs, off = [d0], 6
    while descs[-1] & 0x80:
        descs.append(pkt[off]); off += 1
    params = []
    for d in descs:
        n, sz = NUM_FIELDS[d & 7], FIELD_SIZE[d & 7]
        for _ in range(n):
            params.append(int.from_bytes(pkt[off:off + sz], "little")); off += sz
    return dev, cmd, params, pkt[off:]


def roles(pkt):
    """Role of every byte of an unescaped packet: dev cmd len len chk dsc,
    extra descriptors (dsc), parameter bytes (par), payload (pay)."""
    r = ["dev", "cmd", "len", "len", "chk", "dsc"]
    descs, off = [pkt[5]], 6
    while descs[-1] & 0x80:
        descs.append(pkt[off]); off += 1; r.append("dsc")
    for d in descs:
        n = NUM_FIELDS[d & 7] * FIELD_SIZE[d & 7]
        r += ["par"] * n
    r += ["pay"] * (len(pkt) - len(r))
    return r


def annotate(frame):
    """[(byte, role), ...] for a SLIP frame; escape pairs get role esc."""
    pkt = unslip(frame)
    rl = roles(pkt)
    out = [(END, "end")]
    for b, r in zip(pkt, rl):
        if b == END:
            out += [(ESC, "esc"), (ESC_END, "esc")]
        elif b == ESC:
            out += [(ESC, "esc"), (ESC_ESC, "esc")]
        else:
            out.append((b, r))
    out.append((END, "end"))
    return out


def hexs(b):
    return " ".join("%02X" % x for x in b)


class Bus:
    def __init__(self, host="127.0.0.1", port=1985, timeout=5.0):
        self.s = socket.create_connection((host, port), timeout=timeout)
        self.s.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)

    def send(self, frame):
        self.s.sendall(frame)

    def recv_frame(self):
        buf = bytearray()
        while True:
            b = self.s.recv(1)
            if not b:
                raise EOFError
            if not buf and b[0] != END:
                continue
            buf += b
            if len(buf) > 1 and b[0] == END:
                if len(buf) == 2:      # back-to-back ENDs: resync
                    buf = bytearray([END]); continue
                return bytes(buf)

    def call(self, dev, cmd, params=(), payload=b"", verbose=False):
        f = encode(dev, cmd, params, payload)
        if verbose:
            print(">>", hexs(f))
        self.send(f)
        r = self.recv_frame()
        if verbose:
            print("<<", hexs(r))
        d, c, p, pl = decode(r)
        return d, c, pl


if __name__ == "__main__":
    b = Bus(port=int(sys.argv[1]) if len(sys.argv) > 1 else 1985)
    print(b.call(0x70, 0xFA, verbose=True))
