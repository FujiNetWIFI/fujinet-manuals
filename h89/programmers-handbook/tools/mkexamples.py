#!/usr/bin/env python3
"""mkexamples.py RUN... -- the book's byte strips, from what was on the bus.

Each RUN is a directory under build/runs/ made by runprog.sh: tap.jsonl
holds every SLIP frame that passed between the emulated card and
fujinet-pc while one of the book's programs ran. The exerciser programs
send a marker before each example (ex_mark: a frame to device 0FH, which
does not exist, carrying the example's key), so the log splits into
examples: the exchanges after a marker belong to its key, up to the next.

Writes data/examples.json:
  {KEY: {RUN: [exchange, ...]}}
  exchange = {"req": [[hex, role], ...], "rep": [[hex, role], ...] | null,
              "raw": "hex ..." | null, "dev", "cmd", "reply": "ACK"|"NAK"|
              "none"|"raw", "replen", "paylen", "text"}
Roles are those of fujibus.annotate: end esc dev cmd len chk dsc par pay.
Runs already in examples.json and not named again are kept, so runs can
be added one at a time; --fresh starts over, --drop=RUN forgets one.
"""
import fcntl
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fujibus import annotate, decode, unslip  # noqa: E402

BOOK = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(BOOK, "data", "examples.json")
MARK_DEV = 0x0F


def frame(hexs):
    return bytes(int(x, 16) for x in hexs.split())


def strip(f):
    return [["%02X" % b, r] for b, r in annotate(f)]


def split(run):
    path = os.path.join(BOOK, "build", "runs", run, "tap.jsonl")
    recs = [json.loads(l) for l in open(path) if l.strip()]
    keyed, key, cur = {}, "_start", None
    skip_reply = False
    for r in recs:
        if r["dir"] == "h89" and "hex" in r:
            f = frame(r["hex"])
            dev, cmd, params, pay = decode(f)
            if dev == MARK_DEV:
                key = pay.rstrip(b"\0").decode("latin-1")
                skip_reply, cur = True, None
                continue
            cur = {"req": strip(f), "rep": None, "raw": None, "dev": dev, "cmd": cmd,
                   "params": params, "paylen": len(pay), "reply": "none", "replen": 0,
                   "text": ""}
            keyed.setdefault(key, []).append(cur)
            skip_reply = False
        elif r["dir"] == "fn" and "hex" in r:
            if skip_reply:
                skip_reply = False
                continue
            f = frame(r["hex"])
            if cur is None or cur["rep"] is not None:
                # a reply nobody asked for: keep it, so it shows
                cur = {"req": None, "rep": None, "raw": None, "dev": None, "cmd": None,
                       "params": [], "paylen": 0, "reply": "none", "replen": 0, "text": ""}
                keyed.setdefault(key, []).append(cur)
            dev, cmd, params, pay = decode(f)
            cur["rep"] = strip(f)
            cur["reply"] = {0x06: "ACK", 0x15: "NAK"}.get(cmd, "%02X" % cmd)
            cur["replen"] = len(pay)
            cur["text"] = pay[:96].decode("latin-1")
        elif r["dir"] == "h89" and "raw" in r:
            # bytes the H89 sent outside a frame (the modem's AT commands)
            cur = {"req": None, "rawreq": r["raw"], "rep": None, "raw": None, "dev": None,
                   "cmd": None, "params": [], "paylen": len(r["raw"].split()), "reply": "none",
                   "replen": 0, "text": ""}
            keyed.setdefault(key, []).append(cur)
            skip_reply = False
        elif r["dir"] == "fn" and "raw" in r:
            if cur is None:
                cur = {"req": None, "rep": None, "raw": "", "dev": None, "cmd": None,
                       "params": [], "paylen": 0, "reply": "raw", "replen": 0, "text": ""}
                keyed.setdefault(key, []).append(cur)
            cur["raw"] = ((cur["raw"] or "") + " " + r["raw"]).strip()
            if cur["rep"] is None:
                cur["reply"] = "raw"
            cur["replen"] = len(cur["raw"].split())
    return keyed


def main():
    # one writer at a time: exercisers may finish together
    lock = open(os.path.join(BOOK, "build", ".data.lock"), "w")
    fcntl.flock(lock, fcntl.LOCK_EX)
    args = sys.argv[1:]
    fresh = "--fresh" in args
    drop = [a[7:] for a in args if a.startswith("--drop=")]
    runs = [a for a in args if not a.startswith("--")]
    ex = {} if fresh or not os.path.exists(OUT) else json.load(open(OUT))
    for run in drop:                      # --drop=RUN forgets a run
        for key in list(ex):
            ex[key].pop(run, None)
            if not ex[key]:
                del ex[key]
    for run in runs:
        for key in list(ex):
            ex[key].pop(run, None)
            if not ex[key]:
                del ex[key]
        for key, xs in split(run).items():
            ex.setdefault(key, {})[run] = xs
    json.dump(dict(sorted(ex.items())), open(OUT, "w"), indent=0)
    print("mkexamples: %d keys from %d runs" % (len(ex), len({r for k in ex for r in ex[k]})))


if __name__ == "__main__":
    main()
