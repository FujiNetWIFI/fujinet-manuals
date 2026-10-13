#!/usr/bin/env python3
"""cardinfo.py PREFIX... -- what the book knows about some commands, at a
glance, for writing their cards: the firmware survey's entry (fields,
payload, reply, traps), the expectation, and what each run's capture got.

  python3 tools/cardinfo.py fuji.get_ssid net.open
"""
import json
import os
import sys

BOOK = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
J = lambda *p: json.load(open(os.path.join(BOOK, *p)))
EX = J("data", "examples.json")
SPEC = {}
for f in ("fuji", "net"):
    for c in J("data", "fwspec", f + ".json")["commands"]:
        SPEC[c["name"]] = c
for d in J("data", "fwspec", "misc.json")["devices"]:
    for c in d["commands"]:
        SPEC[c["name"]] = c
EXPECT = {}
for f in os.listdir(os.path.join(BOOK, "expect")) if os.path.isdir(os.path.join(BOOK, "expect")) else []:
    if f.endswith(".json"):
        EXPECT.update(J("expect", f))
PREFIX = {"fuji": "FUJI_", "net": "NET_", "disk": "DISK_", "clock": "APETIME_",
          "printer": "PRINTER_", "modem": "MODEM_"}


def spec_for(key):
    dev, cmd = key.split(".")[:2]
    name = PREFIX.get(dev, "") + cmd.upper()
    return name, SPEC.get(name)


def show(key):
    name, s = spec_for(key)
    print("=" * 78)
    print(key, "->", name)
    if s:
        for f in s.get("fields", []):
            print("  field %s: %s size %s -- %s" % (f.get("index"), f.get("name"), f.get("size"), f.get("meaning")))
        p = s.get("payload", {})
        print("  payload:", p.get("len"), "|", (p.get("format") or "")[:300])
        r = s.get("reply", {})
        print("  reply:", r.get("kind"), r.get("len"))
        for l in [x for x in r.get("layout", []) if isinstance(x, dict)][:14]:
            print("     +%s %s %s %s" % (l.get("off"), l.get("size"), l.get("name"), (l.get("meaning") or "")[:90]))
        for n in r.get("naks_when", []):
            print("  NAK:", n[:160])
        if s.get("side_effects"):
            print("  effects:", s["side_effects"][:300])
        for t in s.get("traps", []):
            print("  TRAP:", t[:240])
        for lib in s.get("fujinet_lib", []):
            print("  lib: %s (%s) %s" % (lib.get("symbol"), lib.get("sends"), lib.get("mismatch") or ""))
    if key in EXPECT:
        print("  expect:", json.dumps(EXPECT[key])[:300])
    runs = EX.get(key, {})
    pr = lambda t: "".join(c if 32 <= ord(c) < 127 else "." for c in t)
    for run in [r for r in runs if r.endswith("asm-hdos")][:1]:
        for x in runs[run]:
            req = " ".join(h for h, _ in x["req"]) if x["req"] else "-"
            print("  %-16s %-4s %4d  req %s" % (run, x["reply"], x["replen"], req[:72]))
            rep = " ".join(h for h, _ in x["rep"]) if x["rep"] else ""
            if x["replen"]:
                print("     rep %s" % rep[:96])
                print("     txt %r" % pr(x["text"])[:72])
    # does the C request differ (beyond descriptor flag bits)?
    a = [r for r in runs if r.endswith("asm-hdos")]
    c = [r for r in runs if r.endswith("c-hdos")]
    if a and c:
        def body(xs):
            out = []
            for x in xs:
                if x["req"]:
                    bs = [int(h, 16) for h, _ in x["req"]]
                    out.append((bs[1], bs[2], x["params"], x["paylen"]))
            return out
        ba, bc = body(runs[a[0]]), body(runs[c[0]])
        if ba != bc:
            print("  C differs: asm %s / c %s" % (ba, bc))


for a in sys.argv[1:]:
    if a in EX or a in EXPECT:
        show(a)
        continue
    for k in sorted(set(list(EX.keys()) + list(EXPECT.keys()))):
        if k.startswith(a + "."):
            show(k)
