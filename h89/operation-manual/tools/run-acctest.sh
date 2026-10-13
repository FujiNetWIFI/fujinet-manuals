#!/usr/bin/env bash
# Key the book's acceptance test into each Heath monitor ROM on FujiNet Go
# H89's headless machine, exactly as the book tells the reader to, and check
# the display the book promises:
#   - with the card:    a line "12 <text> H", then the H: prompt
#   - card absent:      "H" alone (no 1)
#   - HA-88-3 at 320Q:  "H" alone (the 8250 answers, not an 82C55)
# plus the MTR-90 port check (200, then 206) and the flash-mode program.
#
#   tools/run-acctest.sh [screens-dir]
#
# Needs: ~/Workspace/fujinet-go-h89-desktop built with the FujiNet runtime,
# its tools/roms (MAME's h89.zip + heath_tlb.zip), build/acctest.keys and
# build/flashmode.keys (make acctest).
set -uo pipefail
cd "$(dirname "$0")/.."
G="${H89GO:-$HOME/Workspace/fujinet-go-h89-desktop}"
RUN="$G/build/core/h89_session_run"
ROMS="$G/tools/roms"
OUT="${1:-build/acctest}"
mkdir -p "$OUT"; OUT="$(cd "$OUT" && pwd)"   # the FujiNet runtime moves the cwd
KEYS="$(cat build/acctest.keys)"
FLASH="$(cat build/flashmode.keys)"
fail=0

# the screen as text, without the FujiNet log lines
screen() { sed -n '/---- screen ----/,/^\(\[fujinet\] \)\?----------------$/p' | sed 's/^\[fujinet\] //' | sed '1d;$d'; }

run() {   # run NAME MONITOR [--set ...] -- prints the screen
    local name="$1" mon="$2"; shift 2
    "$RUN" --roms "$ROMS" --monitor "$mon" --timeout 30 "$@" \
        --until 'H:' --type 'S040100\r' --type "$KEYS\r" \
        --prompt 'H:' --type 'G040100\r' --wait 3000 --prompt 'H:' \
        --screen --debug card --ppm "$OUT/$name.ppm" > "$OUT/$name.log" 2>&1
    screen < "$OUT/$name.log" > "$OUT/$name.txt"
}

check() { # check NAME REGEX WHAT
    if grep -Eq "$2" "$OUT/$1.txt"; then echo "PASS $1: $3"
    else echo "FAIL $1: $3"; tail -5 "$OUT/$1.txt"; fail=1; fi
}

for mon in 2716_444-40_mtr88.u518 2716_444-62_mtr89.u518 \
           2732_444-84_mtr90.u518 2732_444-142_mtr90.u518; do
    n="${mon%.u518}"; n="${n#*_}"
    run "pass-$n" "$mon"
    check "pass-$n" '^12 .* H$' "12, the reply, H"
    grep -m1 '^12 ' "$OUT/pass-$n.txt" | sed 's/^/      /'
done

run absent 2732_444-142_mtr90.u518 --set slot.p504=empty
check absent '^H$' "card absent: H alone"
! grep -q '^1' "$OUT/absent.txt" || { echo "FAIL absent: printed a checkpoint"; fail=1; }

run conflict 2732_444-142_mtr90.u518 --set slot.p504=h88-3
check conflict '^H$' "HA-88-3 at 320Q: H alone"

run mem16 2716_444-62_mtr89.u518 --set machine.memory=16
check mem16 '^12 .* H$' "16K machine"

# MTR-90's own port commands: no program at all
"$RUN" --roms "$ROMS" --monitor 2732_444-142_mtr90.u518 --timeout 30 \
    --until 'H:' --type 'O323,300\r' --prompt 'H:' --type 'I322\r' --prompt 'H:' \
    --type 'O322,006\r' --prompt 'H:' --type 'I322\r' --prompt 'H:' \
    --screen --ppm "$OUT/ports.ppm" > "$OUT/ports.log" 2>&1
screen < "$OUT/ports.log" > "$OUT/ports.txt"
check ports '^ *2[04]0$' "In 322 after the mode set reads 200 (or 240)"
check ports '^ *2[04]6$' "In 322 after Out 322,006 reads 206 (or 246)"
cat "$OUT/ports.txt" | sed 's/^/      /'

# flash mode on a monitor without Out
"$RUN" --roms "$ROMS" --monitor 2716_444-62_mtr89.u518 --timeout 30 \
    --until 'H:' --type 'S040100\r' --type "$FLASH\r" \
    --prompt 'H:' --type 'G040100\r' --wait 2000 --prompt 'H:' \
    --screen --debug card > "$OUT/flash.log" 2>&1
screen < "$OUT/flash.log" > "$OUT/flash.txt"
check flash '^ *H$' "flash-mode program returns with H"
grep -A3 -- '---- card ----' "$OUT/flash.log" | sed 's/^\[fujinet\] /      /'

# screens for the book: the first entries being keyed, on MTR-90 and MTR-88
for mon in 2732_444-142_mtr90.u518 2716_444-40_mtr88.u518; do
    n="${mon%.u518}"; n="${n##*_}"
    "$RUN" --roms "$ROMS" --monitor "$mon" --timeout 30 \
        --until 'H:' --type 'S040100\r' --type "$(echo "$KEYS" | cut -d' ' -f1-6) " --wait 500 \
        --ppm "$OUT/keying-$n.ppm" > "$OUT/keying-$n.log" 2>&1
done
CELLS="$(cd "$OUT/../cells" 2>/dev/null && pwd || { mkdir -p build/cells; cd build/cells; pwd; })"
FONTROM="$(pwd)/build/roms/2716_444-29_h19font.u420"
for p in "$OUT"/pass-444-142_mtr90.ppm "$OUT"/pass-444-40_mtr88.ppm "$OUT"/absent.ppm \
         "$OUT"/ports.ppm "$OUT"/keying-*.ppm; do
    n="$(basename "$p" .ppm)"
    python3 tools/ppm2cells.py "$FONTROM" "$p" "$CELLS/mtr-$n.json"
done

exit $fail
