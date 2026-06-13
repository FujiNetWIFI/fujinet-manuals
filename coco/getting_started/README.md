# FujiNet Color Computer — Getting Started Manual

A getting-started manual for novice FujiNet users on the TRS-80 Color
Computer, typeset as a faithful tribute to the 1980 Radio Shack
*TRS-80 Color Computer Operation Manual* (26-3001/3002): landscape
10×8 in booklet, Century Schoolbook text, double-rule chapter heads
with the green center ornament, pale-yellow caution boxes, green
gradient end bars, Symptom/Cure troubleshooting tables, and a
starfield cover set in Souvenir.

Content incorporates Rich Stephens' *FujiNet For CoCo: The Basics*,
cross-checked against source:

- **Hardware** — `fujinet-hardware` `Coco/CoCo-FujiNet-Rev000`
  (schematic, READMEs, and the 3D case models, from which the
  illustrations are rendered — see `make images`).
- **CONFIG screens** — typeset cell-for-cell in the genuine MC6847
  character set (Kreative Korp's *Hot CoCo*, free license) with
  strings taken verbatim from `fujinet-config/src/coco/screen.c`,
  including the VDG lowercase-as-inverse-video menu convention, CLS
  fill colors, and semigraphics shadow rows.
- **Behavior** — `fujinet-config` common + coco sources and
  `fujinet-firmware` (DriveWire bus, baud-by-DIP-switch, devices).

## Building

```
make            # fujinet-getting-started-coco.pdf
make watch      # rebuild on save
make preview    # preview/page-NN.png at 72 ppi
make images     # re-render case art from fujinet-hardware STLs
```

Requires Typst 0.13+. Fonts are vendored in `fonts/` (C059 — URW's
Century Schoolbook, free; Monotype Century Schoolbook Bold; Bitstream
Souvenir; Helvetica; Hot CoCo). `make images` additionally needs
python3 + numpy + Pillow and a `fujinet-hardware` checkout.

## Photographs

Four photos are placeholders pending Thom's camera — see
`FIGURES.md` for the shot list. The PDF builds and reads fine with
the placeholder boxes in place.

## Wiki edition

A GitHub-wiki markdown version lives in `wiki/`.
