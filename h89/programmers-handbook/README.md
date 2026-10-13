# FujiNet Manual for the H89 FujiNet — Programming

The programmer's companion to the H89 FujiNet Operation Manual
(`../operation-manual/`). It covers:

- how a program talks to the card: the 82C55A's ports, the handshake, and the
  FujiBus protocol, byte by byte;
- Z80 assembly, cross-assembled with z88dk-z80asm: one source file for HDOS 2.0
  and for Heath CP/M 2.2.04, with the book's own small library;
- 8080 assembly on the H89 itself, with Heath's ASM and Digital Research's ASM
  and LOAD;
- C with z88dk and fujinet-lib, including a reference to every library
  function;
- every command of every device, each with a Z80 snippet, a C snippet and the
  bytes that went over the bus;
- the 28 network protocols;
- whole programs:
  - NETCAT, NGET/NPUT and an ISS tracker (JSON), each in assembly and in C;
  - the Texas Hold'em, Battleship and Fujitzee games, listed in full.

`fujinet-h89-programming-manual.pdf` is the book.

## House style

The same as the Operation Manual: Heath's 1979 *Manual for the Digital
Computer Model H88 — Operation* (595-2268-02).

- Two columns, with a badge-and-rule running head and "Page N-M" folios.
- Century Schoolbook heads.
- ( ) steps, and NOTE / CAUTION / WARNING run-ins.
- The gold cover, labelled PROGRAMMING, FN-89-02.

`lib.typ` and `figs.typ` are kept identical to the Operation Manual's.
`prog.typ` adds what a programmer's manual needs:

- program text in the H19's own characters (the font is made from ROM 444-29);
- command cards;
- shaded byte strips;
- two-column listings.

`pfigs.typ` draws the timing diagrams, frames and memory maps.

## Nothing printed is typed in by hand

| What is printed | Where it comes from |
|---|---|
| Snippets | Cut by `tools/mksnips.py` from `;@ex KEY` … `;@end` and `//@ex KEY` … `//@end` regions of programs that were built and run, into `data/snips.json`. |
| Byte strips | The bus log of those runs (`tools/tap.py` between the emulated card and fujinet-pc), split at marker frames by `tools/mkexamples.py` into `data/examples.json`. Never edited. |
| Listings | Made from the sources by `tools/mklistings.py`, into `data/listings/*.json`. For the games, the file set is taken from the H89 builds' dependency files. |
| Screens | The emulator's H19, read cell by cell from its picture (`tools/ppm2cells.py`, `tools/keepscreen.py`), into `screens/*.json`. The stand-in network is replaced by the Operation Manual's example network; `data/screenfix.json` records every replacement (see FIGURES.md). |
| Command facts | The firmware surveys in `data/fwspec/*.json`, every statement cited to a line of fn-h89's source. |

See `tools/EXERCISERS.md` for how the command examples are written and run.

## The rig

Every program runs on FujiNet Go H89's headless machine. Its in-process FujiNet
is switched off (`enable_fujinet=0`), so the emulated card dials
127.0.0.1:11512. There, `tools/tap.py` logs every frame and passes it to a
fujinet-pc built from the firmware the book describes:

- fn-h89 `h89-disk-fixes`, 7ab84ae64;
- RS232 target, `-DPINMAP_H89`;
- listening on port 11514.

`tools/helpers.py` supplies the local servers the examples talk to:

- a TCP test board;
- an HTTP server that logs methods and bodies, with canned ISS JSON;
- a client for FujiNet's TCP server;
- UDP.

`tools/runprog.sh` runs one program. A lock serialises runs, because the card's
port is fixed.

| Piece | Version |
|---|---|
| Firmware | fn-h89 7ab84ae64 (reports v1.6) |
| fujinet-lib | `h89-setup-after-reset` d08f584 (Chapters 13-19 and the library tests: `h89-keep-esp32-running` 9e6d4dd) |
| z88dk | v2.4-1231 (3bd06cad56) |
| FujiNet Go H89 | `card-reset-bus-hold` 51f411d (Chapters 13-19 and the library tests: v0.1.0-3, 8dc059d) |
| Games | Texas Hold'em 6bad3aa; Battleship 0c86ed6; Fujitzee from its uncommitted `add-h89` working tree |

## Building

```sh
make            # the PDF: needs typst 0.15 and the fonts in fonts/
make ONLY=08    # one chapter, quickly (no contents)
make preview    # PNG pages in preview/
make check      # stranded lines, margins, overprinting, fonts
```

Everything the PDF needs is committed: `data/`, `screens/`, `fonts/` and
`images/`. These regenerate it, given z88dk, FujiNet Go H89, fn-h89,
fujinet-lib and the game repositories:

