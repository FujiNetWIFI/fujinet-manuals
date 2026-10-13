#!/usr/bin/env python3
"""Chapter 6's table of fujinet-lib's own tests.

Reads the H19 screens of the runs (build/runs/libtest-NAME-OS/screen.txt, and
libtestfix-NAME-OS for the programs rebuilt with their H89 faults corrected, and
libtestslow-NAME-OS for those also linked with TIMEOUT_SLOW raised to 60 s),
takes each program's last summary line, and writes data/libtests.json:
{"tests": [{"name", "hdos", "cpm", "note"}]}. The notes come from
data/libtests-notes.json; "{fix}" and "{slow}" in a note become those runs' results.

  python3 tools/mklibtests.py
"""
import json, os, re, sys

BOOK = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RUNS = os.path.join(BOOK, "build", "runs")

ALL = re.compile(r"=== ALL (\d+) TESTS PASSED, (\d+) SKIPPED ===", re.I)
SOME = re.compile(r"=== RESULTS: (\d+) PASSED, (\d+) SKIPPED, (\d+) FAILED, (\d+) TOTAL ===", re.I)


def result(run):
    """(passed, total, skipped) from a run's screen, or None."""
    path = os.path.join(RUNS, run, "screen.txt")
    if not os.path.exists(path):
        return None
    text = open(path).read()
    m = ALL.findall(text)
    if m:
        n, s = map(int, m[-1])
        return (n, n, s)
    m = SOME.findall(text)
    if m:
        p, s, f, t = map(int, m[-1])
        return (p, t, s)
    sys.exit("mklibtests: no summary line in %s" % path)


def cell(r):
    if r is None:
        return "not run"
    p, t, s = r
    out = "all %d" % t if p == t else "%d of %d" % (p, t)
    return out + (", %d skipped" % s if s else "")


def main():
    notes = json.load(open(os.path.join(BOOK, "data", "libtests-notes.json")))
    tests = []
    for name in notes["order"]:
        h, c = result("libtest-%s-hdos" % name), result("libtest-%s-cpm" % name)
        note = notes["notes"].get(name, "")
        for key, prefix in (("{fix}", "libtestfix"), ("{slow}", "libtestslow")):
            if key in note:
                fh, fc = result("%s-%s-hdos" % (prefix, name)), result("%s-%s-cpm" % (prefix, name))
                if fh == fc:
                    fix = cell(fh) + " under both"
                else:
                    fix = "%s under HDOS, %s under CP/M" % (cell(fh), cell(fc))
                note = note.replace(key, fix)
        tests.append({"name": name.upper(), "hdos": cell(h), "cpm": cell(c), "note": note})
    json.dump({"tests": tests}, open(os.path.join(BOOK, "data", "libtests.json"), "w"), indent=1)
    for t in tests:
        print("%-9s %-10s %-10s %s" % (t["name"], t["hdos"], t["cpm"], t["note"]))


if __name__ == "__main__":
    main()
