#import "../lib.typ": *

#opener-art.update((sub: [fourteen pages · one program],
  art: tvrow("pages", w: 1.6in)))
= Pages and Far Calls <pages>

The 1802’s short branches are two bytes long. The second is the low byte of the target; the high byte stays what it was. A short branch therefore reaches only the 256-byte page it is on, and the long branches that reach further are three-cycle instructions the cartridge cannot allow. A program bigger than a page is a set of pages joined by the runtime’s calls.

== Staying on the page

AS knows which page each branch is on and refuses one whose target is elsewhere. The runtime’s `FIT` macro keeps a routine whole: `FIT 43` starts the next page unless 43 bytes still fit on this one.

#excerpt-at(auto, "listings/runtime/s2macro.inc", "FIT     MACRO", n: 5)

Put a `FIT` in front of every routine that branches, with its size. `tools/fitcheck.py` measures each one in the listing and complains when the size is too small, while the routine still happens to fit.

#important[Never fall through into a `FIT`. When it moves to the next page it leaves a gap of zeros behind, and `$00` is `IDL`. End the code before every `FIT` with a branch, an `FJMP` or an `FRET`.]

== Leaving the page

`FJMP` goes anywhere, at the cost of a trip through the runtime; `FCALL` calls anywhere and comes back. Neither cares which page it is on, and both keep D and DF. A program’s routines can be scattered over all the pages it has.

`RFIT`, CONFIG’s version of `FIT` that `osk.inc` brings in, also skips the four pages at the bottom of each 4K block, which a program may not use. A program that runs past `$0FFF` should use it.

== The pages

#tbl((1.2in, 1fr),
  [*Pages*], [*Count*],
  [`$04-$07`], [4: the runtime],
  [`$0A`], [1],
  [`$0C-$0F`], [4],
  [`$x4-$xF`, x = 1 to D], [156],
)

One ST2 image holds 64 of them, 16K: CONFIG takes 25, Battleship 42.

== Fourteen pages

`pages.asm` runs through fourteen pages. Each is a page of its own, made by a macro, and does two things: calls `mark`, which shows the page it was called from, and jumps to the next.

#excerpt-at(auto, "listings/asm/pages.asm", "; PAGE here, next", n: 6)

`mark` finds the page in R6, the link the call left. The page number is the high byte of the address the call would return to.

#excerpt-at(auto, "listings/asm/pages.asm", "; mark --", to: "done:")
