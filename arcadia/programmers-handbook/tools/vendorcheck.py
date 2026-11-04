#!/usr/bin/env python3
"""vendorcheck.py -- what the handbook carries is what it says it carries.

Byte-compares every entry of listings/VENDOR (repo, revision, source,
destination under listings/) with `git show rev:source` in
~/Workspace/<repo>, whatever branch that checkout is on. Notes, without
failing, a source that has changed since its pin.

    tools/vendorcheck.py
"""
import os
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
WS = os.path.expanduser("~/Workspace")


def git(repo, *args, check=True):
    return subprocess.run(["git", "-C", os.path.join(WS, repo)] + list(args),
                          capture_output=True, check=check)


bad = n = 0
moved = []
for line in open(os.path.join(ROOT, "listings", "VENDOR")):
    if not line.strip() or line.startswith("#"):
        continue
    repo, rev, src, dst = line.split()
    n += 1
    want = git(repo, "show", "%s:%s" % (rev, src)).stdout
    path = os.path.join(ROOT, "listings", dst)
    try:
        have = open(path, "rb").read()
    except FileNotFoundError:
        print("MISSING listings/%s (%s %s:%s)" % (dst, repo, rev, src)); bad += 1
        continue
    if have != want:
        print("DIFFERS listings/%s from %s %s:%s" % (dst, repo, rev, src)); bad += 1
    head = "origin/master" if repo == "fujinet-firmware" else "origin/main"
    if git(repo, "diff", "--quiet", rev, head, "--", src, check=False).returncode == 1:
        moved.append("%s %s (since %s)" % (repo, src, rev))
for m in moved:
    print("note: changed upstream: " + m)
print("vendorcheck: %d files, %s" % (n, "all match their pins" if not bad else "%d differ" % bad))
sys.exit(1 if bad else 0)
