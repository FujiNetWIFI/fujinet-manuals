# Programming the FujiNet — for the Coleco ADAM

A programmer's guide and **command reference** for driving the FujiNet
WiFi peripheral from **Z80 assembly language** over **AdamNet**. It is the
developer companion to *Getting Started with FujiNet CONFIG for the Coleco
ADAM*, and borrows that book's visual language — the silver cover with its
rising pinstripes and rainbow masthead, ITC Avant Garde Gothic body,
Serpentine bold-oblique heads, Handel Gothic display — styled after Coleco's
own ADAM manuals of 1983.

It teaches both roads to a FujiNet from the ADAM:

* the **EOS road** — the Elementary Operating System's jump table
  (`START_WR_CH_DEV`/`START_RD_CH_DEV`, `FIND_DCB`, …); and
* the **CP/M road** — finding the Peripheral Control Block at `$FEC0`,
  walking to the FujiNet's Device Control Block, and driving it directly by
  poking its status byte — the way a CP/M program must, with no EOS present.

Every command is shown both ways.

Build output: **`fujinet-programmers-guide-adam.pdf`** (6 × 9 in, ~40 pp).

## What's inside

1. **The AdamNet Connection** — the 62,500-baud one-wire bus, the master
   6801, the PCB and DCB, device IDs, and finding the FujiNet's DCB by hand.
2. **Shaping a Transaction** — the write-then-read pattern, the EOS jump
   table, the four call primitives (EOS and direct-DCB), error handling.
3. **The Network Device (`N:`)** — device specs, open/close/read/write/
   status, JSON, HTTP, TCP/UDP, filesystem ops, credentials.
4. **The Fuji Control Device** — WiFi, host/disk slots, mounting, directory
   browsing, app keys, adapter config, hashing/Base64/QR.
5. **Telling Time** — the clock, read from the Fuji device with one command.
6. Appendices: **error codes**, a complete **command quick reference**, and
   a working **netcat** in Z80 (CP/M, direct DCB).

A **Github wiki** version of the same material lives in
[`wiki/`](wiki/FujiNet-Programming-Guide-for-the-Coleco-ADAM.md).

## Source-verified

Every command byte, DCB layout, EOS entry point and error number is taken
verbatim from the FujiNet sources, not from memory:

* **firmware** — `fujinet-firmware`: the AdamNet bus in `lib/bus/adamnet/`
  (`adamnet.h`/`.cpp`), the device handlers in `lib/device/adamnet/`
  (`adamFuji.cpp`, `network.cpp`), the device IDs in `include/fujiDeviceID.h`,
  and the master command list in `include/fujiCommandID.h`;
* **ADAM side** — the EOS C binding (`eos.h`) and its assembly
  implementations (EOS jump-table entry points), the `fujinet-lib` ADAM
  target (`adam/src/`), and the FujiNet ADAM CP/M library
  (`fujinet-adam-cpm-lib`), which drives the DCB directly under CP/M.

The assembly is Zilog Z80 mnemonics in the syntax common to `z88dk`'s
assembler and `zmac`.

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

`fonts/` carries the faces the manual needs, the same as the ADAM Set-Up
Manual: ITC Avant Garde Gothic (body), Serpentine (heads), and Handel Gothic
D (display). Program listings and DCB dumps are set in DejaVu Sans Mono (a
system font). They are passed to Typst with `--font-path fonts`.
