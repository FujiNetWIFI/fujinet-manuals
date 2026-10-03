#!/usr/bin/env python3
"""expand.py -- content/*.yaml + one platform -> build/<platform>.json.

usage: expand.py [PLATFORM...]      (default: every platform)

The three renderers (manual.typ, build_wiki.py, build_wxr.py) all read the
JSON this writes, so the PDF, the wiki and the web pages say the same thing.
Everything platform-specific is settled here: {tokens} are filled in, the
generated tables are built, and pictures that don't exist for the platform
are left out.

Expanded blocks ("t" is the type):
  chapter {id, title}          h {text}              p {text}
  list {items, ordered}        tips {items}          qa {items: [{q, a}]}
  note {text}                  table {head, rows, icon}   (a cell may be {img})
  step {n, title, lead, text, img, alt}
  shot {img, alt, title, caption}       shots {imgs: [{img, label}], caption}
  event {kind, name, text, effect, times}
Inline text keeps **bold** and *italic*.
"""
import json
import os
import re
import sys

import yaml

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
C = os.path.join(ROOT, "content")

ALT_SCENES = ("02-lobby", "08-develop-town", "09-develop-map")   # MS-DOS: CGA beside PCjr


def load(name):
    return yaml.safe_load(open(os.path.join(C, name)))


def sentence(s):
    """the game's lower-case message, in sentence case for print."""
    s = s.replace("$%d", "$…")
    out, cap = [], True
    for ch in s:
        if cap and ch.isalpha():
            out.append(ch.upper())
            cap = False
        else:
            out.append(ch)
        if ch in ".!?":
            cap = True
    s = "".join(out)
    s = re.sub(r"\birata\b", "Irata", s)
    return s.replace("M.U.L.E. ", "M.U.L.E. ").replace("M.u.l.e.", "M.U.L.E.")


def money(x):
    sign = "+" if x > 0 else "−"
    a = [abs(x) * m for m in (25, 50, 75, 100)]
    return f"{sign}${a[0]} / ${a[1]} / ${a[2]} / ${a[3]}"


