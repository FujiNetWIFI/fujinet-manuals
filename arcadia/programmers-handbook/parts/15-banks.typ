#import "../lib.typ": *

= Bigger Than 8K: Protocol 2 <banks>

The connector never shows the console more than 8K, and a program’s share of
that is 6,912 bytes. M.U.L.E. needed about 48K. So the mailbox has a second
version, protocol 2 (`$2C0B` reads 2), with three things a big program
needs: _pages_ of code seen through a window, a kilobyte of _cartridge RAM_,
and a _tick_ that counts the frames. On an ordinary 8K image all three are
inert, so nothing in Sections 2 to 14 changes.

== The APPBANK image

A protocol 2 image is exactly 8,192 + _k_ × 2,048 bytes, _k_ from 1 to 31 --
at most 71,680 -- and it carries the claim. Its first 8K are laid out as an
ordinary image; the 2K pages after them are seen, one at a time, through
the _window_ at `$0800-$0FFF`:

#tbl((1.25in, 1.1in, 1fr),
  [*Image*], [*Console*], [*Is*],
  [`0x0000-0x05FF`], [`$0000-$05FF`], [fixed: always there],
  [`0x0600-0x07FF`], [`$0600-$07FF`], [cartridge RAM, the low half (RAM-L)],
  [`0x0800-0x0FFF`], [`$0800-$0FFF`], [the window; page 0 lives here],
  [`0x1000-0x18FF`], [`$2000-$28FF`], [fixed],
  [`0x1900-0x1AFF`], [`$2900-$2AFF`], [cartridge RAM, the high half (RAM-H)],
  [`0x1B00-0x1FFF`], [`$2B00-$2FFF`], [the mailbox, as on any image],
  [`0x2000` + (_n_--1) × `0x800`], [`$0800-$0FFF`], [page _n_, when selected],
)

So the fixed code is 1,536 bytes in block 1 and 2,304 in block 2, and every
page adds 2,048. M.U.L.E. is 51,200 bytes: the base and 21 pages.

== Selecting a page

One read of `$2D80` + _n_ selects page _n_ (_n_ under 32). The game chip
decodes it where it serves the bus, so the very next fetch already sees the
new page: the read must be made from fixed code, never from the window it
changes. A page that does not exist reads `$FF`.

```
        LODI,R1 2               ; page 2
        LODA,R0 *FBNKP,R1       ; FBNKP: DWBE FNBANK ($2D80)
        BSTA,UN $0800           ; call into it
```

The swap of Section 13 maps page 0. A console RESET changes neither the page
nor the cartridge RAM, so a program’s start code selects page 0 itself
before it calls into the window, as `fujibank` does in its first lines.

== Cartridge RAM

The 1K of cartridge RAM is the image’s own bytes at `$0600-$07FF` and
`$2900-$2AFF`, made writable. *Reading* it is reading ROM: code in block 1
reads `$0600` directly, code in block 2 reads `$2900`. *Writing* it is, as
always, reading:

#steps(
  [Set the pointer: REGSEL `$14`--`$17`, then REGDATA _v_. The pointer is
   `0x000`, `0x100`, `0x200` or `0x300` plus _v_, in the RAM’s own 10-bit
   space: `0x000-0x1FF` is RAM-L, `0x200-0x3FF` is RAM-H.],
  [REGSEL `$18`, POKE, then one REGDATA for each byte: each stores its value
   at the pointer and moves it on, wrapping at `0x400`.],
  [End the burst with a bare REGSEL `$14`.],
)

So _n_ bytes cost _n_ + 4 reads. These reads are taken by the game chip’s
bus code and never reach the mailbox proper, whose REGSEL is good for one
REGDATA. The closing REGSEL matters: after it, a stray REGDATA can move the
pointer but never store.

#excerpt-at(auto, "listings/runtime/fujibank.asm", "; ---- 3. RAM-L and RAM-H", to: "        LODI,R3 0               ; RAM-L reads back")

#caution[Never _store_ into the cartridge’s space, cartridge RAM included.
The connector has no read/write line, so the cartridge drives the data lines
whenever A12 is low, and a `STRA` into `$0000-$0FFF` or `$2000-$2FFF` makes
the 2650 and the game chip drive them at once: a bus fight. MAME ignores the
store; a real console may not survive it.]

== The tick

`$2C0E` (low) and `$2C0F` (high) count 60 Hz frames from the cartridge’s
power-up and keep counting through transactions: a clock the console never
had. Read the high byte, the low, then the high again, and try again if the
two highs differ:

#excerpt-at(auto, "listings/runtime/fujibank.asm", "; Read the tick tear-free", to: "TSTR:")

#note[In MAME the tick is emulated time: it stands still across a
transaction, which runs inside one read, and runs fast in an unthrottled
test. On the cartridge it is the game chip’s own timer.]

== fujibank

`fujibank` is the cartridge’s own test of all of this: an 8K base and three
pages. It reads the id byte at `$0FFF` after selecting each of pages 0 to 4
(4 does not exist), calls into page 2, pokes four bytes into RAM-L and two
into RAM-H and reads them back, checks that strays after the closing REGSEL
stored nothing, and times the tick over 60 frames. The firmware’s
`emu/bankprobe.lua` reads the results from RAM and judges them; it is one
of `emu/verify.sh`’s eleven.

The pages are assembled at `$3000` and up in the flat, each with `PHASE
$0800` so its labels have the window’s addresses, and `mkimage.py --pages 3`
appends them to the folded 8K:

#excerpt-at(auto, "listings/runtime/fujibank.asm", "BANKPG  MACRO   n", to: "        BANKPG  1")

== M.U.L.E.

The FujiNet M.U.L.E. client for the Arcadia is the reason protocol 2
exists, and the measure of it. It runs its game screens in the 26-row mode,
where the console has only 84 bytes of RAM left, so its state lives in the
cartridge RAM: the 550-byte game state from the server in RAM-L, names and
the server’s address in RAM-H. A small fixed layer, in the 1,536 and 2,304
fixed bytes, holds what every page needs; the boot, the network core and
each screen -- the map, the town, the auction -- are pages of their own,
called through the window.
