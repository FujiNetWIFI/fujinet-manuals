#import "../lib.typ": *

= The 2650 Library <library>

Every program in this book is built on two files from the cartridge’s
firmware, `fujilib.inc` (the mailbox) and `fujidisp.inc` (the screen and the
controller), used exactly as the firmware ships them, and on three of the
handbook’s own: `bookdefs.inc` (the commands), `booklib.inc` (what every
program shares) and `netlib.inc` (the network device).

== A program’s shape

#excerpt-at(auto, "listings/asm/clock.asm", "        CPU     2650", to: "GO:     FNBEGIN")

- *The header* is the first four bytes: `BCTA,UN START` at `$0000`, where
  the 2650 starts, and the `RETC,UN` guard at `$0003`.
- *The includes come first.* AS resolves a label used before it is
  defined, but not a macro, so every file with a macro in it (`SETSTR`,
  `SETFSTR`, `DWBE`, `FNBEGIN`, `PUTS`) must be included before the code
  that uses it. `fujidisp.inc` goes first, then `fujilib.inc`.
- *The status word.* `EORZ R0` then `LPSU` clears the upper status byte;
  `LPSL` with `$02` sets COM, so every compare is _logical_ (unsigned): `$C0`
  is greater than `$40`. The libraries count on it.
- *The display* comes up with `BKINIT` (or the runtime’s own `DINIT` and
  `DCLS`), then `FNCHECK` asks whether there is a FujiNet at all.

== The registers

#tbl((0.6in, 1fr),
  [*Reg.*], [*By convention*],
  [R0], [the data: every indexed load and store moves R0, and every routine returns its result there],
  [R1, R2], [the arguments: a register number and a value, a cell, a count],
  [R3], [a counter or an index],
)

A routine’s comment says which registers it clobbers; assume the rest are
clobbered too unless it says otherwise. The second register bank (R1--R3
with RS set) is never selected.

#important[On the 2650 a _load_ sets CC (EQ, GT or LT, by sign), and so does
every arithmetic and logical instruction and every compare. A _store_ does
not. After a subroutine returns, CC is whatever its last such instruction
left: the library routines end with R0 loaded, so `BCFA,EQ FAIL` right
after `FNGO` is safe. A routine of your own may not be; follow it with
`COMI,R0 0` when in doubt.]

== fujilib.inc: the mailbox

#tbl((0.95in, 1fr, 0.95in),
  [*Routine*], [*Does*], [*Clobbers*],
  [`FNREGWR`], [register R1 = value R2], [R0],
  [`FNSTART`], [DATA_RST, and DEVICE = `$70`: begin a Fuji command], [R0--R2],
  [`FNPARB`], [append a one-byte parameter, value R2], [R0, R1],
  [`FNTXSTR`], [append the string at `(FSTRP)`, at most 255, no NUL], [R0, R1, R3],
  [`FNPATH`], [append it padded with NULs to 256 bytes], [R0, R1, R3],
  [`FNCOMMIT`], [SEQ = ACKSEQ + 1, wait about 6 s: R0 = ERR, or `FETIMO`], [R1--R3],
  [`FNSLICE`], [show reply slice R2, wait for SLICE_ECHO], [R0, R1, R3],
  [`FNCHECK`], [R0 = 0 when the `F`, `N` magic is there], [R0],
)

`SETFSTR label` points `FSTRP` at a string. At the end of the file are the
pointer words page-0 code reaches the mailbox through -- `FSELP`, `FDATP` and
`FTXP` for the hotspots, `FRDP` for the reply, `FACKP`, `FERRP`, `FREPP`,
`FRXLP` and the rest for the status page -- each a `DWBE`, big-endian, as the
2650 reads an indirect address (Section 8).

== fujidisp.inc: the screen and the controller

#tbl((0.95in, 1fr, 0.95in),
  [*Routine*], [*Does*], [*Clobbers*],
  [`DINIT`], [13-row text, 8 × 8 characters, white on black, sound off; loads the eight UDCs], [R0, R1, R3],
  [`DCLS`], [all 208 cells to spaces], [R0, R3],
  [`DXLAT`], [ASCII in R0 to a glyph in R0], [R0, R1],
  [`DPRINT`], [the string at `(DSTRP)` from cell R2 + 1], [R0--R3],
  [`DHEX`], [R0 as two hex digits from cell R2 + 1], [R0--R2],
  [`SCAN`], [in the vertical blank: the first control held, as a code (Section 9)], [R0, R1],
  [`GETKEY`], [wait for a fresh press: its code], [R0, R1],
)

