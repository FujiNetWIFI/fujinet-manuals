#!/usr/bin/env python3
"""mklistings.py GAME...                 the games' listings, as printed
   mklistings.py --name NAME FILE...     any of the book's own sources

Reads the dependency files the H89 builds left (build/games/<game>/build/
h89-*/**/*.d, made by tools/games.sh) to find every file compiled into the
HDOS and CP/M programs: the shared game code in src/, the H89 code in
src/h89/ and the headers in src/platform-specific/. (The dependency scan
also names other systems' headers behind #ifdefs; those are not compiled
for the H89 and are left out, as are Battleship's own copies of
fujinet-lib's headers, which Chapter 7 covers.)

Each line is wrapped at WRAP columns -- at a space if one is near, else
hard -- and the pieces after the first carry "+" for a line number.

Writes data/listings/<game>.json:
  {"game", "source": {repo, commit, branch, dirty, files_changed},
   "files": [{"path", "lines", "sha256", "printed": [[num, text], ...]}],
   "total_lines", "printed_lines"}
"""
import hashlib
import json
import os
import re
import subprocess
import sys

BOOK = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
WRAP = 95
NUMW = 5                     # "1234 " -- the number column
SKIP = {"battleship": {"src/fujinet-fuji.h", "src/fujinet-network.h"}}
COMMIT = {"texasHoldEm": "6bad3aa", "battleship": "0c86ed6", "fujitzee": None}
GROUPS = ["src/main.c", "src", "src/platform-specific", "src/h89"]


def deps(game):
    root = os.path.join(BOOK, "build", "games", game)
    found = set()
    for d, _, files in os.walk(os.path.join(root, "build")):
        if "/h89-" not in d + "/":
            continue
        for f in files:
            if not f.endswith(".d"):
                continue
            text = open(os.path.join(d, f)).read().replace("\\\n", " ")
            for tok in text.split():
                if tok.endswith(":"):
                    continue
                p = os.path.normpath(tok.replace(root + "/", ""))
                parts = p.split("/")
                if p.startswith("/") or not p.startswith("src/"):
                    continue
                if len(parts) == 2 or parts[1] in ("h89", "platform-specific"):
                    found.add(p)
    return sorted(found - SKIP.get(game, set()))


def order(paths):
    """main.c first; then src/, platform-specific/, h89/ -- in each, a .c
    file followed by its own header, then the headers left over."""
    out = []
    for g in GROUPS:
        if g.endswith(".c"):
            if g in paths:
                out.append(g)
            continue
        here = [p for p in paths if os.path.dirname(p) == g and p not in out]
        cs = sorted(p for p in here if p.endswith(".c"))
        hs = sorted(p for p in here if p.endswith(".h"))
        for c in cs:
            out.append(c)
            h = c[:-2] + ".h"
            if h in hs:
                out.append(h)
                hs.remove(h)
        out += hs
    out += [p for p in paths if p not in out]
    # main.c's header sits with it if there is one
    return out


def wrap(line, width=WRAP):
    line = line.rstrip("\n").rstrip().expandtabs(8)
    if len(line) <= width:
        return [line]
    indent = len(line) - len(line.lstrip(" "))
    cont = " " * min(indent + 4, 40)
    pieces, rest, first = [], line, True
    while True:
        w = width if first else width - len(cont)
        if len(rest) <= w:
            pieces.append(rest if first else cont + rest)
            break
        cut = rest.rfind(" ", int(w * 0.6), w + 1)
        if cut <= 0:
            cut = w
        head, rest = rest[:cut].rstrip(), rest[cut:].lstrip(" ")
        pieces.append(head if first else cont + head)
        first = False
    return pieces


def source_info(game):
    repo = os.path.expanduser("~/Workspace/fujinet-" + game)
    git = lambda *a: subprocess.run(["git", "-C", repo] + list(a), capture_output=True,
                                    text=True).stdout.strip()
    c = COMMIT[game]
    info = {"repo": "fujinet-" + game, "branch": git("branch", "--show-current")}
    if c:
        info.update(commit=git("rev-parse", "--short", c), dirty=False, files_changed=0)
    else:
        changed = [l for l in git("status", "--short").split("\n") if l.strip()]
        info.update(commit=git("rev-parse", "--short", "HEAD"), dirty=True,
                    files_changed=len(changed))
    return info


MARKER = re.compile(r"^\s*(;|//)@(ex|end|hide|show)\b")


def listing_of(root, paths, raw=False):
    """The book's own sources, less the ;@ex / //@ex marker lines (they
    only tell tools/mksnips.py where the snippets are)."""
    files, total, printed = [], 0, 0
    for p in paths:
        data = open(os.path.join(root, p), "rb").read()
        lines = data.decode("latin-1").replace("\r\n", "\n").split("\n")
        if lines and lines[-1] == "":
            lines = lines[:-1]
        lines = [l for l in lines if not MARKER.match(l)]
        if raw:     # an assembler's own listing: it numbers its own lines
            lines = [l.replace("\f", "").replace("\0", "").replace("\x1a", "") for l in lines]
        out = []
        for n, l in enumerate(lines, 1):
            for i, piece in enumerate(wrap(l, 100 if raw else WRAP)):
                num = "" if raw else (("%4d " % n) if i == 0 else "   + ")
                out.append([num, piece])
        files.append({"path": p, "lines": len(lines),
                      "sha256": hashlib.sha256(data).hexdigest(), "printed": out})
        total += len(lines)
        printed += len(out)
    return files, total, printed


def main():
    os.makedirs(os.path.join(BOOK, "data", "listings"), exist_ok=True)
    if sys.argv[1:2] == ["--name"]:
        name, paths = sys.argv[2], sys.argv[3:]
        raw = "--raw" in paths
        paths = [x for x in paths if x != "--raw"]
        files, total, printed = listing_of(BOOK, paths, raw)
        doc = {"name": name, "files": files, "total_lines": total,
               "printed_lines": printed, "wrap": WRAP}
        json.dump(doc, open(os.path.join(BOOK, "data", "listings", name + ".json"), "w"))
        print("mklistings %s: %d files, %d lines, %d printed" % (name, len(files), total, printed))
        return
    for game in sys.argv[1:]:
        root = os.path.join(BOOK, "build", "games", game)
        files, total, printed = [], 0, 0
        for p in order(deps(game)):
            raw = open(os.path.join(root, p), "rb").read()
            lines = raw.decode("latin-1").split("\n")
            if lines and lines[-1] == "":
                lines = lines[:-1]
            out = []
            for n, l in enumerate(lines, 1):
                for i, piece in enumerate(wrap(l)):
                    num = ("%4d " % n) if i == 0 else "   + "
                    out.append([num, piece])
            files.append({"path": p, "lines": len(lines),
                          "sha256": hashlib.sha256(raw).hexdigest(), "printed": out})
            total += len(lines)
            printed += len(out)
        doc = {"game": game, "source": source_info(game), "files": files,
               "total_lines": total, "printed_lines": printed, "wrap": WRAP}
        json.dump(doc, open(os.path.join(BOOK, "data", "listings", game + ".json"), "w"))
        print("mklistings %s: %d files, %d lines, %d printed" % (game, len(files), total, printed))


if __name__ == "__main__":
    main()