class Ed:
    def __init__(self, pid):
        pl = load("platforms.yaml")
        self.id = pid
        self.p = pl[pid]
        self.rules = load("rules.yaml")
        self.ev = load("events.yaml")
        self.man = load("manual.yaml")
        self.shots = self.p["shots"]
        self.manifest = self._manifest(self.shots)
        alt = self.p.get("shots_alt")
        self.alt = alt
        self.alt_manifest = self._manifest(alt) if alt else None

    @staticmethod
    def _manifest(t):
        f = os.path.join(ROOT, "assets", t, "manifest.json")
        return json.load(open(f)) if os.path.exists(f) else {"scenes": [], "icons": []}

    # -- pictures --
    def scene(self, n):
        if n in self.manifest["scenes"]:
            return f"assets/{self.shots}/screens/{n}.png"
        return None

    def alt_scene(self, n):
        if self.alt and n in ALT_SCENES and n in self.alt_manifest["scenes"]:
            return {"img": f"assets/{self.alt}/screens/{n}.png", "label": self.p.get("alt_name", "")}
        return None

    def icon(self, n):
        if n in self.manifest["icons"]:
            return {"img": f"assets/{self.shots}/icons/{n}.png"}
        return ""

    # -- text --
    def fill(self, s):
        k = dict(self.p["keys"])
        k["name"] = self.p["name"]
        k["machine"] = self.p["machine"]
        k["file"] = self.p["file"]
        return re.sub(r"\{(\w+)\}", lambda m: str(k.get(m.group(1), m.group(0))), s)

    def wanted(self, b):
        if "only" in b and self.id not in b["only"]:
            return False
        if "except" in b and self.id in b["except"]:
            return False
        return True

    # -- generated blocks --
    def gen(self, g):
        p, r = self.p, self.rules
        if g == "needs":
            return [{"t": "list", "ordered": False, "items": [self.fill(x) for x in p["needs"]]}]
        if g == "file":
            url = p["tnfs"]
            host, path = url[len("tnfs://"):].split("/", 1)
            folder = "/" + path.rsplit("/", 1)[0] + "/"
            return [{"t": "table", "head": ["", ""], "rows": [
                ["Host", f"**{host}**"], ["Folder", folder], ["File", f"**{p['file']}**"],
                ["Full address", url]], "kv": True}]
        if g == "boot":
            return [{"t": "list", "ordered": True, "items": [self.fill(x) for x in p["boot"]]}]
        if g == "notes":
            if not p.get("notes"):
                return []
            return [{"t": "h", "text": f"Notes for the {p['machine']}"},
                    {"t": "list", "ordered": False, "items": [self.fill(x) for x in p["notes"]]}]
        if g == "controls":
            return [{"t": "table", "head": ["Control", "What it does"], "widths": [1, 1.3],
                     "rows": [[", ".join(c[:-1]), c[-1]] for c in p["controls"]]}]   # (an unquoted comma splits the first cell)
        if g == "species-shots":
            first = "02-lobby" if self.scene("02-lobby") else "03-summary"
            imgs = [{"img": self.scene(first), "label": "First four"},
                    {"img": self.scene("17-species-b"), "label": "The other four"}]
            imgs = [i for i in imgs if i["img"]]
            if not imgs:
                return []
            cap = ("All eight species: the four the lobby offers first, and the other four."
                   if len(imgs) == 2 else "Each seat shows its colonist's species.")
            return [{"t": "shots", "imgs": imgs, "caption": cap}]
        if g == "species":
            rows = []
            for s in r["species"]:
                secs = round(101 * s["ptu"] / 60)
                rows.append([f"**{s['name']}**", f"${s['money']:,}", f"about {secs} seconds"])
            rows.append(["*Computer (Mechtron)*", f"${r['computer']['money']:,}", "about 47 seconds"])
            return [{"t": "table", "head": ["Species", "Money", "Full turn"], "rows": rows, "widths": [1.2, 0.8, 1.2]}]
        if g == "terrain":
            rows = []
            for t in r["terrain"]:
                rows.append([self.icon(t["id"]), f"**{t['name']}**", str(t["food"]), str(t["energy"]),
                             str(t["smithore"]), "by deposit" if t["crystite"] == "deposit" else "–"])
            rows.append([self.icon("town"), "**Town**", "–", "–", "–", "–"])
            return [{"t": "table", "icon": True,
                     "head": ["", "Land", "Food", "Energy", "Smithore", "Crystite"], "rows": rows}]
        if g == "outfits":
            o, sp = r["outfit"], r["start_prices"]
            rows = [[self.icon(g), f"**{g.capitalize()}**", f"${o[g]}", f"${sp[g]}"]
                    for g in ("food", "energy", "smithore", "crystite")]
            return [{"t": "table", "icon": True,
                     "head": ["", "M.U.L.E.", "Outfit", "Opening price"], "rows": rows}]
        if g in ("events-good", "events-bad"):
            out = []
            for e in self.ev["good" if g == "events-good" else "bad"]:
                eff = e.get("effect")
                if "x" in e:
                    eff = money(e["x"])
                    if "per" in e:
                        eff += f" for each {e['per']}"
                if e.get("needs"):
                    eff += f" ({e['needs'].lower()})" if "x" in e else ""
                out.append([f"*“{sentence(e['text'])}”*", eff])
            return [{"t": "table", "head": ["The message", "What it does"], "rows": out, "events": True}]
        if g == "events-colony":
            caps = r["colony_caps"]
            return [{"t": "event", "kind": "colony", "name": e["name"], "text": sentence(e["text"]),
                     "effect": e["effect"], "times": caps[e["id"]]} for e in self.ev["colony"]]
        if g == "rating":
            return [{"t": "table", "head": ["", "Colony total", "The verdict"], "widths": [0, 1, 1.8],
                     "rows": [[str(x["n"]), x["total"], f"*“{sentence(x['text'])}”*"] for x in r["rating"]]}]
        if g == "spread":
            return [{"t": "p", "text": "In the table, P is the store's reference price for the good."},
                    {"t": "table", "head": ["Good", "Store buys at", "Store sells at"], "widths": [0.8, 1, 1],
                     "rows": [[f"**{x['good']}**", x["buys"], x["sells"]] for x in r["store_spread"]]}]
        if g == "start":
            sp, ss = r["start_prices"], r["store_start"]
            return [{"t": "table", "head": ["", ""], "kv": True, "rows": [
                ["Each colonist", "$1000 (Flapper $1600, Humanoid $600, computer $1200), 4 Food, 2 Energy"],
                ["The store", f"{ss['food']} Food, {ss['energy']} Energy, {ss['smithore']} Smithore, no Crystite, {ss['mules']} M.U.L.E.s"],
                ["Opening prices", f"Food ${sp['food']}, Energy ${sp['energy']}, Smithore ${sp['smithore']}, Crystite ${sp['crystite']}, M.U.L.E. ${sp['mule']}"],
            ]}]
        if g == "reference":
            o = r["outfit"]
            out = [{"t": "h", "text": "Production per M.U.L.E. (average, before bonuses)"},
                   {"t": "table", "head": ["Land", "Food", "Energy", "Smithore", "Crystite"],
                    "rows": [[t["name"], str(t["food"]), str(t["energy"]), str(t["smithore"]),
                              "deposit (0–4)" if t["crystite"] == "deposit" else "–"] for t in r["terrain"]]},
                   {"t": "h", "text": "The Store"},
                   {"t": "table", "head": ["", "Food", "Energy", "Smithore", "Crystite", "M.U.L.E."],
                    "rows": [["Outfit", f"${o['food']}", f"${o['energy']}", f"${o['smithore']}", f"${o['crystite']}", "–"],
                             ["Opening price"] + [f"${r['start_prices'][k]}" for k in ("food", "energy", "smithore", "crystite", "mule")],
                             ["Opening stock"] + [str(r["store_start"][k]) for k in ("food", "energy", "smithore", "crystite", "mules")],
                             ["Lowest price"] + [f"${r['price_floor'][k]}" for k in ("food", "energy", "smithore", "crystite")] + ["–"]]},
                   {"t": "h", "text": "Month by Month"},
                   {"t": "table", "head": ["Months", "1–3", "4–7", "8–11", "12"],
                    "rows": [["Food for a full turn", "3", "4", "5", "5"],
                             ["Event base amount", "$25", "$50", "$75", "$100"],
                             ["Wampus reward", "$100", "$200", "$300", "$400"],
                             ["Pub base winnings", "$50", "$100", "$150", "$200"]]},
                   {"t": "h", "text": "Limits"},
                   {"t": "list", "ordered": False, "items": [
                       "A plot makes at most 8 units a month.",
                       "Half of leftover Food and a quarter of leftover Energy spoil each month.",
                       "You can hold at most 50 Smithore and 50 Crystite.",
                       "The corral holds up to 14 M.U.L.E.s; each new one uses 2 Smithore.",
                       "Each plot counts $500 towards your score; a M.U.L.E. on it adds its outfit cost plus $35."]}]
            return out
        raise SystemExit(f"unknown gen: {g}")

    # -- the book --
    def expand(self):
        out = []
        n = 0
        for ch in self.man["chapters"]:
            out.append({"t": "chapter", "id": ch["id"], "title": ch["title"]})
            if not ch.get("continue_steps"):
                n = 0
            for b in ch["blocks"]:
                if not self.wanted(b):
                    continue
                if "p" in b:
                    out.append({"t": "p", "text": self.fill(b["p"])})
                elif "h" in b:
                    out.append({"t": "h", "text": self.fill(b["h"])})
                elif "note" in b:
                    out.append({"t": "note", "text": self.fill(b["note"])})
                elif "list" in b:
                    out.append({"t": "list", "ordered": False, "items": [self.fill(x) for x in b["list"]]})
                elif "tips" in b:
                    out.append({"t": "tips", "items": [self.fill(x) for x in b["tips"]]})
                elif "qa" in b:
                    out.append({"t": "qa", "items": [{"q": self.fill(x["q"]), "a": self.fill(x["a"])} for x in b["qa"]]})
                elif "shot" in b:
                    s = b["shot"]
                    img = self.scene(s["scene"])
                    if img:
                        out.append({"t": "shot", "img": img, "alt": self.alt_scene(s["scene"]),
                                    "title": s.get("title", ""), "caption": self.fill(s.get("caption", ""))})
                elif "steps" in b:
                    for st in b["steps"]:
                        if not self.wanted(st):
                            continue
                        n += 1
                        sc = st.get("shot")
                        out.append({"t": "step", "n": n, "title": self.fill(st["title"]),
                                    "lead": self.fill(st.get("lead", "")), "text": self.fill(st.get("text", "")),
                                    "img": self.scene(sc) if sc else None,
                                    "alt": self.alt_scene(sc) if sc else None})
                elif "gen" in b:
                    out += self.gen(b["gen"])
                else:
                    raise SystemExit(f"unknown block in {ch['id']}: {b}")
        return {"platform": self.id, "name": self.p["name"], "long": self.p["long"], "slug": self.p["slug"],
                "shots": self.shots, "title": self.man["title"], "subtitle": self.man["subtitle"],
                "kind": self.man["kind"], "cover": self.scene("01-title") or self.scene("02-lobby"),
                "blocks": out}


def main():
    ids = sys.argv[1:] or load("platforms.yaml")["order"]
    os.makedirs(os.path.join(ROOT, "build"), exist_ok=True)
    for pid in ids:
        d = Ed(pid).expand()
        json.dump(d, open(os.path.join(ROOT, "build", pid + ".json"), "w"), indent=1, ensure_ascii=False)
        print(pid, len(d["blocks"]), "blocks")


if __name__ == "__main__":
    main()
