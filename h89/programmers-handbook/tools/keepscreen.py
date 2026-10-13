#!/usr/bin/env python3
"""keepscreen.py RUN NAME [OLD=NEW ...] -- keep a run's last screen for the book.

Copies build/runs/RUN/screen.json (the H19's 25 rows as ppm2cells read them)
to screens/NAME.json, first replacing each OLD with NEW wherever it stands on
the screen. Rows keep their 80 columns: a longer NEW pushes the rest of the
row right (trailing blanks absorb it), a shorter one pulls it left.

The book's runs talk to fujinet-pc on the same computer, so the screens show
the stand-in network ("Dummy Cafe", 127.0.0.1, the PC's host name) and the
local test servers at 127.0.0.1. The Operation Manual's example network is
put in their place -- the FujiNet at 192.168.1.89 on "Workshop", the servers
at 192.168.1.10 -- and every replacement is recorded in FIGURES.md's table
(data/screenfix.json), so nothing is changed silently.
"""
import json
import os
import sys

BOOK = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def main():
    run, name = sys.argv[1], sys.argv[2]
    subs = [a.split("=", 1) for a in sys.argv[3:]]
    d = json.load(open(os.path.join(BOOK, "build", "runs", run, "screen.json")))
    done = []
    for r in d["rows"]:
        text = "".join(r["text"]) if isinstance(r["text"], list) else r["text"]
        rev = r["rev"]
        for old, new in subs:
            while old in text:
                i = text.index(old)
                text = text[:i] + new + text[i + len(old):]
                if isinstance(rev, list):
                    rev = rev[:i] + [rev[i]] * len(new) + rev[i + len(old):]
                else:
                    rev = rev[:i] + rev[i] * len(new) + rev[i + len(old):]
                done.append([old, new])
        text = (text.rstrip() + " " * 80)[:80] if len(text.rstrip()) <= 80 else text[:80]
        rev = rev[:80] + (rev[-1:] * (80 - len(rev)) if len(rev) < 80 else rev[:0])
        r["text"] = text
        r["rev"] = rev
    os.makedirs(os.path.join(BOOK, "screens"), exist_ok=True)
    json.dump(d, open(os.path.join(BOOK, "screens", name + ".json"), "w"))
    log_path = os.path.join(BOOK, "data", "screenfix.json")
    log = json.load(open(log_path)) if os.path.exists(log_path) else {}
    log[name] = {"run": run, "replaced": sorted({tuple(x) for x in done})}
    json.dump(dict(sorted(log.items())), open(log_path, "w"), indent=1)
    print("keepscreen %s -> screens/%s.json (%d replacements)" % (run, name, len(done)))


if __name__ == "__main__":
    main()