| Command | Does |
|---|---|
| `tools/asm.sh OS NAME src.asm` | Assembles a Z80 program for HDOS or CP/M |
| `tools/cc.sh OS NAME src.c ...` | Compiles a C program, with the book's z88dk options |
| `tools/runprog.sh RUN OS UNTIL CMD PROG [FILE...] [-- STEPS]` | Runs it on the rig, into `build/runs/RUN/` |
| `python3 tools/mkexamples.py RUN...` | Turns the bus logs into byte strips |
| `python3 tools/mksnips.py` | Rebuilds the snippets |
| `tools/games.sh`, then `python3 tools/mklistings.py texasHoldEm battleship fujitzee` | Builds the games and lists them |
| `python3 tools/mkcmds.py ~/Workspace/fn-h89` | Rebuilds the command equates |
| `tools/native.sh` | Assembles Chapter 5's 8080 programs with Heath's ASM and DRI's ASM and LOAD in the emulator, runs them, and byte-compares them with z80asm `-m8080` |
| `python3 tools/mklibref.py` | Rebuilds `data/libref.json` from fujinet-lib's headers, including a link probe for each function on both systems |
| `python3 tools/mkquickref.py`, `mkerrata.py`, `mkfigures.py` | The Appendix's quick reference, `errata.md` and `data/errata.json`, and `FIGURES.md` |
| `python3 tools/mklibtests.py` | Chapter 6's table of fujinet-lib's own tests, from the runs' screens (`build/runs/libtest*-NAME-OS`) and the notes in `data/libtests-notes.json` |
| `python3 tools/mkwiki.py` | The wiki edition in `wiki/`: page and pictures, prefixed `h89-prog-` |
| `python3 tools/cardinfo.py KEY...` | What the specs, expectations and captures say about some commands (for writing cards) |

## What was checked, and how

- **Every command** of the 119 the H89's firmware dispatches has a card. Each card has:
  - a Z80 snippet and a C snippet, cut from the exerciser programs (`src/asm/ex`, `src/c/ex`);
  - the bytes from the Z80 run under HDOS.

  Every exerciser ran in all four forms: Z80 and C, under HDOS and under CP/M.
- `expect/*.json` records the reply each example should get, and the firmware fault behind it where
  there is one. Commands that would crash fujinet-pc are written but marked `"sent": false`.
- The firmware facts in `data/fwspec/` were surveyed from fn-h89's source, every one cited to a line.
  Where a run disagreed with the survey, the run wins, and the expectation says `surprise`.
- **NGET:** its HDOS copy of a 3,000-byte file was compared byte for byte.
- **NPUT:** the test server logged what NPUT sent.
- **ISS:** the star's position on the map was checked against the arithmetic.
- **Chapter 5:** its programs were assembled by the H89's own assemblers and compared, byte for byte,
  with z80asm's output.
- **fujinet-lib's own tests** (its `testing` directory, 11 programs) ran under both systems on the
  rig. Three test programs have H89 mistakes (errata T1-T3). They were corrected in a copy,
  `build/fnlib/testing-fixed`, and run again. DISK was also linked with a copy of fujinet-lib whose
  `TIMEOUT_SLOW` is 60 s (`build/fnlib-slow`), because FUJI_COPY_FILE takes about 15 s (F91, L21).
  These tests use public servers (httpbin.dev, tcpbin.com, tnfs.fujinet.online, and others).
- **Games:** screens were taken against the live game servers. While doing so, the games agent
  accidentally seated a viewer at Battleship's ai3 table, which pushed a robot off it, and sent
  `leave` requests to clear its own test player's seats.
- **The card's start-up (Oct 13, 2026).** HDOS CONFIG hung on a real H89 (erratum L22). After
  that, `card_on`, the four Chapter 5 programs and the book's fujinet-lib (d08f584) leave and look
  for a mark in port B. FujiNet Go H89 51f411d resets the 82C55A the way the real card does.
  - Run again on it: the exercisers (Z80 and C, both systems), FNHELLO, HELLO and Chapter 5.
  - Their frames and screens matched the earlier runs, except for:
    - values that change on every run: the clock, UUIDs, random bytes, uninitialised firmware
      memory, and how often a STATUS loop polled;
    - one connection fewer, since `card_on` no longer pulses EN.
  - The byte strips are still those of the earlier runs.
  - Not run again: the programs of Chapters 13-19 and fujinet-lib's own tests.
- **Not done:** nothing was run on a real H89 FujiNet card.

## Decisions taken without asking

- Listings are set at 6.0 pt, wrapped at 95 columns. A continued line is marked +.
- Byte captures are printed as captured. Where fujinet-pc stands in for the
  card's radio, the card says STAND-IN WIFI.
- CRT screens show the Operation Manual's example network: the FujiNet at
  192.168.1.89 on "Workshop", and the test servers at 192.168.1.10. This is
  disclosed in FIGURES.md.
- The firmware is documented as it is today, with WARNING run-ins and
  workarounds, and errata.md collects every case.
- **Fujitzee's H89 port is not yet committed upstream.** The book lists the
  `add-h89` working tree as it stood when the book was made. Please commit it so
  the listing matches a commit.
- z88dk's HDOS start-up code has two faults the book works around, rather than
  patching z88dk:
  - the default load address 4480H (a split-octal misreading of 042.200);
  - the command line, which comes out damaged.

  Both are in errata.md with the proposed fixes.
