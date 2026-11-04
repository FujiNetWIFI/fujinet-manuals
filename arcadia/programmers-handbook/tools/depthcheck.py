#!/usr/bin/env python3
"""depthcheck.py -- the deepest the 2650's return stack can go, counted
the long way round.

The firmware's tools/checkdepth.py builds its call graph from BSTA/BSTR
alone, one node per label. That misses two ways a routine reaches
another without a call of its own: falling through into the next label
(FNCOMMIT runs on into FNCM1, where its BSTA is) and branching to it
(a tail BCTA, or a BCFA,EQ FAIL from inside a subroutine, runs the
target at the depth the branch was taken). So its figure is a lower
bound. This one reads the program as AS does -- INCLUDEs in place,
macros expanded -- and gives every label three kinds of edge:

    a call (BSTA, BSTR)                     the target, one deeper
    a branch (BCTA, BCFR, BDRR, BIRR ...)   the target, the same depth
    falling through                         the next label, the same depth

The depth of a chain is counted as checkdepth.py counts it: the root
itself is 1, each call adds one (a chain of 8 uses 7 of the RAS's 8
entries). Recursion, and an indirect call or branch (BSXA, BXA, ZBSR,
ZBRR, *ptr) that cannot be followed, are reported -- except through a
pointer word the program defines with DWBE, whose target it follows, as
CONFIG's zero-page vectors (ZBSR *ZMSTART) are.

    depthcheck.py [--max N] [-I dir ...] program.asm
"""
import os
import re
import sys

CALLS = {"BSTA", "BSTR", "BSFA", "BSFR", "BSNA", "BSNR"}
BRANCHES = {"BCTA", "BCTR", "BCFA", "BCFR", "BDRA", "BDRR", "BIRA", "BIRR",
            "BRNA", "BRNR"}
INDIRECT = {"BSXA", "BXA", "ZBSR", "ZBRR"}
LABEL = re.compile(r"^([A-Za-z_.][\w.]*)(:|\s)")


def strip(line):
    out, q = [], None
    for ch in line:
        if q:
            out.append(ch)
            if ch == q:
                q = None
        elif ch in "\"'":
            q = ch
            out.append(ch)
        elif ch == ";":
            break
        else:
            out.append(ch)
    return "".join(out).rstrip()


def read(path, dirs, macros, out):
    base = os.path.dirname(path)
    body = None
    for raw in open(path, encoding="latin-1"):
        line = strip(raw)
        if body is not None:
            if re.match(r"^\s*ENDM\b", line, re.I):
                macros[body[0]] = body[1]
                body = None
            else:
                body[1].append(line)
            continue
        m = re.match(r"^([A-Za-z_]\w*)\s+MACRO\b", line, re.I)
        if m:
            body = (m.group(1).upper(), [])
            continue
        m = re.match(r'^\s*INCLUDE\s+"([^"]+)"', line, re.I)
        if m:
            for d in [base] + dirs:
                p = os.path.join(d, m.group(1))
                if os.path.exists(p):
                    read(p, dirs, macros, out)
                    break
            else:
                sys.exit(f"depthcheck: {path}: no {m.group(1)}")
            continue
        out.append(line)


def expand(lines, macros):
    out = []
    for line in lines:
        m = re.match(r"^(\S*?:?)\s+([A-Za-z_]\w*)\b", line)
        if m and m.group(2).upper() in macros:
            if m.group(1):
                out.append(m.group(1))
            out.extend(expand(macros[m.group(2).upper()], macros))
        else:
            out.append(line)
    return out


def vectors(lines):
    # a pointer word, NAME: DWBE TARGET -- what an indirect call goes to
    vec = {}
    for line in lines:
        m = re.match(r"^([A-Za-z_.][\w.]*):?\s+DWBE\s+([A-Za-z_.][\w.]*)\s*$", line, re.I)
        if m:
            vec[m.group(1).upper()] = m.group(2).upper()
    return vec


def graph(lines, vec):
    nodes, edges, order, problems = {}, {}, [], []
    cur, ended = "(reset)", False
    order.append(cur)
    edges[cur] = []
    for line in lines:
        m = LABEL.match(line)
        if m and not re.match(r"^\S+\s+(EQU|SET|=)\b", line, re.I):
            name = m.group(1).upper()
            if name not in edges:
                edges[name] = []
                order.append(name)
            if not ended:
                edges[cur].append((name, 0, "fall"))
            cur, ended = name, False
            line = line[m.end():] if m.group(2) == ":" else line[len(m.group(1)):]
        parts = line.split(None, 1)
        if not parts:
            continue
        op = parts[0].upper()
        mn, _, cond = op.partition(",")
        arg = parts[1].strip() if len(parts) > 1 else ""
        if mn in ("ORG", "PHASE"):
            ended = True               # a new origin: no falling into it
            continue
        if mn in INDIRECT or ((mn in CALLS or mn in BRANCHES) and arg.startswith("*")):
            if not cond and "," in arg and mn not in ("ZBSR", "ZBRR"):
                cond, arg = arg.split(",", 1)
            ptr = re.split(r"[\s,+\-]", arg.strip().lstrip("*"))[0].upper()
            call = mn in CALLS or mn in ("ZBSR", "BSXA")
            if mn in ("ZBRR", "BXA") or (mn in BRANCHES and cond.upper() == "UN"):
                ended = True           # an unconditional jump, wherever to
            if ptr in vec and mn not in ("BXA", "BSXA"):
                edges[cur].append((vec[ptr], 1 if call else 0, "call" if call else "branch"))
            else:
                problems.append(f"{cur}: indirect {line.strip()}")
            continue
        if mn in CALLS or mn in BRANCHES:
            if not cond and "," in arg:            # BCTA UN,START
                cond, arg = arg.split(",", 1)
            tgt = re.split(r"[\s,+\-]", arg.strip())[0].upper()
            if tgt and tgt != "$" and re.match(r"^[A-Z_.]", tgt):
                edges[cur].append((tgt, 1 if mn in CALLS else 0,
                                   "call" if mn in CALLS else "branch"))
            if mn in BRANCHES and cond.upper() == "UN":
                ended = True
        elif mn in ("RETC", "RETE") and cond.upper() == "UN":
            ended = True
        elif mn == "HALT":
            ended = True
    return edges, order, problems


