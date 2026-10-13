#!/usr/bin/env python3
"""mklibref.py -- every fujinet-lib name an H89 program can use, for Chapter 7.

Reads fujinet-lib's headers (build/fnlib/include) as z88dk sees them for the
H89 -- run through the host's C preprocessor with __H89__ defined, which
selects the same #if branches -- and its sources, and writes
data/libref.json:

  {"functions": [{"name", "kind": "function"|"macro", "proto",
                  "header", "line", "doc", "commands": [...],
                  "links": {"hdos": bool, "cpm": bool}}],
   "constants": {...}}

"kind" macro means the name is a macro over the bus call (FUJICALL_...);
"commands" are the FUJICMD_/NETCMD_/... names it sends; "links" is the
result of linking a program that uses it, for each system (a function
declared but not built for the H89 fails to link).
"""
import json
import os
import re
import subprocess
import tempfile

BOOK = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LIB = os.path.join(BOOK, "build", "fnlib")
INC = os.path.join(LIB, "include")
HEADERS = ["fujinet-fuji.h", "fujinet-network.h", "fujinet-clock.h", "fujinet-qrcode.h",
           "fujinet-appkey.h", "fujinet-bus.h"]
API = re.compile(r"\b((?:fuji|network|clock|qrcode)_\w+)\b")


def cpp(text, extra=()):
    with tempfile.NamedTemporaryFile("w", suffix=".c", delete=False) as f:
        f.write(text)
        name = f.name
    out = subprocess.run(["gcc", "-E", "-D__H89__", "-I", INC] + list(extra) + [name],
                         capture_output=True, text=True)
    os.unlink(name)
    if out.returncode:
        raise SystemExit(out.stderr)
    return out.stdout


