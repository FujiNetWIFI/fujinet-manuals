#!/usr/bin/env python3
"""Print a captured screen (screens/<name>.json) on a terminal, for review:
graphics glyphs as their nearest Unicode, reverse video in ANSI inverse."""
import json, sys
G = {0x00: "│", 0x01: "─", 0x03: "┐", 0x04: "┘", 0x05: "└", 0x06: "┌", 0x08: "→",
     0x09: "▒", 0x0C: "▗", 0x11: "▐", 0x14: "┤", 0x16: "├", 0x1B: "_", 0x7F: "█"}
for path in sys.argv[1:]:
    d = json.load(open(path))
    print("==", path, "cursor", d["cursor"])
    for r in d["rows"]:
        out, inv = [], False
        for ch, a in zip(r["text"], r["rev"]):
            cp = ord(ch)
            if 0xE000 <= cp <= 0xE07F:
                ch = G.get(cp - 0xE000, "¤")
            want = a == "r"
            if want != inv:
                out.append("\033[7m" if want else "\033[0m"); inv = want
            out.append(ch)
        out.append("\033[0m")
        print("".join(out).rstrip())
