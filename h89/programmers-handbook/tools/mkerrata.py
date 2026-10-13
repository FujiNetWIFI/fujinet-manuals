#!/usr/bin/env python3
"""mkerrata.py -- every way the H89's FujiNet software differs from what a
programmer would expect, in one list, for errata.md and the Appendix.

Sources:
  data/fwspec/{fuji,net,misc}.json   the firmware surveys' traps, each cited
                                     to a line of fn-h89 (or fujinet-lib)
  data/errata-extra.json             found while making the book: z88dk,
                                     fujinet-lib, fujinet-pc, and the
                                     exercisers' surprises

Writes data/errata.json ({"items": [{id, area, subject, text, cite}]}) and
errata.md. The ids (F1, N1, D1, L1, Z1, P1 ...) are stable as long as the
sources keep their order, so the book can refer to them.
"""
import json
import os
import re

BOOK = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
J = lambda *p: json.load(open(os.path.join(BOOK, *p)))
CITE = re.compile(r"\(((?:fn-h89|fujinet-lib)/[^)]*|[\w/.-]+\.(?:cpp|h|c)[^)]*)\)\s*\.?\s*$")


def split_cite(t):
    t = t.strip()
    m = CITE.search(t)
    if m:
        return t[:m.start()].strip().rstrip(":;,"), m.group(1)
    m = re.search(r"\(([^()]*\.(?:cpp|h|c):[\d,\- ]+[^()]*)\)", t)
    if m:
        return (t[:m.start()] + t[m.end():]).strip(), m.group(1)
    return t, ""


def main():
    items = []
    areas = (("F", "FujiNet device (70H)", J("data", "fwspec", "fuji.json")["commands"]),
             ("N", "Network channels (71H-78H)", J("data", "fwspec", "net.json")["commands"]))
    for prefix, area, cmds in areas:
        n = 0
        for c in cmds:
            for t in c.get("traps", []) or []:
                n += 1
                text, cite = split_cite(t)
                items.append({"id": "%s%d" % (prefix, n), "area": area, "subject": c["name"],
                              "text": text, "cite": cite})
    misc = J("data", "fwspec", "misc.json")
    n = 0
    for key in ("framing", "params", "replies", "errors"):
        for t in misc["bus"].get(key, []):
            if not re.search(r"(?i)crash|abort|silen|lost|never|not |no reply|trap|bug|garbage|wrong",
                             t):
                continue
            n += 1
            text, cite = split_cite(t)
            items.append({"id": "B%d" % n, "area": "The bus", "subject": key, "text": text,
                          "cite": cite})
    letters = {"disk": "D", "clock": "C", "printer": "R", "modem": "M", "cpm": "X"}
    names = {"disk": "Disk drives (31H-38H)", "clock": "Clock (45H)", "printer": "Printer (40H)",
             "modem": "Modem (50H)", "cpm": "CP/M device (5AH)"}
    for d in misc["devices"]:
        n = 0
        for c in d["commands"]:
            for t in c.get("traps", []) or []:
                n += 1
                text, cite = split_cite(t)
                items.append({"id": "%s%d" % (letters[d["device"]], n), "area": names[d["device"]],
                              "subject": c["name"], "text": text, "cite": cite})
    extra_path = os.path.join(BOOK, "data", "errata-extra.json")
    if os.path.exists(extra_path):
        for e in json.load(open(extra_path))["items"]:
            items.append(e)
    # group by area: the firmware's areas in the order generated, then the rest in TAIL's order;
    # a stable sort keeps each area's own order
    TAIL = ["fujinet-lib", "fujinet-lib's test programs", "z88dk (HDOS)", "z88dk",
            "fujinet-pc (the book's stand-in for the card)"]
    head = []
    for it in items:
        if it["area"] not in TAIL and it["area"] not in head:
            head.append(it["area"])
    order = head + TAIL
    items.sort(key=lambda it: order.index(it["area"]))
    json.dump({"items": items}, open(os.path.join(BOOK, "data", "errata.json"), "w"), indent=1)

    out = ["# Errata: the H89 FujiNet's software, as this manual found it", "",
           "Everything below behaves differently from what a programmer would",
           "reasonably expect. The manual documents today's behaviour, with a WARNING",
           "and a workaround where it matters, so its examples work as printed. This",
           "list is the place to check when a newer firmware, fujinet-lib or z88dk",
           "comes out: each entry cites the line of source it comes from.", "",
           "Versions: fn-h89 `h89-disk-fixes` 7ab84ae64; fujinet-lib",
           "`h89-setup-after-reset` d08f584 (the entries were found in 9e6d4dd, which",
           "differs only in port_init: L22); z88dk v2.4-1231 (3bd06cad56); fujinet-pc",
           "built from the same firmware.", ""]
    area = None
    for it in items:
        if it["area"] != area:
            area = it["area"]
            out += ["", "## " + area, ""]
        cite = " (`%s`)" % it["cite"] if it.get("cite") else ""
        out.append("- **%s %s**: %s%s" % (it["id"], it["subject"], it["text"], cite))
    open(os.path.join(BOOK, "errata.md"), "w").write("\n".join(out) + "\n")
    print("mkerrata: %d items" % len(items))


if __name__ == "__main__":
    main()
