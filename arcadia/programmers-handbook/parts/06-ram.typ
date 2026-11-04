#import "../lib.typ": *

= Living in 288 Bytes <ram>

The ARCADIA-2001 has no RAM chip of its own. Its working memory is the part
of the 2637’s RAM the picture does not use: 32 bytes at `$18D0`, four at
`$18F8`, and, in the 13-row mode, the 256 bytes of the lower screen at
`$1A00`. That is 292 bytes in all, and since the runtime’s figure leaves out
the four at `$18F8`, this book calls it 288 as the firmware does.

It is less tight than it sounds. The 2650 keeps its return addresses on the
chip, so there is no stack to feed. The program is in ROM. And the reply
window is 256 bytes the program can read without owning: a FujiNet program
in 288 bytes copies almost nothing.

== The ledger

#tbl((1.15in, 0.55in, 1fr),
  [*Address*], [*Bytes*], [*Who*],
  [`$18D0-$18DD`], [14], [free: the runtime takes none of it (CONFIG’s own variables live here)],
  [`$18DE-$18DF`], [2], [`fujiboot`’s two scratch bytes],
  [`$18E0-$18EA`], [11], [the boot stub, copied here just before a swap (Section 13)],
  [`$18EB-$18EC`], [2], [`FSTRP`: the string `FNTXSTR` and `FNPATH` send],
  [`$18ED-$18EE`], [2], [`DSTRP`: the string `DPRINT` prints],
  [`$18EF`], [1], [free],
  [`$18F8-$18FB`], [4], [free],
  [`$1A00-$1A07`], [8], [`booklib.inc` and `netlib.inc`: FNGO’s count, the failure code, the STATUS reply, DREPLY’s position and count],
  [`$1A08-$1AFF`], [248], [the program’s own, from `BKVAR`],
)

The boot stub’s eleven bytes are needed only for the moment of a swap, so
any program that does not boot another can use them; `fujibank` keeps its
frame counter there. The same goes for anything the book’s libraries own:
a program that never calls `FNGO` may take `$1A00`.

#note[The lower screen is RAM only while the screen has 13 rows. Turn on
the 26-row mode (bit 6 of `$19F8`) and `$1A00-$1ACF` is on the screen:
every variable there is drawn as a character. Only `$1AD0-$1AFF` stays
yours.]

== What a whole program takes

CONFIG is the measure: it uses every one of the 292 bytes. Its cursor,
counters and scratch fill `$18D0-$18EA` around the runtime’s two pointers;
four flags take `$18F8-$18FB`; and the lower screen holds, laid over one
another because no two are needed at once, the path being browsed, the host
name and the WiFi name and password being edited, then the filter, the
copy’s source, a stack of parent folders and the editor’s state, up to
`$1AFC`.

NetCat (Section 12), by contrast, fits in the first 41 bytes of the lower
screen: the libraries’ eight, nine variables at `BKVAR`, and a 17-byte line
buffer at `BKVAR+16`.

== Reading instead of copying

The reply window stays as it is until the next transaction ends or a slice
is selected, so:

- *print from it*: `SETSTR FNRDATA+140` and `DPRINT` puts an IP address on
  the screen with no copy at all;
- *send from it*: `FNTXSTR` reads its string through a pointer, so
  `SETFSTR FNRDATA` streams a name the last reply held straight into the
  next command’s TX stream;
- *test it in place*: `LODA,R0 *FRDP,R3` reads reply byte R3 wherever the
  window is.

What cannot stay in the window is anything needed _after_ the next
transaction: RXLEN, a count to READ, a byte of state. Copy those first.

#important[The reply that matters is always the last one. `netlib.inc`’s
`NSTAT` copies STATUS’s four bytes into `NAVL..NDST` before anything else
runs, because the READ that follows paints over them.]

== What RESET keeps

The console’s RESET starts the 2650 again at `$0000`. Nothing clears the
RAM, and RESET does not reach the cartridge, which has no reset line. So after a
RESET:

- the RAM holds what it held -- initialise every variable you rely on;
- the cartridge keeps its ACKSEQ, so the next sequence number is not 1
  (Section 4);
- a protocol 2 image keeps its page and its cartridge RAM (Section 15).

Switching the console off restarts everything, the cartridge included.