def main():
    tu = "#include <stdbool.h>\n#include <stdint.h>\n#include <stddef.h>\n" + \
         "".join('#include "%s"\n' % h for h in HEADERS)
    macros = {}
    for line in cpp(tu, ["-dM"]).split("\n"):
        m = re.match(r"#define ((?:fuji|network|clock|qrcode)_\w+)\(([^)]*)\)\s*(.*)$", line)
        if m:
            macros[m.group(1)] = (m.group(2), m.group(3))
    pre = cpp(tu)
    # prototypes, joined across lines
    flat = re.sub(r"\s+", " ", "\n".join(l for l in pre.split("\n") if not l.startswith("#")))
    protos = {}
    for m in re.finditer(r"(?:extern )?([A-Za-z_][\w ]*?[\s\*]+)((?:fuji|network|clock|qrcode)_\w+)\s*\(([^;{}]*?)\)\s*;", flat):
        protos[m.group(2)] = "%s%s(%s);" % (m.group(1).strip() + " ", m.group(2), m.group(3).strip())
    # where each name is in the headers, and the comment above it
    hdr = {}
    for h in os.listdir(INC):
        if not h.endswith(".h"):
            continue
        lines = open(os.path.join(INC, h), encoding="latin-1").read().split("\n")
        for i, l in enumerate(lines):
            for name in set(API.findall(l)):
                is_def = re.search(r"#define\s+%s\b" % name, l)
                is_proto = re.search(r"^\s*(extern\s+)?[A-Za-z_][\w\s\*]*\b%s\s*\(" % name, l)
                if (is_def or is_proto) and (name not in hdr or (is_proto and hdr[name][3])):
                    j, doc = i - 1, []
                    while j >= 0 and (lines[j].strip().startswith(("*", "/*", "//")) or lines[j].strip().endswith("*/")):
                        doc.insert(0, lines[j].strip())
                        j -= 1
                    text = " ".join(re.sub(r"^(/\*\*?|\*/|\*|//)\s?", "", d).strip() for d in doc)
                    hdr[name] = (h, i + 1, re.sub(r"\s+", " ", text.replace("*/", "")).strip(),
                                 bool(is_def))
    # what each function sends: from its source
    srcs = {}
    for d in ("common", "bus/h89"):
        for f in os.listdir(os.path.join(LIB, d)):
            if f.endswith(".c"):
                srcs[os.path.join(d, f)] = open(os.path.join(LIB, d, f), encoding="latin-1").read()
    CMD = re.compile(r"\b((?:FUJICMD|NETCMD|CLOCKCMD|CLKCMD|APETIMECMD)_\w+)\b")
    # and what the firmware surveys say each sends (command -> library name)
    BYSPEC = {}
    for spec in ("fuji", "net", "misc"):
        d = json.load(open(os.path.join(BOOK, "data", "fwspec", spec + ".json")))
        cl = d.get("commands", []) + [c for dv in d.get("devices", []) for c in dv["commands"]]
        for c in cl:
            for lib in c.get("fujinet_lib", []) or []:
                for sym in API.findall(lib.get("symbol", "")):
                    BYSPEC.setdefault(sym, []).append(c["name"])
    names = sorted(set(macros) | set(protos))
    funcs = []
    for n in names:
        kind = "macro" if n in macros else "function"
        cmds, where_src = [], None
        if kind == "macro":
            cmds = CMD.findall(macros[n][1])
            proto = "#define %s(%s)" % (n, macros[n][0])
        else:
            proto = protos[n]
            for path, text in srcs.items():
                m = re.search(r"\b%s\s*\([^;]*?\)\s*\{" % re.escape(n), text)
                if m:
                    where_src = path
                    body = text[m.end():]
                    body = body[:body.find("\n}") if "\n}" in body else 3000]
                    cmds = CMD.findall(body)
                    break
        h = hdr.get(n, (None, None, "", False))
        # the firmware's names for the commands (FUJICMD_X is FUJI_X)
        norm = lambda c: re.sub(r"^(FUJI|NET|APETIME|CLOCK|DISK)CMD_", r"\1_", c)
        cmds = sorted({norm(c) for c in cmds} | set(BYSPEC.get(n, [])))
        funcs.append({"name": n, "kind": kind, "proto": proto, "header": h[0], "line": h[1],
                      "doc": h[2][:600], "commands": sorted(set(cmds)), "source": where_src,
                      "expands": macros[n][1][:200] if kind == "macro" else None})
    # link probe: one program that takes the address of every function
    links = probe([f["name"] for f in funcs if f["kind"] == "function"])
    for f in funcs:
        f["links"] = links.get(f["name"], {"hdos": True, "cpm": True})
    json.dump({"functions": funcs}, open(os.path.join(BOOK, "data", "libref.json"), "w"), indent=1)
    bad = [f["name"] for f in funcs if not all(f["links"].values())]
    print("mklibref: %d names (%d macros), %d do not link: %s"
          % (len(funcs), sum(f["kind"] == "macro" for f in funcs), len(bad), " ".join(bad)))


def probe(fnames):
    work = os.path.join(BOOK, "build", "linkprobe")
    os.makedirs(work, exist_ok=True)
    src = os.path.join(work, "probe.c")
    with open(src, "w") as f:
        f.write("#include <stdint.h>\n#include <stdbool.h>\n")
        for h in HEADERS:
            f.write('#include <%s>\n' % h)
        f.write("void *probe_table[] = {\n")
        for n in fnames:
            f.write("    (void *)%s,\n" % n)
        f.write("};\nint main(void) { return probe_table[0] != 0; }\n")
    res = {}
    env = dict(os.environ, PATH=os.path.expanduser("~/Workspace/z88dk/bin") + ":" + os.environ["PATH"],
               ZCCCFG=os.path.expanduser("~/Workspace/z88dk/lib/config"))
    for os_, args in (("hdos", ["+hdos", "-startup=3", "-Cz--abs", "-create-app"]),
                      ("cpm", ["+cpm", "-create-app"])):
        lib = os.path.join(LIB, "r2r", "h89-" + os_)
        cmd = ["zcc"] + args + ["-D__H89__", "-I" + INC, "-L" + lib, "-lfujinet.h89-%s.lib" % os_,
                                "-o", os.path.join(work, "probe_" + os_), src]
        out = subprocess.run(cmd, capture_output=True, text=True, cwd=BOOK, env=env)
        missing = set(re.findall(r"undefined symbol: _(\w+)", out.stderr + out.stdout))
        for n in fnames:
            res.setdefault(n, {})[os_] = n not in missing
    return res


if __name__ == "__main__":
    main()
