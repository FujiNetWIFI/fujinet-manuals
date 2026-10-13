#!/usr/bin/env python3
"""mkquickref.py -- the Appendix's command quick reference, from the specs.

Reads data/fwspec/{fuji,net,misc}.json (the firmware surveys, every entry
cited to fn-h89's source) and writes data/quickref.json: one row per
command the H89 firmware dispatches, by device --

  {"devices": [{"name", "ids", "rows": [{"equ", "hex", "fields",
                "payload", "reply"}]}]}

Fields are given as their sizes in order (1 = byte, 2 = word, 4 = long),
the payload and reply as their lengths, so the table fits a page; the
card the "page" column points at says the rest.
"""
import json
import os
import re

BOOK = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def short_len(x, kind=None):
    if x is None:
        return "--"
    s = str(x).strip()
    if kind in ("ack", "nak", "none") and s in ("0", "", "none"):
        return "--"
    m = re.match(r"^(\d+)\b", s)
    if m and not re.match(r"^\d+\s*[-+*]", s):
        return m.group(1)
    if s.lower().startswith(("none", "0 ")) or s == "0":
        return "--"
    s = re.sub(r"\s*\(.*$", "", s)
    return s[:18]


def rows_of(cmds):
    out = []
    for c in cmds:
        f = c.get("fields") or []
        fields = ",".join(str(x.get("size", "?")) for x in f) or "--"
        p = c.get("payload") or {}
        pay = "--"
        if p.get("required") or (p.get("len") not in (None, "0", "none", "")):
            pay = short_len(p.get("len"))
        r = c.get("reply") or {}
        kind = (r.get("kind") or "").split("|")[0]
        if kind.startswith("ack-data") or kind == "raw":
            rep = short_len(r.get("len"))
        elif kind == "nak":
            rep = "NAK"
        elif kind == "none":
            rep = "none"
        else:
            rep = "ACK"
        out.append({"equ": c["name"], "hex": c["value"].replace("0x", "").upper().zfill(2) + "H",
                    "fields": fields, "payload": pay, "reply": rep})
    return sorted((tidy(r) for r in out), key=lambda r: r["equ"])


# Cells the surveys' wording does not shorten well, set by hand from the
# cards (fields: sizes; payload, reply: lengths or what they are)
OVERRIDE = {
    "FUJI_HASH_OUTPUT": {"reply": "length"},
    "FUJI_READ_DIR_ENTRY": {"reply": "field 1"},
    "FUJI_COPY_FILE": {"payload": "src|dst"},
    "FUJI_WRITE_APPKEY": {"payload": "<= 64"},
    "FUJI_SET_SSID": {"fields": "1"},
    "NET_OPEN": {"payload": "spec"}, "NET_CHDIR": {"payload": "path"},
    "NET_DELETE": {"payload": "spec"}, "NET_RENAME": {"payload": "spec,new"},
    "NET_MKDIR": {"payload": "spec"}, "NET_RMDIR": {"payload": "spec"},
    "NET_LOCK": {"payload": "spec"}, "NET_UNLOCK": {"payload": "spec"},
    "NET_USERNAME": {"payload": "text"}, "NET_PASSWORD": {"payload": "text"},
    "NET_QUERY": {"payload": "pointer"}, "NET_SET_DESTINATION": {"payload": "N:host:port"},
    "NET_SET_EOL": {"payload": "1-2"}, "NET_WRITE": {"payload": "field"},
    "NET_READ": {"reply": "<= field"}, "NET_GETCWD": {"reply": "prefix"},
    "DISK_READ": {"fields": "4", "reply": "512"}, "DISK_WRITE": {"fields": "4", "payload": "512"},
    "DISK_PUT": {"fields": "4", "payload": "512"}, "DISK_STATUS": {"fields": "1"},
    "DISK_FORMAT": {"reply": "128"}, "DISK_FORMAT_MEDIUM": {"reply": "128"},
    "DISK_PERCOM_WRITE": {"payload": "12"},
    "APETIME_GET_GENERAL": {"reply": "text"}, "APETIME_SETTZ": {"payload": "text"},
    "APETIME_SETTZ_ALT": {"payload": "text"},
    "PRINTER_WRITE": {"payload": "text"}, "PRINTER_PUT": {"payload": "text"},
    "MODEM_LISTEN": {"fields": "2"}, "MODEM_BAUDRATELOCK": {"fields": "1,1"},
    "MODEM_WRITE": {"payload": "bytes"},
}


def tidy(r):
    r["fields"] = ",".join("1" if f.strip().startswith("any") else f for f in r["fields"].split(","))
    for k in ("payload", "reply"):
        if r[k] in ("ignored", "-") or r[k].startswith("ignored"):
            r[k] = "--"
    r.update(OVERRIDE.get(r["equ"], {}))
    return r


def main():
    devs = []
    fuji = json.load(open(os.path.join(BOOK, "data", "fwspec", "fuji.json")))
    devs.append({"name": "The FujiNet device", "ids": "70H", "rows": rows_of(fuji["commands"])})
    net = json.load(open(os.path.join(BOOK, "data", "fwspec", "net.json")))
    devs.append({"name": "Network channels", "ids": "71H-78H", "rows": rows_of(net["commands"])})
    misc = json.load(open(os.path.join(BOOK, "data", "fwspec", "misc.json")))
    names = {"disk": ("Disk drives", "31H-38H"), "clock": ("Clock", "45H"),
             "printer": ("Printer", "40H"), "modem": ("Modem", "50H")}
    for d in misc["devices"]:
        if d["device"] in names:
            n, ids = names[d["device"]]
            devs.append({"name": n, "ids": ids, "rows": rows_of(d["commands"])})
    json.dump({"devices": devs}, open(os.path.join(BOOK, "data", "quickref.json"), "w"), indent=1)
    print("mkquickref: %d commands" % sum(len(d["rows"]) for d in devs))


if __name__ == "__main__":
    main()
