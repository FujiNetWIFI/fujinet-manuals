#!/usr/bin/env python3
"""build_wiki.py -- build/<platform>.json -> wiki/*.md + wiki/images/.

GitHub-wiki Markdown for the FujiNet wiki
(https://github.com/FujiNetWIFI/fujinet-firmware/wiki), in the style of the
other wiki editions in this repo: a title, an italic summary, a rule, a
numbered contents list, then ## sections. One page per edition, and a
landing page that links them. Pictures are copied to wiki/images/ under
flat names, and linked relatively (images/...), so wiki/ can be pushed to
the wiki's git repository as it is.
"""
import os
import shutil

from common import (ROOT, GUIDE, editions, chapters, images, flat_name, anchor, alt_text)

OUT = os.path.join(ROOT, "wiki")


def page_name(ed):
    return f"MULE-Players-Guide-{ed['name'].replace(' ', '-').replace('/', '-')}"


def cell(c):
    if isinstance(c, dict):
        return f"<img src=\"images/{flat_name(c['img'])}\" width=\"48\" alt=\"{alt_text(c['img'])}\">"
    return c.replace("|", "\\|").replace("\n", " ")


def img(path, alt=None, width=480):
    return f"<img src=\"images/{flat_name(path)}\" width=\"{width}\" alt=\"{alt or alt_text(path)}\">"


def render(b):
    t = b["t"]
    if t == "p":
        return b["text"]
    if t == "h":
        return f"### {b['text']}"
    if t == "list":
        if b["ordered"]:
            return "\n".join(f"{i + 1}. {x}" for i, x in enumerate(b["items"]))
        return "\n".join(f"- {x}" for x in b["items"])
    if t == "note":
        return f"> {b['text']}"
    if t == "step":
        out = [f"#### {b['n']}. {b['title']}"]
        if b.get("img"):
            out.append(img(b["img"]))
        if b.get("alt"):
            out.append(img(b["alt"]["img"], width=320) + f"<br>*{b['alt']['label']} screen*")
        if b.get("lead"):
            out.append(f"**{b['lead']}**")
        if b.get("text"):
            out.append(b["text"])
        return "\n\n".join(out)
    if t == "shot":
        out = [img(b["img"])]
        if b.get("alt"):
            out.append(img(b["alt"]["img"], width=320) + f"<br>*{b['alt']['label']} screen*")
        if b.get("caption"):
            out.append(f"*{b['caption']}*")
        return "\n\n".join(out)
    if t == "shots":
        return " ".join(img(i["img"], width=360) for i in b["imgs"]) + f"\n\n*{b['caption']}*"
    if t == "tips":
        return "### Tips on the Tournament Game\n\n" + "\n".join(f"- {x}" for x in b["items"])
    if t == "qa":
        return "\n\n".join(f"**Q: {x['q']}**  \nA: {x['a']}" for x in b["items"])
    if t == "table":
        head = b["head"] if not b.get("kv") else ["", ""]
        lines = ["| " + " | ".join(head) + " |", "|" + "|".join("---" for _ in head) + "|"]
        lines += ["| " + " | ".join(cell(c) for c in r) + " |" for r in b["rows"]]
        return "\n".join(lines)
    if t == "event":
        return (f"#### {b['name']}\n\n*Can happen up to {b['times']} times a game.*\n\n"
                f"> “{b['text']}”\n\n{b['effect']}")
    raise SystemExit(f"unknown block {t}")


def build(ed):
    name = page_name(ed)
    chs = chapters(ed)
    out = [f"# {GUIDE}: {ed['name']}", "",
           f"*How to load and play The FujiNet Multiplayer M.U.L.E. on the {ed['long']}: "
           f"the room, the colonists, the land, every phase of a month, and every fortune and catastrophe.*",
           "", "---", ""]
    if ed.get("cover"):
        out += [img(ed["cover"], alt="M.U.L.E. title screen"), ""]
    out.append("## Contents")
    out.append("")
    for i, c in enumerate(chs):
        out.append(f"{i + 1}. [{c['title']}](#{anchor(c['title'])})")
    out.append("")
    for c in chs:
        out += [f"## {c['title']}", ""]
        for b in c["blocks"]:
            out += [render(b), ""]
    out += ["---", "",
            "*M.U.L.E. was designed by Ozark Softscape and published by Electronic Arts in 1983. "
            "The FujiNet Multiplayer Edition is a network version made by the FujiNet community; "
            "its pictures are converted from the 1983 Atari disk and remain the property of their owners.*",
            "", f"*Other editions of this guide: [[{GUIDE}|MULE-Players-Guide]]*", ""]
    open(os.path.join(OUT, name + ".md"), "w").write("\n".join(out))
    for p in images(ed):
        shutil.copy(os.path.join(ROOT, p), os.path.join(OUT, "images", flat_name(p)))
    return name


def main():
    if os.path.isdir(OUT):
        shutil.rmtree(OUT)
    os.makedirs(os.path.join(OUT, "images"))
    eds = editions()
    names = [(ed, build(ed)) for ed in eds]
    land = [f"# {GUIDE}", "",
            "*The player's guide to The FujiNet Multiplayer M.U.L.E., in an edition for each machine it runs on.*",
            "", "---", "",
            "M.U.L.E. is played over the Internet with FujiNet. Up to four colonists share a room. "
            "Right now there is one room, **Planet IRATA**, and more will be added. Each guide below "
            "covers the same game, with its own machine's pictures, controls and loading steps.", ""]
    land += [f"- [[{ed['name']}|{n}]] ({ed['long']})" for ed, n in names]
    land += ["", "A printable PDF of each guide is available as well.", ""]
    open(os.path.join(OUT, "MULE-Players-Guide.md"), "w").write("\n".join(land))
    print(f"wiki: {len(names)} pages, {len(os.listdir(os.path.join(OUT, 'images')))} images")


if __name__ == "__main__":
    main()
