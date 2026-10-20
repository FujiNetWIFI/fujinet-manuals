#!/usr/bin/env python3
"""vendorcheck.py -- what the handbook carries is what it says it carries.

Byte-compares every entry of listings/VENDOR with `git show rev:path` in
its repository (~/Workspace/<repo>; fujinet-firmware is read from the
fn-studio2-board checkout, whose own branch does not matter). A directory
entry compares every file git holds there; build output is ignored. Then
each block of listings/asm/osk.inc between a "; >>> repo rev path" line and
"; <<<" must appear, line for line, in that file at that revision. Notes
(without failing) when a repository has moved past its pin.

    tools/vendorcheck.py
"""
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
WS = os.path.expanduser("~/Workspace")
REPO = {"fujinet-firmware": os.path.join(WS, "fn-studio2-board")}


def repo(name):
    return REPO.get(name, os.path.join(WS, name))


def git(r, *args):
    return subprocess.run(["git", "-C", repo(r)] + list(args), capture_output=True,
                          check=True).stdout


bad = n = 0
moved = set()
for line in open(os.path.join(ROOT, "listings", "VENDOR")):
    if not line.strip() or line.startswith("#"):
        continue
    r, rev, src, dst = [f.strip() for f in line.split("|")]
    files = [src]
    if src.endswith("/"):
        files = [f for f in git(r, "ls-tree", "-r", "--name-only", rev, src).decode().split("\n") if f]
    for f in files:
        n += 1
        d = os.path.join(ROOT, dst, f[len(src):]) if src.endswith("/") else os.path.join(ROOT, dst)
        want = git(r, "show", "%s:%s" % (rev, f))
        try:
            have = open(d, "rb").read()
        except FileNotFoundError:
            print("MISSING %s (%s %s:%s)" % (os.path.relpath(d, ROOT), r, rev, f)); bad += 1
            continue
        if have != want:
            print("DIFFERS %s from %s %s:%s" % (os.path.relpath(d, ROOT), r, rev, f)); bad += 1
    try:
        head = git(r, "rev-parse", "--short", "origin/HEAD" if r != "fujinet-firmware" else "origin/master").decode().strip()
        if not head.startswith(rev[:7]) and subprocess.run(
                ["git", "-C", repo(r), "diff", "--quiet", rev, head, "--", src],
                capture_output=True).returncode:
            moved.add("%s: %s has moved past %s (now %s)" % (r, src, rev, head))
    except subprocess.CalledProcessError:
        pass

# the derived blocks
osk = open(os.path.join(ROOT, "listings", "asm", "osk.inc")).read().split("\n")
i = blocks = 0
while i < len(osk):
    m = re.match(r"; >>> (\S+) (\S+) (\S+?):", osk[i])
    if not m:
        i += 1
        continue
    j = osk.index("; <<<", i)
    body = osk[i + 1:j]
    src = git(m.group(1), "show", "%s:%s" % (m.group(2), m.group(3))).decode().split("\n")
    k = len(body)
    if not any(src[a:a + k] == body for a in range(len(src) - k + 1)):
        print("DERIVED osk.inc block at line %d is not in %s %s:%s" % (i + 1, *m.groups())); bad += 1
    blocks += 1
    i = j + 1
for note in sorted(moved):
    print("note: " + note)
print("vendorcheck: %d files, %d derived blocks, %s" % (n, blocks, "all match" if not bad else "%d differ" % bad))
sys.exit(1 if bad else 0)
