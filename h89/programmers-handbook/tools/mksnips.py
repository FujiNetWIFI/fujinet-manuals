#!/usr/bin/env python3
"""mksnips.py -- cut the printed snippets out of the book's programs.

Every example in the book is a piece of a program that was built and run.
The pieces are marked in the sources:

  assembly   ;@ex KEY   ...   ;@end         C   //@ex KEY   ...   //@end
             ;@hide ... ;@show                  //@hide ... //@show

A key may be marked more than once in one language (the call in the code,
the request block in the data): the pieces are joined in source order with
a "..." line between them. Lines between @hide and @show are left out
(the exerciser's own bookkeeping). The marker lines themselves never print.

Writes data/snips.json:
  {KEY: {"asm"|"c": {"text": "...", "where": [["src/...", first, last], ...]}}}
and fails if one key is cut from two different files in the same language
(two programs would claim the same printed example).
"""
import fcntl
import json
import os
import re
import sys

BOOK = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MARK = {
    "asm": re.compile(r"^\s*;@(ex|end|hide|show)\b\s*(\S*)"),
    "c": re.compile(r"^\s*//@(ex|end|hide|show)\b\s*(\S*)"),
}
LANG = {".asm": "asm", ".inc": "asm", ".c": "c", ".h": "c"}


def dedent(lines):
    body = [l for l in lines if l.strip() and l != "..."]
    if not body:
        return lines
    cut = min(len(l) - len(l.lstrip(" ")) for l in body)
    return [l[cut:] if l != "..." else l for l in lines]


def scan(path, lang, out, errors):
    rel = os.path.relpath(path, BOOK)
    key, hide, start, piece = None, False, 0, []
    for n, line in enumerate(open(path, encoding="latin-1").read().split("\n"), 1):
        line = line.rstrip().expandtabs(8)
        m = MARK[lang].match(line)
        if m:
            what, arg = m.groups()
            if what == "ex":
                if key:
                    errors.append("%s:%d: @ex %s inside @ex %s" % (rel, n, arg, key))
                key, start, piece, hide = arg, n + 1, [], False
            elif what == "end":
                if not key:
                    errors.append("%s:%d: @end without @ex" % (rel, n))
                    continue
                ent = out.setdefault(key, {}).setdefault(lang, {"pieces": [], "where": []})
                if ent["where"] and ent["where"][0][0] != rel:
                    errors.append("%s:%d: %s (%s) is already cut from %s"
                                  % (rel, n, key, lang, ent["where"][0][0]))
                ent["pieces"].append(dedent(piece) if lang == "c" else piece)
                ent["where"].append([rel, start, n - 1])
                key = None
            elif what == "hide":
                hide = True
            elif what == "show":
                hide = False
            continue
        if key and not hide:
            piece.append(line)
    if key:
        errors.append("%s: @ex %s never ends" % (rel, key))


def main():
    # one writer at a time: exercisers may finish together
    lock = open(os.path.join(BOOK, "build", ".data.lock"), "w")
    fcntl.flock(lock, fcntl.LOCK_EX)
    out, errors = {}, []
    for top in ("src/asm", "src/c", "src/native"):
        for d, _, files in sorted(os.walk(os.path.join(BOOK, top))):
            for f in sorted(files):
                lang = LANG.get(os.path.splitext(f)[1].lower())
                if lang:
                    scan(os.path.join(d, f), lang, out, errors)
    for key in out:
        for lang, ent in out[key].items():
            lines = []
            for i, p in enumerate(ent.pop("pieces")):
                while p and not p[0].strip():
                    p = p[1:]
                while p and not p[-1].strip():
                    p = p[:-1]
                if i:
                    lines.append("...")
                lines += p
            ent["text"] = "\n".join(lines)
    if errors:
        print("\n".join(errors), file=sys.stderr)
        sys.exit(1)
    path = os.path.join(BOOK, "data", "snips.json")
    json.dump(dict(sorted(out.items())), open(path, "w"), indent=1)
    both = sum(1 for k in out if len(out[k]) == 2)
    print("mksnips: %d keys (%d in both languages)" % (len(out), both))


if __name__ == "__main__":
    main()
