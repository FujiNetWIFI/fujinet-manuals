# Getting Started with FujiNet — for the Apple II (1984 edition)

A new-user guide to the FujiNet WiFi peripheral and its CONFIG
program on the Apple II family, designed after the **1984 *Apple IIc
Owner's Manual*** (the Snow White era):

* cream stock, warm red accents, and the wide "scholar's margin"
  carrying notes, figure callouts, and **Important!** / **▲ Warning**
  tags;
* serif chapter openers over thin red rules, Helvetica-bold section
  heads over thick ones, square black bullets, drawn keycaps —
  with all serif text in **Apple Garamond** (ITC Garamond
  Condensed), Apple's corporate face, rather than the 1984
  original's Century Old Style;
* a Preface that teaches the book's own visual cues, per-chapter
  summaries, an *Ask FujiNet* style troubleshooting appendix, and a
  "Tell Apple" card homage at the back.

Build output: **`fujinet-getting-started-apple2.pdf`**
(7½ × 9 in, the Apple manual trim).

## Building

Requires [Typst](https://typst.app) 0.13+ (the Makefile looks on
`PATH`, then in `~/.local/bin`):

```sh
make            # build the PDF
make watch      # rebuild automatically while editing manual.typ
make preview    # render every page as PNG into preview/ for proofing
make clean
```

## Illustrations

CONFIG screens are **typeset, not screenshotted**: they are set in
the genuine Apple II character set (Print Char 21) with text taken
verbatim from `fujinet-config` source (`src/apple2/screen.c`), shown
in green-phosphor monochrome like the period Monitor IIc.

Hardware photographs are Thom's department — every photo location
currently renders as a labeled placeholder box. See `FIGURES.md` for
the shot list and status.

## Fonts (vendored in `fonts/`)

| File | Role | License |
|---|---|---|
| AppleGaramond-Light{,Italic}.ttf | all body text, chapter titles, contents, folios — the genuine Apple Garamond is the *Light* cut of ITC Garamond Condensed | commercial (ITC/Apple); for this tribute build only |
| AppleGaramond-Bold{,Italic}.ttf | bold emphasis and TOC chapter entries | same |
| Helvetica.ttf, Helvetica-Bold.ttf | section heads, figure tags, keycap legends — the IIc manual's heads | commercial (Linotype/Monotype); for this tribute build only |
| PrintChar21.ttf | the genuine Apple II 40-column screen character set ([Kreative Korp "Ultimate Apple II Font"](https://www.kreativekorp.com/software/fonts/apple2/)) | Kreative free license (`PrintChar21-FreeLicense.txt`) |
| PRNumber3.ttf | the 80-column variant (kept for future use) | same |

The commercial faces are included for this tribute project's build
only — do not redistribute separately, and consider licenses for
commercial use.

## Content provenance

Feature coverage was verified against the `fujinet-config` source
(`src/apple2/*` + common code, June 2026) and `fujinet-firmware`
(`lib/bus/iwm`, `lib/device/iwm`, `lib/media/apple`: boot behavior,
SmartPort device names, Disk II write support), plus the
[Apple II & III FujiNet Quickstart Guide](https://github.com/FujiNetWIFI/fujinet-firmware/wiki/Apple-II-&-III-FujiNet-Quickstart-Guide)
wiki and the hardware facts in
[`fujinet-hardware/AppleII`](https://github.com/FujiNetWIFI/fujinet-hardware/tree/master/AppleII)
(FujiApple Rev1.1: IDC20 port, DB-19 adapter, USB-C, two LEDs, two
buttons). Screen mockups reproduce the exact strings and key labels
from `src/apple2/screen.c`.

Apple, Apple IIc, Apple IIGS, ProDOS, and SmartPort are trademarks
of Apple Inc., used here in loving tribute. FujiNet is a community
project not affiliated with Apple. Distributed under GPLv3 as part
of `fujinet-manuals`.
