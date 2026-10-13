#!/usr/bin/env python3
"""mkcmds.py FIRMWARE_TREE

Read the firmware's command enum (include/fujiCommandID.h) and its device
IDs (include/fujiDeviceID.h) and write

  src/asm/inc/fncmd.inc   z80asm equates, one per command (FUJI_..., NET_...)
  data/cmds.json          {"commands": [{name, value, group}], "devices": [...]}

so the book's assembly programs use the firmware's own names and numbers.
"""
import json
import os
import re
import sys

tree = sys.argv[1]
book = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
src = open(os.path.join(tree, "include", "fujiCommandID.h")).read()
body = src[src.index("enum class CMD"):]
body = body[:body.index("} fujiCommandID_t")]
cmds = []
for m in re.finditer(r"^\s*([A-Z][A-Z0-9_]*)\s*=\s*(0x[0-9A-Fa-f]+|'.'|\d+)\s*,?\s*(//.*)?$", body, re.M):
    name, val = m.group(1), m.group(2)
    if val.startswith("'"):
        v = ord(val[1])
    else:
        v = int(val, 0)
    group = name.split("_")[0]
    cmds.append({"name": name, "value": v, "group": group,
                 "comment": (m.group(3) or "").lstrip("/ ").strip()})

dsrc = open(os.path.join(tree, "include", "fujiDeviceID.h")).read()
dsrc = dsrc[dsrc.index("#else"):dsrc.index("#endif /* BUILD_ADAM */")]   # the non-Adam IDs
devs = []
for m in re.finditer(r"^\s*([A-Z][A-Z0-9_]*)\s*=\s*(0x[0-9A-Fa-f]+|\d+)", dsrc, re.M):
    devs.append({"name": "DEV_" + m.group(1), "value": int(m.group(2), 0)})

with open(os.path.join(book, "src", "asm", "inc", "fncmd.inc"), "w") as f:
    f.write("; fncmd.inc -- the FujiNet firmware's command numbers, made by\n")
    f.write("; tools/mkcmds.py from include/fujiCommandID.h (fn-h89). Do not edit.\n\n")
    for d in devs:
        f.write("%-32s equ 0x%02X\n" % (d["name"], d["value"]))
    f.write("\n")
    for c in cmds:
        f.write("%-32s equ 0x%02X%s\n" % (c["name"], c["value"],
                ("    ; " + c["comment"]) if c["comment"] else ""))
json.dump({"commands": cmds, "devices": devs},
          open(os.path.join(book, "data", "cmds.json"), "w"), indent=1)
print("mkcmds: %d commands, %d device ids" % (len(cmds), len(devs)))
