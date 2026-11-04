#import "../lib.typ": *

= Pages, Blocks and Pointers <pages>

The 2650 divides its 32K into four _pages_ of 8K, and most of its
instructions cannot see past the page they are in. On the ARCADIA-2001 that
rule meets the cartridge’s two blocks, and between them they decide where
every routine and every table goes.

== What reaches what

#tbl((1.6in, 1.05in, 1fr),
  [*Addressing*], [*Example*], [*Reaches*],
  [absolute, a load, store or ALU instruction], [`LODA,R0 $1800`], [only the instruction’s own 8K page: 13 address bits],
  [absolute, a branch or call], [`BCTA,UN $2000`], [anywhere: 15 bits],
  [relative], [`BCTR,EQ LOOP`], [64 bytes back to 63 ahead],
  [indirect, `*`], [`LODA,R0 *PTR`], [anywhere: the 15-bit address in the two bytes at PTR, high byte first -- but PTR itself must be in the instruction’s page],
  [indexed], [`LODA,R0 TAB,R3`], [the page, at TAB + R3; R0 moves the data],
  [indirect indexed], [`LODA,R0 *PTR,R3`], [anywhere: the address at PTR, plus R3],
  [zero page], [`ZBSR *$10`], [`$0000-$003F` and `$1FC0-$1FFF`, from any page],
)

Block 1 (`$0000-$0FFF`) is in page 0 with the 2637 and the RAM
(`$1800-$1AFF`). Block 2 (`$2000-$2FFF`) is in page 1 with the mailbox. So:

- *code in block 1* reaches the screen, the controllers and the RAM
  directly, and the mailbox only through a pointer;
- *code in block 2* reaches the mailbox directly, and the screen and the RAM
  only through a pointer.

AS knows the rule and stops a build that breaks it:

```
START:  LODA,R0 $2C00           ; in block 1
> > > pg.asm(6): error: target not on same page
```

== Pointer words

An indirect address is two bytes, _high byte first_. AS’s `DW` writes words
low byte first, the other way round, so every pointer the 2650 dereferences
is made with `fujilib.inc`’s `DWBE` macro:

#excerpt-at(auto, "listings/runtime/fujilib.inc", "DWBE    MACRO", n: 3)

#caution[A pointer written with `DW` assembles without a word and reads
the wrong address. `DW $2C00` stores `$00 $2C`, and the 2650 goes to
`$002C`.]

The runtime lives in block 1, so it keeps a pointer word in block 1 for
every mailbox address it uses, and reaches each through it:
`LODA,R0 *FACKP` reads ACKSEQ, and `LODA,R0 *FTXP,R1` reads
`$2F00` + R1, appending R1 to the TX stream.

The pointer word itself is found the ordinary way, so it must be in the
instruction’s own page: code in block 2 cannot use `FACKP`, which is in
block 1. Going the other way, code in block 2 needs pointers into page 0,
kept in block 2. 5 Card Stud
and Battleship put their network code in block 2, where `LODA,R0 FNREPLY`
reads the reply byte directly, and reach their RAM variables through
pointer words such as `STRA,R0 *PAVA0`.

== Zero-page vectors

`ZBSR` and `ZBRR` are the 2650’s short calls and branches: two bytes,
relative not to the instruction but to address zero, so they reach the same
64 bytes from every page. With `*` they are indirect, through a pointer word
in those bytes. CONFIG keeps 30 such words, from `$0004` to `$003F` -- the
bytes between the header and the runtime that every other program leaves
empty -- and calls any routine, from either block, in two bytes:

```
ZMSTART: DWBE   MSTART          ; at $0004 on: one word a routine
...
        ZBSR    *ZMSTART        ; 2 bytes, from anywhere
```

Against a three-byte `BSTA` that saved CONFIG about 180 bytes, which is how
the whole CONFIG fits the 6,912. `depthcheck.py` cannot follow an indirect
call, and says so; a program built this way counts its depth by hand.

== Splitting a program between the blocks

Block 1 has 4,096 bytes and block 2 has 2,816. A program that outgrows block
1 moves to block 2, in this order of cheapness:

+ *strings*, read through `DSTRP` (any page), if nothing reads them with a
  direct indexed load;
+ *tables*, reached through a pointer word with an indirect indexed load;
+ *whole modules* that talk to the mailbox more than to the screen: the
  network code, the boot code -- which in block 2 can read the mailbox
  directly and get smaller as they move.

CONFIG splits that way: block 1 holds the screen, the RAM and the
controller; block 2 the mailbox, WiFi, boot, the tables and the strings.

== Five traps

Every one of these cost an evening during the FujiNet ports.

*`EORZ` works on R0.* `EORZ R1` sets R0 to R0 XOR R1; it does not clear
R1. To clear any register but R0 use `LODI,R1 0`. (`EORZ R0`, which clears
R0, is the one form that does what it looks like.)

*Indexed means R0.* `LODA,R1 TAB,R2` will not assemble: in an indexed
instruction the register field names the index, and the data is R0.

*A store does not set CC.* `SUBI,R0 1` then `STRA,R0 N` then `BCFR,EQ`
tests the subtraction, which is usually what you want -- but not if you
meant to test the stored byte loaded from elsewhere.

*CC after a call is the callee’s last.* Battleship’s random number routine
ended on `COMZ R1`, so a `BCTR,EQ` after the call tested that compare, not
the number; every ship was placed the same way round. Follow such a call
with `COMI,R0 0`.

*Read the branch twice.* `BCTA` branches when CC _is_ the condition, `BCFA`
when it is _not_. While this book was written, NetGet’s test for "the
count is not zero" was a `BCFA,EQ` where a `BCTA,EQ` belonged, so it threw
every good reading away and timed out with the file waiting:

```
        IORA,R0 NAVL            ; and not 0?
        BCTA,EQ AGAIN           ; zero: read STATUS again
```
