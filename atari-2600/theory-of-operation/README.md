# FujiNet for the Atari 2600 — Theory of Operation

An engineering description of the Atari 2600 FujiNet: the Rev0 cartridge board,
the firmware on its two microcontrollers, and the console programs that use it.
Written for an engineer who knows the 6507 and the TIA and wants to know what
the cartridge does with the bus it is given, how the two chips divide the work,
and what has and has not been proven. It is not a programming manual; that is
the *Programmer's Handbook* beside it.

FujiNet Engineering Series style (Nimbus Sans / Nimbus Roman / Source Code Pro),
with the cartridge's own 3×5 font (VCS Screen) for the one text-grid mockup.

## Building

Requires [Typst](https://typst.app) 0.15 or newer and the vendored fonts in
`fonts/`.

```sh
make            # -> fujinet-2600-theory-of-operation.pdf
make watch      # rebuild on save
make preview    # a PNG per page at 120 ppi, into preview/
```

Check with `pdffonts` that only the vendored families are embedded.

## Layout

```
manual.typ      front matter, page chrome, the #include list
lib.typ         preamble, callouts, status tags, memory-map / sequence / timing helpers
parts/          one file per Part, plus the appendices
images/sch/     the Rev0 schematic sheets, cropped from the KiCad PDF export
images/         board renders, layout SVGs, MAME screens (from the handbook), logo
fonts/          vendored fonts
```

## Status tags

Every quantitative claim carries one: **verified in emulation**, **host test**,
**verified in CAD**, **design value, unmeasured**, or **not yet implemented**.
No part of the design has run on a physical Atari 2600. Chapter 31 lists what
that leaves unproven, including five defects in the firmware source found
while this document was written and confirmed against the cited lines.

## Sources of truth

| Source | Path / repo | Revision |
|---|---|---|
| Cartridge firmware, 6502 clients, MAME device, tests | `fujinet-firmware` `pico/atari-2600/` | branch `2600-experiment`, `7432186c0`, 2026-09-27 |
| Adapter firmware (RS232 bus, USB transport, media, pin map) | `fujinet-firmware` `lib/`, `include/`, `src/` | same |
| Rev0 board: README, BOM, KiCad project, renders | `fujinet-hardware` `ATARI-2600/Fujiversal-Atari2600/` | branch `atari2600-rev0`, `84a8c09`, 2026-09-27 |
| CONFIG | `fujinet-config` `atari-2600/` | branch `add-atari-2600`, `b4e3805` |
| Battleship | `fujinet-battleship` `atari2600/` | `9de5ef6` |
| Combat, network patch | `fujinet-2600-combat` | see Chapter 29 |
| Bus timing bounds | MOS 6500 family datasheet, AC characteristics at 1 MHz | — |

The 2024 FujiPlusCart prototype in `fujinet-hardware` is deliberately not
described; only Rev0 is.
