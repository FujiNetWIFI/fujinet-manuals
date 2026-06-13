# The FujiNet WiFi Peripheral — Owner's Guide (1980–82 edition)

A new-user guide to FujiNet CONFIG on the Atari 8-bit computers,
designed after the **early** Atari home computer manuals:

* *The ATARI 800 Home Computer Owner's Guide* (© 1981, CO60057) —
  cover layout, heavy black headline + full-bleed black band, big
  numbered set-up steps, black "peripheral equipment" showcase page.
* *ATARI 1050 Disk Drive: An Introduction to the Disk Operating
  System* (© 1982, C061529) — silver pinstripe pages, blue condensed
  contents, `COMPUTER:`/`YOU TYPE:` dialogues, blue screen mockups in
  the Atari ROM font, tumbling data-cube illustrations, navy inside
  covers, "What To Do If It Doesn't Work."

This is a sibling of [`../owners_guide/`](../owners_guide/), which
renders the same source-verified content in the later 1983 *800XL
Owner's Guide* style. The GitHub-wiki edition of the content lives
with that project; this one is purely the print artifact.

Build output: **`fujinet-owners-guide-400-800.pdf`** (US Letter, 22 pp).

## Building

Requires [Typst](https://typst.app) 0.13+ (the Makefile looks on
`PATH`, then in `~/.local/bin`):

```sh
make            # build the PDF
make watch      # rebuild automatically while editing manual.typ
make preview    # render every page as PNG into preview/ for proofing
make images     # re-render illustrations from fujinet-hardware STLs
make clean
```

## Illustrations

Unlike the 1983 edition, this guide needs **no photographs**: every
piece of hardware art is rendered from the official 3D models in
[`fujinet-hardware`](https://github.com/FujiNetWIFI/fujinet-hardware)
(`ATARI/FN32ROV-1.7.1/3D/`) by `tools/stl2png.py` — a small
numpy/Pillow rasterizer that produces the flat-color, black-outline
"manual illustration" look of the 1050 booklet (quantized toon
shading + contour extraction). `make images HW=/path/to/3D` re-renders
everything; view angles and part colors are recorded in the Makefile.

CONFIG screens are typeset directly in Typst using the genuine Atari
ROM character set, with text taken verbatim from `fujinet-config`
source — see `FIGURES.md` for the figure manifest and the few
hardware details worth double-checking against a production unit.

## Fonts (vendored in `fonts/`)

| File | Stands in for | License |
|---|---|---|
| FuturaLT-ExtraBold.ttf | masthead, chapter heads, contents entries, step numerals, itemized lists (Typst: family "Futura", `weight: 700`) | commercial (Linotype); for this tribute build only |
| FuturaLT.ttf, FuturaLT-Book.ttf | section heads, captions, keycaps, folios and contents page numbers (Typst: family "Futura", weight 400) | commercial (Linotype) |
| HarryFat.otf | the rainbow cover wordmark and the wildcard art — the same face as the giant ATARI cover letters (Typst: family "Harry", `weight: 900`) | commercial (VGC); from Thom's collection |
| RockwellStd-Light/Regular/Bold.otf | all body text (Light; Bold for run-ins) | commercial (Monotype) |
| EightBit-Atari-Regular.ttf | the Atari 8-bit ROM character set, traced from original bitmaps ([TheRobotFactory/EightBit-Atari-Fonts](https://github.com/TheRobotFactory/EightBit-Atari-Fonts)) | free («GPL spirit», see repo) |

The commercial faces are included for this tribute project's build
only — do not redistribute separately, and consider licenses for
commercial use.

## Content provenance

Function coverage was verified against the `fujinet-config` source
(`src/atari/*` + common code, June 2026) and `fujinet-firmware`
(buttons, LEDs, boot behavior) — same verified content base as
`../owners_guide/`. Screen mockups reproduce the exact strings and
key labels from `src/atari/screen.c`.

ATARI® and the names of ATARI peripherals are trademarks of their
respective owners, used here in loving tribute. FujiNet is not
affiliated with Atari. Distributed under GPLv3 as part of
`fujinet-manuals`.
