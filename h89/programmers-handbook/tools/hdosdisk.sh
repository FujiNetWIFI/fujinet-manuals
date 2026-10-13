#!/usr/bin/env bash
# A 100K H17 disk image for HDOS 2.0 holding the given files.
#   tools/hdosdisk.sh OUT.H8D "LABEL" FILE...
# Uses fujinet-h89's tools/hdosfs.py (FUJINET_H89 = its checkout).
# Copyright (C) 2026 Thomas Cherryhomes
# SPDX-License-Identifier: GPL-3.0-or-later
set -euo pipefail
source "$(dirname "$0")/rig.sh"
hdosdisk "$@"
echo "hdosdisk: $1"
