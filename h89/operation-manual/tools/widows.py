#!/usr/bin/env python3
"""widows.py -- kept for `make check` symmetry with the other manuals; the
two-column checks live in layoutcheck.py, which this runs."""
import os, subprocess, sys
sys.exit(subprocess.call([sys.executable, os.path.join(os.path.dirname(__file__), "layoutcheck.py")] + sys.argv[1:]))
