#!/usr/bin/env python3
"""checkfacts.py -- does the guide still match the game server?

usage: checkfacts.py [--game ~/Workspace/fujinet-multiplayer-mule]

Compares content/*.yaml with fujinet-multiplayer-mule/internal/rules: every
event and rating message must appear word for word in the Go source, and
the numbers the guide prints (prices, stock, money, yields, event limits)
must match the constants. Exits 1 on any mismatch.
"""
import argparse
import os
import re
import sys

import yaml

HERE = os.path.dirname(os.path.abspath(__file__))
C = os.path.join(os.path.dirname(HERE), "content")
bad = 0


def check(what, ok):
    global bad
    if not ok:
        bad += 1
        print("MISMATCH:", what)


def arr(src, name):
    m = re.search(name + r"\s*=\s*\[[^\]]*\]\w*\{([^}]*)\}", src)
    return [int(x) for x in m.group(1).split(",")] if m else None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--game", default=os.path.expanduser("~/Workspace/fujinet-multiplayer-mule"))
    a = ap.parse_args()
    R = os.path.join(a.game, "internal", "rules")
    go = {f: open(os.path.join(R, f)).read() for f in os.listdir(R) if f.endswith(".go")}
    allgo = "\n".join(go.values())
    ev = yaml.safe_load(open(os.path.join(C, "events.yaml")))
    ru = yaml.safe_load(open(os.path.join(C, "rules.yaml")))

    def gostr(s):           # a message as it is written in Go source
        return s.replace('"', '\\"')
    for e in ev["good"] + ev["bad"]:
        check(f"player event text: {e['text']}", gostr(e["text"]) in go["events_player.go"])
        if "x" in e and "per" not in e:
            check(f"event amount x{e['x']}: {e['text']}",
                  re.search(re.escape(gostr(e["text"])) + r'", x: ' + str(e["x"]) + r"\b", go["events_player.go"]))
    for e in ev["colony"]:
        check(f"colony event text: {e['text']}", gostr(e["text"]) in go["events_colony.go"])
    check("ship text", ev["ship"] in go["events_colony.go"])
    for r in ru["rating"]:
        check(f"rating {r['n']} text", r["text"] in go["store.go"])
    check("13 good + 9 bad events", len(ev["good"]) == 13 and len(ev["bad"]) == 9)

    caps = re.search(r"colonyEventCaps = \[NumColonyEvents\]int\{([^}]*)\}", go["events_colony.go"]).group(1)
    caps = [int(x) for x in caps.split(",")]
    order = ["pest", "pirates", "acid", "quake", "sunspot", "meteorite", "radiation", "fire"]
    check("colony event limits", [ru["colony_caps"][k] for k in order] == caps[1:9])

    c = go["constants.go"]
    g4 = ("food", "energy", "smithore", "crystite")
    check("outfit costs", arr(c, "OutfitCost") == [ru["outfit"][k] for k in g4])
    check("store stock", arr(c, "StoreInitStock") == [ru["store_start"][k] for k in g4])
    check("opening prices", arr(c, "StoreInitPrice") == [ru["start_prices"][k] for k in g4])
    check("price floors", arr(c, "StoreMinPrice") == [ru["price_floor"][k] for k in g4])
    check("price cap", re.search(r"StoreMaxPrice\s*=\s*(\d+)", c).group(1) == str(ru["price_cap"]))
    check("corral", re.search(r"StoreInitMules\s*=\s*(\d+)", c).group(1) == str(ru["store_start"]["mules"]))
    check("M.U.L.E. price", re.search(r"InitMulePrice\s*=\s*(\d+)", c).group(1) == str(ru["start_prices"]["mule"]))
    check("player goods", arr(c, "PlayerInitGoods")[:2] == [ru["start_goods"]["food"], ru["start_goods"]["energy"]])
    check("computer money", "return 1200" in c and ru["computer"]["money"] == 1200)
    money = {s["name"]: s["money"] for s in ru["species"]}
    check("Flapper money", "case Flapper:\n\t\treturn 1600" in c and money["Flapper"] == 1600)
    check("Humanoid money", "case Humanoid:\n\t\treturn 600" in c and money["Humanoid"] == 600)
    check("others' money", "return 1000" in c and all(v == 1000 for k, v in money.items() if k not in ("Flapper", "Humanoid")))
    ptu = {k: int(re.search(k + r"\s*=\s*(\d+)", allgo).group(1)) for k in ("PTUDefault", "PTUFlapper", "PTUHumanoid")}
    btu = int(re.search(r"\bBTU\s*=\s*(\d+)", allgo).group(1))
    sp = {s["name"]: s["ptu"] for s in ru["species"]}
    check("PTU", sp["Mechtron"] == ptu["PTUDefault"] * btu and sp["Flapper"] == ptu["PTUFlapper"] * btu
          and sp["Humanoid"] == ptu["PTUHumanoid"] * btu)

    m = go["mapgen.go"]
    yp = re.search(r"case Plain:\s*return \[NumGoods\]int\{(\d+), (\d+), (\d+),", m).groups()
    yr = re.search(r"case River:\s*return \[NumGoods\]int\{(\d+), (\d+), (\d+), (\d+)\}", m).groups()
    ym = re.search(r"case Mountain:\s*return \[NumGoods\]int\{(\d+), (\d+), 1 \+ p.Mountains,", m).groups()
    t = {x["id"]: x for x in ru["terrain"]}
    check("plains yield", [str(t["plain"][k]) for k in ("food", "energy", "smithore")] == list(yp))
    check("river yield", [str(t["river"]["food"]), str(t["river"]["energy"])] == list(yr[:2]) and yr[2:] == ("0", "0"))
    check("mountain yield", all([str(t[f"mountain{n}"]["food"]), str(t[f"mountain{n}"]["energy"])] == list(ym)
                                and t[f"mountain{n}"]["smithore"] == 1 + n for n in (1, 2, 3)))
    check("food need", "return 3" in c and "return 4" in c and "return 5" in c
          and [x["need"] for x in ru["food_need"]] == [3, 4, 5])
    check("event chance 27.5%", re.search(r"PlayerEventChance\s*=\s*275", c))

    print("facts:", "OK" if not bad else f"{bad} mismatch(es)")
    sys.exit(1 if bad else 0)


if __name__ == "__main__":
    main()
