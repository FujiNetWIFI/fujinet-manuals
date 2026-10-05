#!/usr/bin/env python3
"""mkwiki.py -- expand wiki/template.md into the wiki page, inlining the
verified listings ({{file:path}}) so the wiki shows exactly what was built."""
import os, re
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
t = open(os.path.join(ROOT, "wiki", "template.md")).read()
t = re.sub(r"\{\{file:([^}]+)\}\}",
           lambda m: open(os.path.join(ROOT, m.group(1))).read().rstrip("\n"), t)
out = os.path.join(ROOT, "wiki", "FujiNet-Programming-Guide-for-the-NES.md")
open(out, "w").write(t)
print("mkwiki:", out, len(t.splitlines()), "lines")
