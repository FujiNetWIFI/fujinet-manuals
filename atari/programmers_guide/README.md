# Programming the FujiNet — for the Atari 8-bit computers

A programmer's guide and **command reference** for driving the FujiNet WiFi
peripheral two ways from an Atari home computer:

* the **high road** — the **N: handler (NDEV)**, a CIO device handler, driven
  from **Atari BASIC** (and any language that speaks CIO); and
* the **low road** — the **SIO bus itself**, driven from **6502 assembly**.

It is the developer companion to *Getting Started with FujiNet — Owner's Guide
for the Atari 400/800*, and borrows that book's visual language: Futura Extra
Bold heads over full-bleed black bands, Rockwell body, the genuine Atari ROM
character set for screens, and the tumbling data cubes off the 1050 booklet —
styled after the Atari home-computer and technical manuals of 1980–1982.

Build output: **`fujinet-programmers-guide-atari.pdf`** (8½ × 11 in, ~44 pp).

## What's inside

1. **Two Roads to the FujiNet** — CIO/NDEV vs. direct SIO, and the devices on the bus.
2. **Getting the N: Handler** — where to get NDEV (the handler disk, any DOS disk,
   or built from source), how to load it, and the **DOS 2 / DUP limitation**.
3. **The N: Device from BASIC** — `OPEN`/`INPUT`/`PRINT`/`GET`/`PUT`/`STATUS`/`CLOSE`,
   device specs, open modes, translation, the `DVSTAT` PEEKs, the PROCEED interrupt.
4. **The XIO Commands** — the complete NDEV special-command set, including **XIO 15**,
   the put-buffer flush implemented inside NDEV itself. BASIC examples throughout.
5. **Talking to SIO Directly** — the DCB, `SIOV`, `DSTATS` direction, the command
   frame and ACK/COMPLETE handshake, and a reusable `SIOCALL` primitive in 6502.
6. **The Network Device — SIO Reference** — every `N:` command with parameters and
   6502 examples.
7. **The Fuji Control Device — SIO Reference** — mounts, hosts, slots, WiFi, app
   keys, directory browsing, utilities — the whole device NDEV cannot reach.
8. **Telling Time** — the Fuji `GET TIME` command and the APETime clock device.
9. **What NDEV Cannot Reach** — the honest gaps (the entire Fuji device, a few
   network sub-commands, the 128-byte buffer), framed as future improvements.
10. **Other Languages Through CIO** — the Assembler/Editor cartridge, Atari Logo, and beyond.
11. **FujiNet from Atari Logo** — reaching `N:` through `.DEPOSIT`/`.CALL` and a page-6 stub.
12. **FujiNet in Action!** — the `NIO.ACT` library, which drives SIO directly, in full.
13. Appendices: **error codes**, a complete **command quick reference**, the
    **complete NDEV handler source listing**, and a **netcat** in Atari BASIC.

A **GitHub wiki** version of the same material lives in
[`wiki/`](wiki/FujiNet-Programming-Guide-for-the-Atari.md).

## Source-verified

Every command byte, parameter, payload and error number is taken verbatim from the
FujiNet sources, not from memory:

* **firmware** — `fujinet-firmware`: the SIO bus in `lib/bus/sio/`, the device
  handlers in `lib/device/sio/` (`network.cpp`, `sioFuji.cpp`) and the shared
  `lib/device/fujiDevice.cpp`, the command list in `include/fujiCommandID.h`, and
  the device ids in `include/fujiDeviceID.h`;
* **the handler** — `fujinet-nhandler` (`handler/src/ndev.s`), reproduced whole in
  Appendix C;
* **Action!** — the `NIO.ACT` network I/O library.

CIO and SIO facts (the IOCB and DCB layouts, `CIOV`/`SIOV`, the command frame and
its ACK/NAK/COMPLETE/ERROR bytes) are drawn from the Atari 400/800 OS ROM source
listing. The assembly is in the syntax common to `ca65` and MADS.

## Building

Requires [Typst](https://typst.app) 0.13+ (the Makefile looks on `PATH`, then in
`~/.local/bin`):

```sh
make            # build the PDF
make watch      # rebuild automatically while editing manual.typ
make preview    # render every page as PNG into preview/ for proofing
make clean
```

## Fonts and listings

`fonts/` carries the same faces as the Atari Owner's Guide: Futura Extra Bold and
Futura LT (heads and labels), Rockwell Std (body), Harry Fat (the ATARI-logo cover
face), and EightBit Atari (the genuine ROM character set, for screen transcripts).
Program listings are set in DejaVu Sans Mono. `listings/` holds the verbatim source
the manual includes at build time — `ndev.s` (the handler) and `NIO.ACT` (the
Action! library, with its ATASCII line endings converted to LF for reading).
Fonts are passed to Typst with `--font-path fonts`.
