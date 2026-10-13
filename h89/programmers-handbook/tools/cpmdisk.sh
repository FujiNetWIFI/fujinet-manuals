#!/usr/bin/env bash
# A 100K H17 disk image for Heath CP/M 2.2.04 holding the given files.
#   tools/cpmdisk.sh OUT.H8D FILE.COM [FILE...]
# Uses z88dk-appmake +cpmdisk -f hz89, then fujinet-h89's cpm-dir-fixup.py.
# Copyright (C) 2026 Thomas Cherryhomes
# SPDX-License-Identifier: GPL-3.0-or-later
set -euo pipefail
source "$(dirname "$0")/rig.sh"
cpmdisk "$@"
echo "cpmdisk: $1"
