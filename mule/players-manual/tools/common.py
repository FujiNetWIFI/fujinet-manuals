"""common.py -- shared by build_wiki.py and build_wxr.py."""
import html
import json
import os
import re

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)

GUIDE = "M.U.L.E. Player's Guide"
GUIDE_SLUG = "mule-players-guide"


def editions():
    import yaml
    order = yaml.safe_load(open(os.path.join(ROOT, "content", "platforms.yaml")))["order"]
    return [json.load(open(os.path.join(ROOT, "build", p + ".json"))) for p in order]


def page_title(ed):
    return f"{GUIDE}: {ed['name']}"


def slug(ed):
    return f"{GUIDE_SLUG}-{ed['slug']}"


def chapters(ed):
    out = []
    for b in ed["blocks"]:
        if b["t"] == "chapter":
            out.append({"id": b["id"], "title": b["title"], "blocks": []})
        else:
            out[-1]["blocks"].append(b)
    return out


def images(ed):
    """every picture an edition uses, in order, once."""
    seen = []

    def add(p):
        if p and p not in seen:
            seen.append(p)
    add(ed.get("cover"))
    for b in ed["blocks"]:
        for k in ("img",):
            if isinstance(b.get(k), str):
                add(b[k])
        if b.get("alt"):
            add(b["alt"]["img"])
        for i in b.get("imgs", []):
            add(i["img"])
        for r in b.get("rows", []):
            for c in r:
                if isinstance(c, dict):
                    add(c["img"])
    return seen


def flat_name(path):
    """assets/atari/screens/05-land-grant.png -> mule-atari-05-land-grant.png"""
    parts = path.split("/")
    kind = "" if parts[2] == "screens" else "icon-"
    return f"mule-{parts[1]}-{kind}{parts[3]}"


def anchor(title):
    """GitHub's heading anchor."""
    a = title.strip().lower()
    a = re.sub(r"[^\w\- ]", "", a)
    return a.replace(" ", "-")


def md_inline_html(s):
    """**bold** / *italic* -> HTML, everything else escaped."""
    s = html.escape(s, quote=False)
    s = re.sub(r"\*\*(.+?)\*\*", r"<strong>\1</strong>", s)
    s = re.sub(r"\*(.+?)\*", r"<em>\1</em>", s)
    return s


def alt_text(path):
    n = os.path.basename(path)[:-4]
    n = re.sub(r"^\d+-", "", n).replace("-", " ")
    return n[:1].upper() + n[1:]
