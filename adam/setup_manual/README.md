# FujiNet CONFIG Set-Up Manual for the Coleco ADAM

A new-user set-up guide for FujiNet CONFIG on the Coleco ADAM, in two formats:

* **`manual.typ`** → **`fujinet-config-adam-setup-manual.pdf`** — print manual,
  designed after the 1983 Coleco *ADAM Set-Up Manual* (silver pinstripe cover,
  ITC Benguiat Gothic, gray section banners, black corner folios, 5.5×8.5 in
  half-letter pages).
* **`wiki/FujiNet-CONFIG-Set-Up-Guide-for-the-Coleco-ADAM.md`** — GitHub wiki
  version for https://github.com/FujiNetWIFI/fujinet-firmware/wiki

Function coverage was taken directly from the `fujinet-config` source
(`src/adam/*` + common code) and `fujinet-firmware` (button/LED behavior,
boot-config behavior), current as of June 2026.

## Building the PDF

Requires [Typst](https://typst.app) (a static binary is fine; the Makefile
looks on `PATH`, then in `~/.local/bin`):

```sh
make            # build fujinet-config-adam-setup-manual.pdf
make watch      # rebuild automatically while editing manual.typ
make preview    # render every page as PNG into preview/ for proofing
make clean      # remove built artifacts
```

Or directly:

```sh
typst compile --font-path fonts manual.typ fujinet-config-adam-setup-manual.pdf
```

## Fonts

`fonts/` contains the typefaces used by Coleco's original ADAM manuals:

| File | Family (internal) | Use |
|---|---|---|
| AvantGardeGothic-Medium.otf | ITC Avant Garde Gothic | body text |
| AvantGardeGothic-MediumOblique.otf | ITC Avant Garde Gothic | (reserve, body italic) |
| AvantGardeGothic-Bold.otf | ITC Avant Garde Gothic | run-in heads, charts, cover subtitle |
| Serpentine-Bold.otf | Serpentine | section banners, chapter titles |
| Serpentine-BoldOblique.otf | Serpentine | page folios, lead capitals, flourishes |
| HandelGothicD-Light.otf | Handel Gothic D | cover display, TABLE OF CONTENTS, step numerals |

Obtained from fontsgeek.com. All three are commercial typefaces
(ITC/Monotype, URW); these files are included for this tribute project's
build only — do not redistribute separately, and consider a license for
commercial use.

## Images

All photographs and screenshots are currently **placeholders** rendered as
labeled boxes. `FIGURES.md` lists every needed image with its exact target
filename. Drop real files into `images/` and rebuild.

`images/fujinet-logo*.png` are derived from the official FujiNet logo
(`FujiNetWIFI.github.io/assets/FujiNet-b.png`).
