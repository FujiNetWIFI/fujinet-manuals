# Programming the FujiNet — for the Apple II

A programmer's guide and **command reference** for driving the FujiNet
WiFi peripheral from 6502 assembly language over SmartPort. It is the
developer companion to *Getting Started with FujiNet*, and borrows that
book's visual language — cream stock, warm red rules, Helvetica heads,
the wide "scholar's margin" — styled after Apple's own technical
reference manuals of the mid-1980s:

* serif body in **Apple Garamond** (ITC Garamond Condensed), Apple's
  corporate face;
* program listings and register dumps set in the genuine **Apple II
  character set** (Print Char 21), in tinted full-bleed panels with a red
  punch-card rule;
* a reference-entry component — command name, a red chip giving the
  SmartPort call and code byte, a payload table, a `Returns` line, and a
  short listing — used for every command in the three device chapters.

Build output: **`fujinet-programmers-guide-apple2.pdf`** (7½ × 9 in, the
Apple manual trim, ~49 pp).

## What's inside

1. **The SmartPort Connection** — finding the dispatcher, the calling
   sequence, the four call primitives, error handling.
2. **Finding the FujiNet, Shaping a Command** — device discovery by type,
   the DIB, and the payload length-header convention.
3. **The Network Device (`N:`)** — device specs, open/close/read/write/
   status, JSON, HTTP, TCP/UDP, filesystem ops.
4. **The Fuji Control Device** — WiFi, host/device slots, mounting,
   directory browsing, app keys, hashing, QR codes.
5. **The Clock Device** — time formats and time zones.
6. Appendices: **error codes**, a complete **command quick reference**,
   and a working **netcat** in 6502.

## Source-verified

Every command code, parameter, payload layout, and error number is taken
verbatim from the FujiNet sources, not from memory:

* **firmware** — `fujinet-firmware`: the SmartPort bus in `lib/bus/iwm/`
  (`iwm.h`, `sp.inc` constants), the device handlers in `lib/device/iwm/`
  (`iwmFuji.cpp`, `network.cpp`, `clock.cpp`), and the master command
  list in `include/fujiCommandID.h`;
* **client** — `fujinet-lib`: the Apple II SmartPort glue in
  `apple2/apple2-6502/bus/` and the per-command payloads in
  `apple2/src/fn_fuji/` and `apple2/src/fn_network/`.

The assembly is in **`ca65`** syntax (the `cc65` suite), the same
toolchain that builds `fujinet-lib`, so the examples can be assembled and
linked against the library.

## Building

Requires [Typst](https://typst.app) 0.13+ (the Makefile looks on `PATH`,
then in `~/.local/bin`):

```sh
make            # build the PDF
make watch      # rebuild automatically while editing manual.typ
make preview    # render every page as PNG into preview/ for proofing
make clean
```

## Fonts

`fonts/` carries the faces the manual needs: Apple Garamond, Helvetica,
and Print Char 21 (the Apple II 40-column charset, used here for code as
well as the occasional green-phosphor screen). They are passed to Typst
with `--font-path fonts`.
