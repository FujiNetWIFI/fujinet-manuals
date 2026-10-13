#!/usr/bin/env python3
"""Give the captured CONFIG screens a real-looking network.

    tools/screenfix.py build/cells screens

The emulator's FujiNet has a stand-in WiFi: every network is "Dummy Cafe N"
at -1 dBm, its address is 127.0.0.1, its hostname is the PC's. This puts an
example network in those places -- laid out the way CONFIG's own code lays
them out (src/h89/screen.c, ui.c) -- and leaves every other cell exactly as
the terminal showed it. FIGURES.md says which screens were touched.
"""
import json
import os
import sys

EXAMPLE = {
    "ssid": "Workshop",
    "ip": "192.168.1.89",
    "gateway": "192.168.1.1",
    "dns": "192.168.1.1",
    "netmask": "255.255.255.0",
    "mac": "24:6F:28:1A:89:01",
    "bssid": "60:38:E0:4D:2B:11",
    "hostname": "FujiNet",
    "config": "6f48e0f",            # fujinet-config add-h89 HEAD
}
# a neighbourhood's worth of networks, strongest first, as the ESP32 lists them
NETWORKS = [("Workshop", -48), ("NETGEAR42", -61), ("Benton Harbor Library", -67),
            ("HP-Print-3C-LaserJet", -72), ("SEBHC-Guest", -79), ("xfinitywifi", -84)]

G = lambda i: chr(0xE000 + i)         # an H19 graphics glyph, as ppm2cells writes it
CHECKER, BAR_BOTTOM, QUAD_LR, HALF_RIGHT = G(0x09), G(0x1B), G(0x0C), G(0x11)


class Screen:
    def __init__(self, d):
        self.text = [list(r["text"]) for r in d["rows"]]
        self.rev = [list(r["rev"]) for r in d["rows"]]
        self.cursor = d["cursor"]

    def dump(self):
        return {"rows": [{"text": "".join(t), "rev": "".join(r)}
                         for t, r in zip(self.text, self.rev)], "cursor": self.cursor}

    def put(self, x, y, s, rev=" "):
        for i, ch in enumerate(s):
            self.text[y][x + i] = ch
            self.rev[y][x + i] = rev

    def find(self, s):
        for y, row in enumerate(self.text):
            i = "".join(row).find(s)
            if i >= 0:
                yield y, i

    def sub(self, old, new, border=True):
        """Replace old by new on every row it appears, shifting the rest of
        the row; the row keeps its length (and its right border)."""
        for y, i in list(self.find(old)):
            t, r = self.text[y], self.rev[y]
            end = 79 if border and t[79] != " " else 80
            seg_t = t[i + len(old):end]
            seg_r = r[i + len(old):end]
            nt = t[:i] + list(new) + seg_t
            nr = r[:i] + [r[i]] * len(new) + seg_r
            if len(nt) > end:                    # drop spaces before the border
                over = len(nt) - end
                for _ in range(over):
                    k = max(j for j in range(i + len(new), len(nt)) if nt[j] == " ")
                    del nt[k], nr[k]
            while len(nt) < end:                 # pad before the border
                nt.append(" ")
                nr.append(nr[-1] if nr else " ")
            self.text[y][:end] = nt
            self.rev[y][:end] = nr

    def status(self, ver):
        """Row 24, as ui_status draws it."""
        y = 24
        self.put(0, y, " " * 80)
        self.put(0, y, CHECKER)
        x = 1
        for label, value in ((" SSID: ", EXAMPLE["ssid"]), (" IP: ", EXAMPLE["ip"]),
                             (" FujiNet ", ver)):
            s = label + value + " "
            self.put(x, y, s)
            x += len(s)
            self.put(x, y, CHECKER)
            x += 1

    def networks(self):
        """The WiFi list, as screen_set_wifi_display_ssid draws it."""
        bar = self.rev[2][1] == "r"
        for y in range(2, 19):
            self.put(1, y, " " * 78)
        for n, (ssid, rssi) in enumerate(NETWORKS):
            y = 2 + n
            self.put(3, y, ssid[:32])
            level = 4 if rssi > -55 else 3 if rssi > -67 else 2 if rssi > -78 else 1
            for i, (g, rv) in enumerate(((BAR_BOTTOM, " "), (QUAD_LR, " "),
                                         (HALF_RIGHT, " "), (" ", "r"))):
                self.put(64 + i, y, g if i < level else " ", rv if i < level else " ")
            self.put(70, y, f"{rssi} dBm")
        self.put(3, 2 + len(NETWORKS), "<Enter a network name>")
        if bar:                                   # h19.c cell(): columns 1-78 reversed, arrow at 1
            self.text[2][1] = G(0x08)
            for x in range(1, 79):
                self.rev[2][x] = "r"


def fix(name, s):
    ver = None
    for y, i in s.find(" FujiNet v"):
        if y == 24:
            ver = "".join(s.text[24][i + 9:]).split(" ")[0]
    if ver:
        s.status(ver)
    if name in ("info",):
        for label, key in (("SSID", "ssid"), ("Hostname", "hostname"), ("IP address", "ip"),
                           ("Gateway", "gateway"), ("DNS", "dns"), ("Netmask", "netmask"),
                           ("MAC", "mac"), ("BSSID", "bssid"), ("CONFIG", "config")):
            for y, i in s.find(label + ": "):
                if not 2 <= y <= 18:              # the list, not the status line
                    continue
                x = i + len(label) + 2
                s.put(x, y, " " * (79 - x))
                s.put(x, y, EXAMPLE[key])
    if name in ("wifi-scan", "wifi-password"):
        s.sub("MAC D0:1C:ED:C0:FF:EE", "MAC " + EXAMPLE["mac"])
        s.networks()
        s.sub("Password for Dummy Cafe 2:", "Password for " + EXAMPLE["ssid"] + ":")
    for y, row in enumerate(s.text):
        assert "Dummy" not in "".join(row), (name, y, "".join(row))
        assert "127.0.0.1" not in "".join(row), (name, y)


def main():
    src, dst = sys.argv[1], sys.argv[2]
    os.makedirs(dst, exist_ok=True)
    for f in sorted(os.listdir(src)):
        if not f.endswith(".json"):
            continue
        name = f[:-5]
        s = Screen(json.load(open(os.path.join(src, f))))
        if name.startswith("mtr-pass"):
            # the acceptance test prints the reply's SSID and hostname
            s.sub("Dummy Cafe TMA-3", EXAMPLE["ssid"] + " " + EXAMPLE["hostname"], border=False)
        elif name not in ("exit-hdos", "exit-cpm") and not name.startswith(("hdos-", "cpm-", "mtr-")):
            fix(name, s)
        json.dump(s.dump(), open(os.path.join(dst, f), "w"), ensure_ascii=False, indent=0)


if __name__ == "__main__":
    main()
