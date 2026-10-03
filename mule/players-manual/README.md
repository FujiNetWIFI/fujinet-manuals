# M.U.L.E. Player's Guide (The FujiNet Multiplayer Edition)

This is the player's guide to [The FujiNet Multiplayer M.U.L.E.](https://github.com/FujiNetWIFI/fujinet-multiplayer-mule). There is one edition for each machine the game runs on:

- Atari 8-bit
- Apple II
- Color Computer
- MS-DOS (PCjr and CGA)
- Coleco Adam
- MSX
- Atari Lynx
- Intellivision
- Bally Astrocade
- Atari 2600

Each edition is built three ways from a single source:

| Output | Where | For |
|---|---|---|
| PDF | `pdf/MULE-Players-Guide-<Machine>.pdf` | printing and download |
| GitHub-wiki Markdown | `wiki/*.md` and `wiki/images/` | the [FujiNet wiki](https://github.com/FujiNetWIFI/fujinet-firmware/wiki) |
| WordPress WXR | `wordpress/mule-players-guide.wxr` and `wordpress/images.zip` | fujinet.online, through Tools → Import → WordPress |

## House style

The PDF imitates the layout of the 1983 Electronic Arts **M.U.L.E.** booklet for the Atari ([archive.org/details/Mule_atari8](https://archive.org/details/Mule_atari8/)). Run `make learn` to download the scan to `learn/MULE.pdf`. The book borrows these elements from it:

- a square page (556 × 560 pt) between red-and-black bands;
- chapter titles in a heavy rounded serif over a red band;
- numbered steps ("**3.** Land Grant") with the step number in red, each over a screen in a black TV bezel, then a bold lead sentence and the body text;
- red "Q:" and "A:" for the questions and answers, and red squares for the tips;
- the reference chart at the back.

Only the layout and typography are borrowed. All of the text is new.

## Building

    make assets       # copy the screenshots from the game repo, cut the map icons
    make              # check the facts, then build the PDFs, the wiki and the WordPress import
    make check        # the PDFs use only the fonts in fonts/
    PREVIEW=coco make preview   # write each page as a PNG to preview/

The build needs:

- Typst 0.13 or later;
- python3 with PyYAML and Pillow;
- `xmllint` and `pdffonts`.

`GAME=` points at the game repository. The default is `~/Workspace/fujinet-multiplayer-mule`.

### Where the content lives

| File | Contents |
|---|---|
| `content/manual.yaml` | The text, platform-neutral. `{stick}`, `{button}`, `{end}`, `{leave}`, `{sitout}`, `{name}` and `{machine}` are filled in for each edition. |
| `content/platforms.yaml` | For each edition: the hardware, the file and its TNFS address, the boot steps, the notes, the key names and the controls table. |
| `content/rules.yaml` | The numbers: species, yields, prices, limits and the colony ratings. |
| `content/events.yaml` | The 22 personal events and the 8 colony events, in the game's own words. |
| `tools/expand.py` | Turns the content and one platform into `build/<platform>.json`. Every renderer reads this file. |
| `manual.typ` | The PDF: the house style only. |
| `tools/build_wiki.py`, `tools/build_wxr.py` | The wiki and the WordPress import. |
| `tools/checkfacts.py` | Compares the event texts, the rating texts and the numbers with the server source (`internal/rules/*.go`). `make` stops if they differ. |
| `tools/pull_assets.py` | Copies `screenshots/<target>/` from the game repo, scales each screen by whole numbers so its shape is right on paper, and cuts single map plots (the land icons) from the land-auction screen. |

### The pictures

Every picture comes from the edition it appears in. Nothing is borrowed from another machine.

The screens come from the game's offline test mode, via `screenshots/make-shots.sh` in the game repo. Its test board has:

- every land type;
- all four kinds of outfitted M.U.L.E.;
- a second lobby scene, `17-species-b`, that shows the other four species (on the Intellivision, which has no offline lobby, it is a summary screen instead).

The Atari 2600's screens come from a live game. Its icons are rendered from `mulemap.py`, the model of the cartridge's own map composer, so they show exactly what the cartridge draws.

The converted graphics in the screenshots are Electronic Arts'.

## Publishing

### Wiki

Copy `wiki/*.md` and `wiki/images/` into a checkout of the wiki's git repository (`fujinet-firmware.wiki.git`), then commit and push. `MULE-Players-Guide.md` is the landing page and links to the ten editions.

### WordPress (fujinet.online)

The WXR holds a parent page, *M.U.L.E. Player's Guide*, with ten child pages, plus one attachment entry for each picture. The importer copies each picture from the URL given in its attachment entry, `--media-base` (`MEDIA=` in the Makefile).

1. Put the contents of `wordpress/images.zip` at that URL. The default is `https://apps.irata.online/mule/manual/images/`; build with `MEDIA=...` to use another location.
2. In WordPress, go to Tools → Import → WordPress, upload `mule-players-guide.wxr`, assign the author, and tick **Download and import file attachments**.
3. The importer copies the pictures into the Media Library and rewrites the pages to use those copies.

The pages are Gutenberg blocks (headings, paragraphs, lists, images, tables, quotes), so they can be edited in the block editor after import.

## Fonts

| Face | File | Used for | Source |
|---|---|---|---|
| Souvenir | `Souvenir*.ttf` | headings, step titles, Q: and A: | the same files as `coco/getting_started` |
| ITC Benguiat Gothic Std | `benguiatgothicstd-*.otf` | body text | the same files as `intv/fujinet-programmers-guide` |

The licences are the same as for those manuals.
