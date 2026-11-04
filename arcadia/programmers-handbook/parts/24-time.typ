#import "../lib.typ": *

#booklet.update(false)
#bandfile.update(none)
= Things That Cost Real Time <time>

Every one of these cost hours during the Arcadia’s bring-up, its ports and
this book. They are here so that they cost you less.

== The emulator is not the console

*A transaction runs inside one read.* In MAME, the read that writes SEQ
does the whole transaction before the 2650’s next instruction, so a program
that waits too little works there and fails on a cartridge, where the
network chip may take 90 seconds. Wait as the cartridge does (`FNGO`), or
as CONFIG does, for as long as progress keeps coming.

*The tick stands still.* `$2C0E` is emulated time: it does not move across a
transaction, and in an unthrottled run it races. Timing measured with it in
MAME says nothing about a console.

*MAME counts whole seconds.* `machine.time.seconds` in MAME’s Lua is an
integer, so a test script written in fractions of a second presses a key
and lets it go in the same frame, and the program never sees it. Count
frames: `emu/walk.lua` does everything in them.

*Unthrottled, it outruns the network.* With `-nothrottle` a minute of
console time passes in a fraction of a real second, so a program that waits
in frames for a server gives up before the server has answered. Anything
that talks to a live server -- NetCat, the games -- is tested with
`THROTTLE=1`.

*A key press is sixteen frames.* `walk.lua` holds a key for eight frames and
lets it go for eight. A program that auto-repeats a held key from its eighth
frame sees one press as two; NetCat repeats from the sixteenth.

*The bus has no timing.* The game chip’s two-sample rule for the address
lines, and the console’s 3.35 µs cycle, are not in MAME’s model. The
cartridge’s host tests cover them; a program cannot.

== The bench

*One MAME to one fujinet-pc.* Two consoles connected to one adapter’s BoIP
port interfere with each other. Run one at a time, and set `FUJINET_TCP`
every time: unset, it means `127.0.0.1:9995`, which may be another rig’s.

*`pgrep -f` finds itself.* A pattern such as `mame arcadia` is also in the
command line of the shell that runs the `pgrep`. Kill by the pid the bench
wrote down (`bench/down.sh` does), never by a pattern.

*fujinet-pc is always on WiFi.* It reports a network called `Dummy Cafe`,
whatever the computer is connected to, so CONFIG’s WiFi screens can only be
tested with a build that pretends otherwise.

*Servers keep their tables.* A second test against the same game server
can join the table the first left half played. `emu/games.sh` restarts the
server before each walk. And Battleship’s READY toggles: press it once.

== The assembler

*Parenthesise macro arguments* inside the macro: `(adr)>>8`. AS substitutes
the text.

*Macros before their callers.* AS resolves a label used before it is
defined, but not a macro.

*`&&` binds tighter than a comparison* in AS’s expressions: write
`(A >= 1) && (B < 2)`.

*`DW` is little-endian*, and the 2650 reads a pointer high byte first:
`DWBE` for every pointer word.

*`p2bin -s` writes a checksum* into the image. The build scripts never pass
it.

== The 2650

*`EORZ R1` does not clear R1.* It sets R0 to R0 XOR R1.

*Indexed loads and stores move R0.* `LODA,R1 TAB,R2` does not exist.

*A pointer word is page-local.* The address it holds is 15 bits, but the
word itself must be in the instruction’s own page.

*CC after a call is the callee’s last.* Follow a call whose result you test
with `COMI,R0 0`, unless its comment promises CC.

*`BCTA` against `BCFA`.* "Branch on condition true" and "false": one letter,
and NetGet threw away every good reading until it was the right one.

*The return stack is eight deep and silent.* `checkdepth.py`’s figure is a
lower bound; `depthcheck.py` follows branches and fall-through, and agrees
with the games’ own hand audits.

*Interrupts.* The runtime starts with the upper status byte clear, which
leaves interrupts enabled and trusts the `RETC` guard at `$0003`; CONFIG
starts with `$20`, interrupts inhibited. Nothing on the ARCADIA-2001
interrupts the FujiNet programs, but `$20` costs nothing.

== The 2637

*The pots are good only in the vertical blank.* Outside it the left disc
reads `$FF`: "down", for ever.

*The multiplexer shares a register.* Bit 6 of `$19F9` lives with the colours
and the character height; rewrite the register from a saved base.

*`$C0` is a switch.* A blue space turns its row into block graphics.

*`DINIT` draws 8 × 8 characters*, so its 13 rows fill the top half of the
picture. For the whole screen, clear bit 7 of `$19F9`.

*A sprite is a character.* Sprites 0--3 are drawn from user-defined
characters `$38-$3B`, which `fujidisp.inc` uses for `/ - _ :`.

== The ROM

*6,912 bytes.* Block 1 fills first. Move strings, then tables, then whole
mailbox-heavy modules to block 2; turn the most-used calls into zero-page
vectors. After that there is protocol 2.
