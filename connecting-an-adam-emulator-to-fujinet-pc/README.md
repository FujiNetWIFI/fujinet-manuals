# Connecting an Emulator to FujiNet-PC

A developer / engineering manual for **adding FujiNet support to a
vintage-computer emulator**, by carrying the emulated machine's peripheral bus
over a socket to the **real FujiNet firmware** running as a desktop application
(`fujinet-pc`) — the *Bus over IP* model pioneered by Atari's NetSIO.

It is a worked example. It takes one real emulator — **ADAMEm**, a Coleco ADAM
emulator (`adamem_sdl`) — and one real FujiNet build — **fujinet-pc** compiled
for the ADAM target (`fujinet-pc-adam`) — and walks through every change that
made them talk: the protocol, the seam, the master state machine, the device
routing, the boot handshake, and the hard-won pitfalls. The assumption is that
the reader knows their own emulator's code; the goal is to teach the reasoning
so they can repeat it on the machine they maintain.

The chain it covers end to end: **the model → the bus's wire protocol → finding
the seam → the socket → the master state machine → device routing → the boot
handshake → the build → five reliability pitfalls → a platform-agnostic
recipe.**

Two formats, same content:

| Format | File |
| --- | --- |
| Print PDF (Typst) | `connecting-an-emulator-to-fujinet-pc.pdf` |
| GitHub wiki (Markdown) | `wiki/Connecting-an-Emulator-to-FujiNet-PC.md` |

## Building the PDF

Requires [Typst](https://typst.app/) 0.13+ (tested with 0.14.2).

```sh
make            # -> connecting-an-emulator-to-fujinet-pc.pdf
make watch      # live recompile
make preview    # PNG of every page in preview/
make clean
```

Fonts are vendored in `fonts/` (Nimbus Sans for heads, Nimbus Roman for body,
Source Code Pro for listings — all from gsfonts / Adobe Source) and supplied to
Typst with `--font-path fonts`, so the build is self-contained. `pdffonts` on
the output shows only those three families — no fallback interlopers.

**No photos.** Every figure is a native Typst diagram (architecture flows,
packet/DCB byte-fields, and full sequence diagrams for each handshake), drawn
by helpers in `manual.typ`. The wiki edition renders the same handshakes as
Mermaid `sequenceDiagram` blocks, which GitHub wikis display inline. There is
no `images/` content to supply — see `FIGURES.md`.

## Source-verified

Unlike a tutorial written from memory, every packet field, register value,
timeout, command-line flag, and source excerpt was transcribed from the live
project sources in the workspace:

- **adamem_sdl** — the Coleco ADAM emulator being adapted. The bridge lives in
  `AdamNet.c` / `AdamNet.h` (TCP transport + the AdamNet master state machine),
  `Coleco.c` (the `UpdateDCB()` intercept and `UpdateFujiNet()` translator),
  `ADAMEm.c` (the `-fujinet [port]` option and boot handshake), and
  `Makefile.SDL`. The five integration commits (`d0f79b0`, `30248a5`,
  `117fc14`, `63a8b72`, `fda05e7`) are the worked example, change by change.
- **fujinet-pc-adam** — the FujiNet firmware built as a PC application for the
  ADAM target. The peripheral side of the socket is
  `lib/hardware/NetAdamNet.*` (the stream IOChannel + half-duplex local echo)
  and `lib/bus/adamnet/*` (transport selection, the 300 µs response deadline,
  idle handling). Commit `b0e57228b` added the ADAM PC target and the
  RTOS/`fnFile` shims.
- **fujinet-firmware** — the canonical AdamNet bus and device firmware the PC
  build derives from; the wire-protocol definitions in
  `lib/bus/adamnet/adamnet.h` are the reference for Part II.
- **fujinet-emulator-bridge** — the Atari NetSIO precedent for "Bus over IP,"
  which the ADAM work mirrors.

Where a path is still experimental (e.g. the character-device DCB-to-wire
mapping), the text says so plainly.

## What it is not

It is not a FujiNet build manual, and not an end-user setup guide for any
platform's CONFIG program (those are separate manuals in this repo). It is for
the person writing the bridge.

## Keeping the two formats in sync

`manual.typ` (PDF) and `wiki/Connecting-an-Emulator-to-FujiNet-PC.md` are
maintained by hand. When you change one, update the other; the wiki is a
faithful Markdown rendering of the same chapters, with Mermaid in place of the
Typst sequence diagrams.
