#!/usr/bin/env python3
"""mkwiki.py -- build wiki/FujiNet-RS232-Users-Manual.md from its .md.in
template, replacing each {{ex:KEY}} with the captured exchange from
examples.json as hex text, so the wiki's byte streams match the PDF's."""
import json, os, re

here = os.path.dirname(os.path.abspath(__file__))
root = os.path.join(here, "..")
ex = json.load(open(os.path.join(root, "examples.json")))
src = open(os.path.join(root, "wiki", "FujiNet-RS232-Users-Manual.md.in")).read()


def hexline(frame, limit=40):
    b = [h for h, _ in frame]
    if len(b) > limit:
        return " ".join(b[:limit - 1]) + " ... (%d more) %s" % (len(b) - limit, b[-1])
    return " ".join(b)


def block(m):
    e = ex[m.group(1)]
    lines = ["```", "-> " + hexline(e["req"])]
    if "rep" in e:
        what = "ACK" if e.get("ack") else "NAK"
        lines.append("<- " + hexline(e["rep"]) + "    (%s, %d byte%s)" % (
            what, e.get("replen", 0), "" if e.get("replen") == 1 else "s"))
    else:
        lines.append("<- (no reply)")
    lines.append("```")
    return "\n".join(lines)


out = re.sub(r"\{\{ex:([a-z0-9_.]+)\}\}", block, src)
open(os.path.join(root, "wiki", "FujiNet-RS232-Users-Manual.md"), "w").write(out)
print("wrote wiki/FujiNet-RS232-Users-Manual.md")
