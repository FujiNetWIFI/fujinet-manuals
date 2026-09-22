# FujiNet Programmer's Handbook for the TRS-80 Color Computer

The companion volume to the Getting Started manual: a source-verified
reference for every FujiNet command a Color Computer can issue, with a
worked example in both 6809 assembly and C on every one of them.

It is 131 pages. Chapters 1–5 are the short road to a working program;
6–11 are the libraries and the two environments (Disk BASIC and OS-9);
12–15 are the command reference, 102 cards covering every command the
firmware dispatches on the DriveWire bus and naming every one it does
not; 16–19 are four complete programs; the appendices carry a quick
reference, the error codes, the full listings and a troubleshooting
table.

## House style

Cut from the same cloth as `../getting_started`, which is itself a
tribute to the 1980 Radio Shack *TRS-80 Color Computer Operation Manual*
(26-3001/3002): a landscape 10×8 booklet, Century Schoolbook text,
double-rule chapter heads with the green centre ornament, pale-yellow
caution panels, green gradient end bars, black-pill keycaps, and screens
typeset cell-exact in the genuine MC6847 character set.

To that it adds what a reference needs and a getting-started guide does
not: command cards, side-by-side 6809/C example panels, byte-field
diagrams, and program listings read straight off disk at typeset time.
Code is set in Source Code Pro — Hot CoCo is the MC6847 charset and has
no lowercase, so it stays where the other book put it.

## Building

```
make            # fujinet-programmers-handbook-coco.pdf
make watch      # rebuild as you edit
make preview    # preview/p001.png ... at 110 ppi
make listings   # build every program in listings/ from clean
make check      # the completeness and correctness gates
make clean
```

Needs Typst 0.15 or later. Fonts are vendored in `fonts/` and passed
with `--font-path fonts`, so the build is self-contained.

`make listings` needs `cmoc` and `lwasm`; `make check` additionally
needs `python3` and `pdffonts`.

## The checks

`make check` is the reason to trust the reference chapters.

* `tools/cmdcheck.py` reads the firmware's dispatch tables — the shared
  handler map in `fujiDevice.cpp`, the four mixins beside it, the two
  commands `drivewireFuji.cpp` adds, and the unified `NDevice.cpp` — and
  diffs them against the `#cmd()` cards in `manual.typ`. It fails if a
  dispatched command has no card, or a card names a command the firmware
  does not answer. Point `FUJINET_FIRMWARE` at a checkout; without one it
  says so and passes.
* `tools/snipcheck.py` pulls every 6809 snippet out of the book and
  assembles it with `lwasm`, stubbing the labels that belong to the
  program around each fragment. 121 snippets, all of them assemble.
* `pdffonts` must show no fallback font, which is how a missing glyph
  gets caught.

Current state:

```
cmdcheck: 102 cards cover 85 dispatched commands: ok
snipcheck: 121 assembly snippets assemble, 122 C snippets balanced: ok
fonts: ok
```

## The example programs

All of them are in `listings/` and all of them build from clean.
Appendix C `read()`s these exact files when the book is typeset, so a
listing in the PDF cannot have drifted from one that compiles.

| Program | What it shows |
|---|---|
| `listings/fnlib/` | `fn.inc`, `fnlow.asm`, `fnnet.asm`, `cocoio.asm` — the 6809 library this book develops, plus `fcdemo` in both languages |
| `listings/netcat/` | the five moves of the `N:` device, both languages |
| `listings/mounter/` | host slots, a directory, a device slot, a mount |
| `listings/weather/` | a JSON channel end to end |
| `listings/os9/` | the same stack above a transport you supply, built with `cmoc --os9` |

C examples link against fujinet-lib. A release unpacks flat; point
`FNDIR` at it:

```
make -C listings FNDIR=~/fujinet-lib
```

Nothing here has been run against hardware or an emulator. Every listing
compiles, every byte layout was read out of the firmware, and the OS-9
transport is correct by inspection of the register map rather than by
observation. The book says so in its own words in Chapters 11 and 19.

## Sources of truth

| Source | What came from it | Commit |
|---|---|---|
| `fujinet-firmware` | every opcode, command byte, parameter width, payload size and reply length; the dispatch tables; the error codes | `9415d3e40` |
| `fujinet-lib` | the byte layout of every frame it sends, and the C half of every example | `515f7b1` |
| `fujinet-apps` | how real Color Computer clients are built | `390b92a` |
| `~/Workspace/libdw`, `coco-net-debugging` | the earliest hand-written statements of this framing | — |
| CMOC 0.1.100, LWTOOLS 4.24, Typst 0.15.1 | the tools everything was built and typeset with | — |

The firmware bugs the book names in Chapters 12, 13 and 14 —
`COPY_FILE` never reading its payload, the clock's double-swapped
timezone length, the base64 and QR output commands' missing length word,
`SET_PARSER` reading aux2 where every client sends aux1 — are named so
that somebody can fix them. When that happens this book is wrong and a
new edition is owed.

## Wiki edition

`wiki/FujiNet-Programming-Guide-for-the-Color-Computer.md` is the
GitHub-wiki edition: the same section order, ASCII in place of the Typst
diagrams, and the full command reference inline as markdown tables so
that the page stands alone. It is maintained by hand alongside
`manual.typ`; when the two disagree, the firmware sources win. Its home
is the fujinet-firmware wiki.