== booklib.inc and netlib.inc: the handbook’s

#tbl((0.95in, 1fr, 0.95in),
  [*Name*], [*Does*], [*Clobbers*],
  [`FNBEGIN`], [macro: DATA_RST, then DEVICE, CMD and NPARAM], [R0--R2],
  [`PUTS`], [macro: print a string from a cell], [R0--R3],
  [`BKINIT`], [`DINIT`, then 8 × 16 characters, then `DCLS`], [R0, R1, R3],
  [`FNPARW`], [append a two-byte parameter, R2 low, R3 high], [R0, R1],
  [`FNTXN`], [append R2 bytes from `(FSTRP)`], [R0--R3],
  [`FNGO`], [commit, wait up to 96 s, check ERR and REPLY: R0 = 0 on an ACK], [R1--R3],
  [`WAITF`], [wait R3 frames], [R3],
  [`DREPLY`], [print `DRCNT` reply bytes from `DRPOS` at cell R2 + 1], [R0--R3],
  [`FAIL`], [branch here with a code: FAILED and the code on row 12], [--],
  [`NOPEN`], [OPEN the devicespec at `(FSTRP)`, mode R2], [R0--R3],
  [`NSTAT`], [STATUS, its four bytes kept in `NAVL..NDST`], [R0--R3],
  [`NREAD`], [READ R2 (low), R3 (high) bytes], [R0--R3],
  [`NWRITE`], [WRITE R2 bytes from `(FSTRP)`], [R0--R3],
  [`NCLOSE`], [CLOSE], [R0--R3],
)

== Eight calls deep

The 2650 keeps its return addresses in an eight-entry stack on the chip.
`BSTA` pushes one and `RETC` pops it; there is no RAM stack and no way to
see how full this one is. A ninth call overwrites the oldest entry without a
word, and the routine at the bottom of the chain then returns to the wrong
place.

So the depth of every program is counted when it is built. The firmware’s
`checkdepth.py` builds a graph from the `BSTA`s, one node per label, and
reports the deepest chain. That is a lower bound, for two reasons:

- *It does not follow falling through.* `FNCOMMIT` makes its `BSTA,UN
  FNREGWR` after its own label `FNCM1`; falling into `FNCM1` is not a call,
  so the graph loses the edge.
- *It does not follow branches.* A routine that ends with `BCTA,UN FNGO`,
  or a `BCFA,EQ FAIL` from inside a subroutine, runs the target at the depth
  the branch was taken; the graph counts the target from nothing.

The handbook’s `tools/depthcheck.py` reads the program as AS does --
includes in place, macros expanded -- and gives each label its calls (one
deeper), its branches (the same depth) and its fall-through (the same
depth). It counts a chain as the firmware’s script does, the top level
included, so a depth of 8 is seven return addresses. For `fujiboot` the
firmware’s script says 3 and the stricter count says 4: `CHKACK` branches
to `FAIL`, and `FAIL` calls `DPRINT`, which calls `DXLAT`. NetCat, the
deepest program here, is 6. Battleship and 5 Card Stud, whose READMEs audit
their deepest chains by hand because the firmware’s script undercounts
them, come out at the hand audits’ figures. Both scripts run on every build;
the stricter one decides.

A jump from inside a subroutine back to a top-level loop that never returns
-- CONFIG does it on every error -- leaves return addresses on the stack. On
the 2650 that is harmless: the stack is a ring of eight, and the old entries
are overwritten. `depthcheck.py` notes each such jump rather than calling it
recursion.

== Building

`listings/asm/build.sh` does for every program what the firmware’s
`build.sh` does for the cartridge’s own, and its images are byte for byte
the firmware’s:

#excerpt-at(auto, "listings/asm/build.sh", "    (cd \"$src\" && \"$ASL\"", to: "    # the call graph")

+ `asl` assembles the program, from its own folder, with `-i` naming the
  runtime and the generated `bookcfg.inc` (the bench’s URLs).
+ `p2bin` writes the flat `$0000-$2FFF`; `-l 0` fills the gaps with zeros.
+ `mkimage.py` folds the two blocks into the 8,192-byte image.
+ `dd` stamps the claim, `FUJI`, at image `0x1CFC`.
+ `checkrom.py`, `checkdepth.py` and `depthcheck.py` check the result.