def components(edges):
    # Tarjan's strongly connected components
    index, low, stack, on, comp, n, comps = {}, {}, [], set(), {}, [0], []

    def strong(v):
        index[v] = low[v] = n[0]
        n[0] += 1
        stack.append(v)
        on.add(v)
        for w, _, _ in edges.get(v, ()):
            if w not in edges:
                continue
            if w not in index:
                strong(w)
                low[v] = min(low[v], low[w])
            elif w in on:
                low[v] = min(low[v], index[w])
        if low[v] == index[v]:
            c = []
            while True:
                w = stack.pop()
                on.discard(w)
                comp[w] = len(comps)
                c.append(w)
                if w == v:
                    break
            comps.append(c)

    sys.setrecursionlimit(10000)
    for v in edges:
        if v not in index:
            strong(v)
    return comp, comps


def deepest(edges, notes):
    # A cycle through a call is recursion -- unless it is closed by a branch
    # to a label nothing calls: a jump back to the top level from inside a
    # subroutine, which leaves the frames under it on the 2650's circular
    # return stack to be overwritten. Such branches are noted and dropped.
    called = {w for v in edges for w, k, _ in edges[v] if k}
    while True:
        comp, comps = components(edges)
        bad = [(v, w) for v in edges for w, k, _ in edges[v]
               if k and w in comp and comp[w] == comp[v]]
        if not bad:
            break
        cand = [(v, w) for v in edges for w, k, kind in edges[v]
                if kind == "branch" and w in comp and comp[w] == comp[v]
                and w not in called and comp[v] == comp[bad[0][0]]]
        if not cand:
            raise ValueError(f"recursion through {bad[0][0]} -> {bad[0][1]}")
        # the top level is where the most jumps go: drop those into it first
        into = {}
        for v in edges:
            for w, _, kind in edges[v]:
                if kind == "branch":
                    into.setdefault(w, set()).add(v)
        top = max({w for _, w in cand}, key=lambda w: (len(into.get(w, ())), w))
        for v in edges:
            if any(e[0] == top and e[2] == "branch" for e in edges[v]) and \
                    comp.get(v) == comp[top]:
                edges[v] = [e for e in edges[v] if not (e[0] == top and e[2] == "branch")]
                notes.append(f"{v} jumps back to {top}, which nothing calls: "
                             f"the frames under it are left to be overwritten")
    memo = {}

    def depth(c):
        if c in memo:
            return memo[c]
        best, path = 0, []
        for v in comps[c]:
            for w, k, _ in edges[v]:
                if w not in comp or comp[w] == c:
                    continue
                d, p = depth(comp[w])
                if d + k > best:
                    best, path = d + k, ([v] + (p or [w])) if k else p
        memo[c] = (best, path)
        return memo[c]

    best, chain = 0, []
    for c in range(len(comps)):
        d, p = depth(c)
        if d >= best:
            best, chain = d, p
    return best + 1, chain


def main():
    args, dirs, hard = sys.argv[1:], [], 8
    files = []
    while args:
        a = args.pop(0)
        if a == "--max":
            hard = int(args.pop(0))
        elif a == "-I":
            dirs.append(args.pop(0))
        else:
            files.append(a)
    if len(files) != 1:
        sys.exit(__doc__.strip())
    lines, macros = [], {}
    read(files[0], dirs, macros, lines)
    edges, _, problems = graph(expand(lines, macros), vectors(lines))
    for p in problems:
        print(f"depthcheck: {files[0]}: {p}", file=sys.stderr)
    notes = []
    try:
        d, chain = deepest(edges, notes)
    except ValueError as e:
        print(f"depthcheck: {files[0]}: {e}", file=sys.stderr)
        return 1
    for t in notes:
        print(f"depthcheck: note: {t}", file=sys.stderr)
    name = os.path.basename(files[0])
    text = " -> ".join(chain) if chain else "(no calls)"
    if d > hard:
        print(f"depthcheck: {name}: FAIL depth {d} > {hard}: {text}")
        return 1
    print(f"depthcheck: {name}: ok, depth {d}: {text}")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
