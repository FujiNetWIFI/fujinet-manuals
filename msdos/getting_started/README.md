# FujiNet RS-232 for MS-DOS — Guide to Operations

A *Getting Started* manual for the **RS-232 FujiNet** network adapter on
the IBM Personal Computer and compatibles running MS-DOS, aimed at the
first-time FujiNet user.

It is typeset as an affectionate tribute to the 1981 IBM Personal Computer
**Guide to Operations** (P/N 6025000): the deep-wine cover with its striped
masthead and "Hardware Reference Library" slug, Press Roman (Times) body,
bold serif heads, big step numerals, `Note:`/`CAUTION:` callouts, the black
bleeder tabs down the fore-edge, and section-relative folios (`Setup 2-7`).

The scan used as the styling reference is in `../learn/`.

## Output

`make` builds **`fujinet-guide-to-operations-msdos.pdf`** — a single
portrait booklet (7 × 9 in) covering:

1. **Introduction** — what the FujiNet does; what you supply; a tour of the
   adapter
2. **Setup** — connecting to the serial port, installing the two drivers in
   `CONFIG.SYS`, the first power-on, and a mini-test
3. **Operations** — the CONFIG program, joining WiFi, host/drive slots,
   loading disks, the drive letters, `FMOUNT`, the `N:` network utilities
   (`NCOPY`/`NGET`/`NPUT`), `FNSHARE`, and the printer
4. **Problem Determination Procedures** — symptom/cure tables
5. **Reference** — driver settings, CONFIG keys, command summary, network
   protocols, disk-image sizes
6. **Relocate** — moving the system
7. **Getting Help** — the community

## Sources of truth

Every feature is cross-referenced against source, not docs:

- **Hardware** — `fujinet-hardware/RS232/RS232-Rev1b` (schematic, BOM, STLs):
  ESP32-S3, DB-9 female edge connector, USB-C power, push-push microSD,
  white WiFi LED + orange BUS LED, knurled thumbscrews.
- **Drivers & utilities** — `fujinet-msdos` (`sys`, `printer`, `fmount`,
  `fnshare`, `ncopy`, `nget`, `nput`): `FUJINET.SYS` block driver,
  `FUJIPRN.SYS` INT 17h printer, `FUJI_PORT`/`FUJI_BPS`/`NOTIME` settings.
- **CONFIG screens** — `fujinet-config/src/msdos`: the EDIT.EXE-style
  80×25 colour UI (blue desktop, light-grey bars), 8 host slots, 8 device
  slots, the WiFi scan, the disk browser, and the mount screen. Screen text
  is reproduced verbatim and typeset in the **genuine IBM PC ROM character
  set** (Px437 IBM CGA, from int10h.org).

## Fonts (vendored in `fonts/`)

| Family                | Use                          | Source |
|-----------------------|------------------------------|--------|
| Nimbus Roman          | body & heads (Press Roman / Times equivalent) | URW (GPL + font exception), `/usr/share/fonts/gsfonts` |
| Px437 IBM CGA         | the CONFIG screens           | int10h.org *Oldschool PC Font Pack* (CC BY-SA 4.0) |
| Px437 IBM VGA 8x16    | DOS command listings         | int10h.org *Oldschool PC Font Pack* (CC BY-SA 4.0) |

## Illustrations

All line art is rendered through `tools/stl2png.py` (flat-shaded, black
contours), matching the rest of the FujiNet manual series:

- **The FujiNet** is assembled from the published `RS232-Rev1b` case STLs by
  `tools/make_case.py`, which closes the two printable shells into a clamshell,
  mirrors the single knurled knob into a pair, and generates the DB-9
  connector and the LED light-pipes.
- **The IBM 5150** (system unit, display, keyboard, rear panel) is a
  parametric model built by `tools/make_pc.py`.

Regenerate everything with `make images` (requires `python3`, `numpy`,
`pillow`).

## Build

```sh
make            # build the PDF
make watch      # rebuild on save
make preview    # per-page PNGs in preview/
make images     # re-render all illustrations from the models
make clean
```

Requires [Typst](https://typst.app) 0.13+. Fonts are loaded with
`--font-path fonts` (handled by the Makefile).

## A note on photographs

This edition needs **no photographs** — all hardware is rendered from
models. A few optional photo slots exist in the `photos` dictionary at the
top of `manual.typ` (and are listed in `FIGURES.md`); they render as
placeholders until a real image is supplied and the flag is flipped to
`true`.

## Licence & trademarks

Manual text and art: © 2026 the FujiNet community; copy freely. FujiNet is a
community project and is **not** affiliated with, endorsed by, or sponsored
by IBM. "IBM" and "Personal Computer" are used only to describe the
computers this adapter works with; the styling is a tribute.
