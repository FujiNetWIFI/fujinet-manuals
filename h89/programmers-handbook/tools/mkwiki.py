#!/usr/bin/env python3
"""mkwiki.py -- the wiki edition: wiki/FujiNet-Programmers-Manual-for-the-
Heathkit-H89.md from its .md.in, with the tables filled from the book's own
data (quickref.json, fwspec/net.json, libref.json, libdesc.json,
errata.json), and its pictures rendered from the book's screens. The
GitHub wiki is one flat folder, so every picture is prefixed h89-prog-.

    tools/mkwiki.py
"""
import json
import os
import re
import shutil
import subprocess

BOOK = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(BOOK, "wiki", "images")
P = "h89-prog-"
TYPST = shutil.which("typst") or os.path.expanduser("~/.local/bin/typst")
J = lambda *p: json.load(open(os.path.join(BOOK, *p)))
PICS = {"netcat": ("crt", "netcat-cpm"), "iss": ("crt", "iss-asm-hdos"),
        "texas": ("crt", "texas-3"), "card": ("card", "card")}

TOP = [
    "**A missing field stops the firmware.** Send every field a command takes, even unused ones.",
    "**One END only.** A frame that starts `C0 C0` is lost, and its bytes go to the modem.",
    "**100 ms between request bytes**, at most; build the request first, then send it.",
    "**FUJI_GET_SSID returns the WiFi password** in plain text.",
    "**FUJI_NEW_DISK always fails** on the H89, after creating an empty file.",
    "**Mounting a .ROM or .BIN file** sends unexpected frames to the H89 before the reply.",
    "**FUJI_RESET has no reply**; wait out the timeout.",
    "**FUJI_COPY_FILE counts host slots from 1**, and fails if a host prefix is set.",
    "**A READ for more than STATUS reports** can fail on TCP and lose what was waiting.",
    "**An HTTP PUT is sent at CLOSE**; a STATUS before CLOSE sends it twice. Mode 0EH sends POST.",
    "**CLOSE_CLIENT's answer is backwards**: NAK when it hung up on a caller.",
    "**UDP STATUS does not count the waiting datagram**; READ anyway.",
    "**A JSON query hitting `[]` stops the firmware**; so does SET_PARSER on a closed channel.",
    "**The modem's replies are not framed**, its AT result text is never sent, and ATCPM crashes.",
    "**The printer truncates its length to 8 bits** and overruns past 320 bytes.",
    "**fujinet-lib**: `FUJI_DIR_ENTRY_IS_DIR` does not compile; `network_json_query` sends 256 bytes "
    "and reads without limit; `clock_get_time` writes one byte past the reply; `port_putc` never "
    "times out.",
    "**z88dk's HDOS start-up**: wrong default load address (4480H), damaged `argv[]`.",
]


def render(key, kind, name):
    out = os.path.join(OUT, P + key + ".png")
    subprocess.run([TYPST, "compile", "--root", BOOK, "--font-path", os.path.join(BOOK, "fonts"),
                    "--ignore-system-fonts", "--ppi", "144", "--input", "kind=" + kind,
                    "--input", "name=" + name, os.path.join(BOOK, "tools", "wikifig.typ"), out],
                   check=True)


def table(head, rows):
    out = ["| " + " | ".join(head) + " |", "|" + "---|" * len(head)]
    for r in rows:
        out.append("| " + " | ".join(str(c).replace("|", "\\|") for c in r) + " |")
    return "\n".join(out)


def main():
    os.makedirs(OUT, exist_ok=True)
    for key, (kind, name) in PICS.items():
        render(key, kind, name)
    shutil.copy(os.path.join(BOOK, "images", "cover-board.png"), os.path.join(OUT, P + "cover-board.png"))

    qr = J("data", "quickref.json")
    parts = []
    for d in qr["devices"]:
        parts.append("### %s (%s)\n" % (d["name"], d["ids"]))
        parts.append(table(["Command", "No.", "Fields", "Payload", "Reply"],
                           [("`%s`" % r["equ"], r["hex"], r["fields"], r["payload"], r["reply"])
                            for r in d["rows"]]))
        parts.append("")
    quick = "\n".join(parts)

    net = J("data", "fwspec", "net.json")
    seen, rows = set(), []
    for s in net["schemes"]:
        if s["scheme"] in seen or s["scheme"] == "summary":
            continue
        seen.add(s["scheme"])
        what = re.sub(r"\s*\([^)]*\.(cpp|h)[^)]*\)", "", s.get("what", "")).strip()
        rows.append(("`%s`" % s["scheme"], what[:150]))
    schemes = table(["Scheme", "What it reaches"], rows)

    lr, ld = J("data", "libref.json"), J("data", "libdesc.json")
    warn = []
    for f in lr["functions"]:
        d = ld.get(f["name"], {})
        if d.get("warning") and f["links"]["hdos"]:
            warn.append(("`%s`" % f["name"], d["warning"].replace("\n", " ")))
    libwarn = table(["Function", "On the H89"], warn)
    unlink = ", ".join("`%s`" % f["name"] for f in lr["functions"]
                       if not (f["links"]["hdos"] and f["links"]["cpm"])) + ", `fn_error`, `_fuji_status`"

    er = J("data", "errata.json")
    src = open(os.path.join(BOOK, "wiki", "FujiNet-Programmers-Manual-for-the-Heathkit-H89.md.in")).read()
    src = (src.replace("{{QUICKREF}}", quick).replace("{{SCHEMES}}", schemes)
              .replace("{{LIBWARN}}", libwarn).replace("{{UNLINKABLE}}", unlink)
              .replace("{{ERRATA_COUNT}}", str(len(er["items"])))
              .replace("{{ERRATA_TOP}}", "\n".join("- " + t for t in TOP)))
    out = os.path.join(BOOK, "wiki", "FujiNet-Programmers-Manual-for-the-Heathkit-H89.md")
    open(out, "w").write(src)
    print("mkwiki: %s (%d lines), %d pictures" % (os.path.relpath(out, BOOK), src.count("\n"),
                                                  len(PICS) + 1))


if __name__ == "__main__":
    main()
