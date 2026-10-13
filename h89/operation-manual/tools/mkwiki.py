#!/usr/bin/env python3
"""Render the wiki edition's pictures from the book's own drawings and
captured screens. The GitHub wiki is one flat folder, so every file is
prefixed h89-operation-.

    tools/mkwiki.py
"""
import os
import shutil
import subprocess

BOOK = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(BOOK, "wiki", "images")
P = "h89-operation-"
TYPST = shutil.which("typst") or os.path.expanduser("~/.local/bin/typst")
FIGS = ["card", "jumpers", "sockets", "portmap", "blocks"]
CRTS = ["hosts", "wifi-scan", "wifi-password", "host-edit", "browse-sd", "filtered",
        "mount-image", "drives", "newdisk-size", "copy-host", "info", "mounting"]


def render(kind, name):
    out = os.path.join(OUT, f"{P}{name}.png")
    subprocess.run([TYPST, "compile", "--root", BOOK, "--font-path", os.path.join(BOOK, "fonts"),
                    "--ignore-system-fonts", "--ppi", "144", "--input", f"kind={kind}",
                    "--input", f"name={name}", os.path.join(BOOK, "tools", "wikifig.typ"), out],
                   check=True)
    print("wrote", os.path.relpath(out, BOOK))


os.makedirs(OUT, exist_ok=True)
for f in FIGS:
    render("fig", f)
for c in CRTS:
    render("crt", c)
shutil.copy(os.path.join(BOOK, "images", "cover-board.png"), os.path.join(OUT, P + "cover-board.png"))


# ---- the page: fill the keyed-in programs' tables from data/*.json ----------
import json


def octal_table(name):
    d = json.load(open(os.path.join(BOOK, "data", name + ".json")))
    flat = d["flat"]
    out = ["```"]
    for i in range(0, len(flat), 8):
        chunk = flat[i:i + 8]
        out.append(flat[i]["addr"].replace(".", "") + "  " + " ".join(e["byte"] for e in chunk))
    out.append("```")
    return "\n".join(out)


src = os.path.join(BOOK, "wiki", "FujiNet-Operation-Manual-for-the-Heathkit-H89.md.in")
text = open(src).read()
text = text.replace("{{ACCTEST_TABLE}}", octal_table("acctest")).replace("{{FLASHMODE_TABLE}}", octal_table("flashmode"))
open(src[:-3], "w").write(text)
print("wrote", os.path.relpath(src[:-3], BOOK))
