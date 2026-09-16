#import "../lib.typ": *
= Battleship

Battleship is a complete networked game for the Video Computer System: a 6502 client for the FujiNet Battleship server, in the binary wire format the Intellivision, Astrocade, Arcadia and Channel F clients share. Up to four 10 × 10 boards on screen at once, in colour, with the fleet strips saying which ships are afloat; a lobby, a placement screen that rolls you a fleet, a menu on the RESET switch, a keyboard for your name, and sound --- on a console with 128 bytes of RAM, no framebuffer, and a playfield with one colour per line. It is 7,800 lines of source in seven banks and a tail, and this section walks through every part of it. Appendix D prints it.

#shot("bs-lobby", w: 1.9in, caption: [The lobby, against the live server: its tables, the seats, and FIRE to join.])

#sect[The screen]

```
 YOUR TURN 45         the status row, synthesised
 BOB   >      ALICE   names over the pair: left owner, a marker each, right
 ###==    #####       each seat's fleet: '#' afloat, '=' sunk; three lines tall
 +-----------+-----------+
 |           |           |   board pair A, 80 lines: two 10x10 boards of
 |    Q1     |    Q2     |   8x8-pixel cells, abutting at pixel 80 with a
 |           |           |   two-clock black missile down the seam
 +-----------+-----------+
 YOU          CAROL
 #####    ##===
 +-----------+-----------+
 |    Q0     |    Q3     |   pair B
 +-----------+-----------+
```

#shot("bs-layout", w: 2.2in, caption: [The four-seat screen, from the layout ROM: status row, names with the turn marker, fleet strips, and two pairs of boards --- blue water, red-and-white hits, white misses, gold hulls and cursor, and the black divider down each seam.])

Three or four seats use the family's quadrant convention: you bottom-left, the others clockwise from top-left. Two seats --- the common case, a table against the server's AI --- get one pair of 8 × 12 cells, square on a 4:3 set, and the lower half becomes text: the server's prompt, each fleet as pips, and a hint.

The status row is synthesised, because the server's prompt is empty for the whole of play: `MISS YOU 45`, `HIT ENEMY`, `SUNK YOU 12` --- the last result, whose turn, and your clock, which counts down locally and polls when it runs out.

#sect[Controls]

#tbl((auto, 1fr, 1fr, 1fr),
  th[], th[Lobby], th[Placement], th[In play],
  [stick], [---], [move the ship], [move the cursor],
  [FIRE], [ready up, a toggle], [keep the ship where it is, or where you moved it], [attack that cell],
  [SELECT], [poll now], [rotate], [poll now],
  [RESET], [], [the menu], [the menu: resume, how to play, leave])

RESET is a switch on this console, a bit in a RIOT register the program reads; it restarts nothing, and what it means is the client's to choose. A shot lands on every live enemy at once --- the one rule this game does not share with the board game, and the reason the help page exists.

#sect[Seven banks and a tail]

A bank switch replaces every byte of `$1000`--`$17FF`, so each bank carries its own copy of every module it calls. Only zero page crosses; the text planes, the playfield tables and the reply window are cartridge state, and survive.

#tbl((auto, auto, 1fr, auto),
  th[Bank], th[File], th[What it does], th[Bytes],
  [0], [`bslobby`], [the cold start and the table list], [1016],
  [1], [`bsgame`], [the board kernel, the cursor, the cues, a shot], [1668],
  [2], [`bsnet`], [one request, with the picture up, and back], [1993],
  [3], [`bsmenu`], [the RESET menu, the help, leaving], [1092],
  [4], [`bsname`], [the keyboard and the shared username], [1201],
  [5], [`bsplace`], [the roll, the five ships], [2013],
  [6], [`bscomp`], [compose the game screen, in passes], [2025],
  [tail], [`bstail`], [the trampoline, the transport, the cold stub], [220])

Seven banks pad to eight, 16384 bytes. The composer is a bank of its own because the game bank came in 961 bytes over with it inside; the network bank exists because the URL and transport code is 550 bytes; and three things every bank used to carry whether it wanted them or not were split behind feature flags before the fleet strips and the roll would fit anywhere: reading the stick (104 bytes) from reading a player record (118), streaming the reply into a row from the string helpers, and the sound cues, numbered so that each bank's are a prefix of the list and a constant says where its copy stops.

The transport and the four text primitives live in the tail, the one region every bank sees at the same address, and `tools/mktail.py` reads their addresses out of the tail's own listing into a generated include, so there is no hand-kept list to go stale. The trampoline resets the stack on every switch, for the reason Section 13 gave.

#sect[Where to carry on]

A switch is a jump, so "what the bank being entered should do" is data: an entry code in `BSENT`. Sixteen of them, and every bank's entry point dispatches on the one it finds:

#excerpt-at("bsdefs.inc: the entry codes", "listings/battleship/src/bsdefs.inc", "ENCOLD  EQU", to: "; ---", size: 6.5pt)

#sect[The zero page]

`$80`--`$BF` is the program's; the stack must stay above `$C0`. `$80`--`$8C` and `$A8`--`$A9` are the transport's; `$8D`--`$A7` is the swap stub's landing ground in the library's clients, and since this program never swaps, it is the program's here.

#excerpt-at("bsdefs.inc: the client's cells", "listings/battleship/src/bsdefs.inc", "INRPT   EQU", to: "; ----------------------------------------------------------------------", size: 6.1pt)

Three regions of it have rules. `$AE`--`$B0` is the game bank's edge memory --- the previous active player, status and last attack --- and it must survive placement, or the first poll after placing hears a phantom shot. Cells with two names are aliases that are never live at the same time, and each carries the reason next to it: `BSINP` and `BSAVL0` share a byte because the network's byte count is only live inside a transaction, when no input runs. And a bank's scratch must never alias a cell a loop in another bank is counting in: a "done" flag in the network bank once aliased the settle loop's delay counter, its hook ran inside every frame that loop drew, and the symptom was a cold start after the first poll.

The place bank needed four more cells for the roll and took `BSSEL`, `BSERR2`, `BSBLINK` and `BSTMP2`, each dead in that bank for a reason written beside it. `SHIPS[4]` is the roll's flag: the slots fill in order, so `$FF` in the last one means the roll is still running, and no cell was spent on a state byte.

#sect[The transport]

The tail's transport is the library's, and the network bank builds on it. Five rules from the siblings are written into `net.inc`: CLOSE at the start of the next request, never after the READ, because every screen renders straight out of the window between polls; capture RXLEN at once, because it belongs to the most recent transaction; STATUS until two readings agree and the count reaches a minimum, because the adapter reports early; the fourth STATUS byte is where an HTTP error shows; and unsigned compares go through the carry.

#excerpt-at("net.inc: the whole round trip", "listings/battleship/src/net.inc", "APICALL: sta", to: "; BSWAIT", size: 6.3pt)

`NPGO` is `FNGO` with a frame drawn per poll, and one frame drawn *before* the first look at the acknowledgement:

#excerpt-at("net.inc: a frame before the first look", "listings/battleship/src/net.inc", "NPGO2:  lda", n: 12, size: 6.5pt)

A validation failure after the read returns without closing: the next request's leading CLOSE retires the connection, and closing here would wipe a window the caller may still be rendering the last good reply from.

#sect[The URL]

Nothing is assembled in RAM. The cartridge counts the payload itself, so nothing tracks a length, which is the only reason a console with 128 bytes can build `N:https://battleship.carr-designs.com/attack/47?table=ai1&player=VCS&bin=1&v=2` at all. The endpoint comes from ROM, the request path from one of six strings, a cell number through a decimal converter that emits digits straight into the TX page, and the table id and player name from two cartridge path buffers --- pushed there once from the server's reply, and emitted raw into every later URL:

#excerpt-at("url.inc: the query string from the path buffers", "listings/battleship/src/url.inc", "BUQ:    ldx", to: "; ----", size: 6.5pt)

#tbl((auto, 1fr),
  th[Request], th[URL],
  [tables], [`tables?bin=1` --- no table, no player],
  [state], [`state?table=T&player=P&bin=1&v=2`],
  [ready], [`ready?...` --- a bare `/ready` toggles],
  [place], [`place/P,P,P,P,P?...` --- each P is `pos + 100 × dir`],
  [attack], [`attack/P?...` --- P is `y × 10 + x`; its reply *is* the next state],
  [leave], [`leave?...`, then a fresh `tables`])

A staged request rides the poll: `/attack`, `/ready` and `/place` all return the next state, so there is no separate submit anywhere in this client. `v=2` brings the winner and the ship reveal at game over.

#sect[The state record]

The server's `?bin=1&v=2` reply is one record, parsed in place. Nothing copies. A 38-byte header is always present; what follows depends on the phase.

#tbl((auto, auto, 1fr),
  th[Offset], th[Size], th[Field],
  [0], [1], [player count, at most 4],
  [1], [33], [the prompt],
  [34], [1], [status: 0 lobby, 1 placing, 10 started, 11 miss, 12 hit, 13 sunk, 99 over],
  [35], [1], [your own status: 0 playing, 1 defeated, 2 viewing, 3 ready, 10 placing],
  [36], [1], [the active player; `$FF` nobody; 0 is you; at game over, the winner],
  [37], [1], [seconds left on the move clock],
  [38], [1], [in play: the last attack position],
  [39], [10], [in play: your five ships, then the winner's five],
  [49], [115 each], [in play: a record per player --- name (9), status (1), the 100-cell field, five ships-left bytes])

In the lobby the body is a server name and ten-byte records of name and status; during placement the records are ten bytes too, and *a program that indexes a game field in the placement phase reads garbage*. In play the second player's record starts past 256, out of an 8-bit index's reach, which is why `PLRECP` is a pointer. `VALID8` checks the reply's length against what the header implies --- a minimum, since a longer reply is harmless and a shorter one means stale bytes --- then caches the four bytes every bank keys on.

#excerpt-at("state.inc: a pointer to a player's record", "listings/battleship/src/state.inc", "PLRECP: lda", to: "; GCURS", size: 6.5pt)

The largest reply, four players in play, is 509 bytes: it fits slice 0 whole, which is why the reply window is 512.

#sect[The game bank]

`bsgame` is the board kernel and the per-frame hook: tick the sound, take the text pass the composer owes, read the stick with auto-repeat, RESET to the menu, SELECT to poll now, the stick to move the cursor and FIRE to shoot, then the clock, and when the poll clock reaches zero, the switch to the network bank --- taken here, inside the vblank, so that the network bank finishes this frame.

#excerpt-at("bsgame.asm: the hook", "listings/battleship/src/bsgame.asm", "APPVBL: jsr", to: "; GMOVE", size: 6.4pt)

A shot is refused with a tone if the cell is already resolved on every live enemy, because the server refuses it silently and the turn never passes. Moving the cursor is a PFCELL blit that clears the gold bracket on every live board, a step, a click, and a blit that puts it back.

#sect[Every frame is 262 lines]

The blanked bands are timed with the RIOT timer, and so is the visible one: the kernel's own lines add up to less than 192 and a timed pad at the bottom absorbs the difference, so an overrun moves nothing. Four things keep a network poll from blanking the screen or making it shudder:

- The network bank carries the board kernel and spends every wait for the cartridge drawing a frame out of the tables it is still holding.
- The overscan is waited out at the *start* of the next frame, not the end of the one before, so whatever a bank does between frames --- stream a URL, recompose the boards, switch banks --- is spent inside the overscan, as long as it fits in thirty lines. With the wait at the end, a played game measured 96 frames in 2,400 that were 273 to 310 lines.
- A switch into a frame is taken inside the vblank hook, and the bank entered finishes the frame. A switch that started a fresh frame from the hook would throw a 40-line frame at the set.
- A poll's recompose is two passes in a bank of its own: the boards between frames, in the overscan; the text a frame later, in the vblank, and only the rows a poll can change.

`TIMINT`, not `INTIM`, is what the waits read. Past zero the timer free-runs at a tick a cycle, and a seven-cycle `LDA INTIM` / `BNE` walks over the single cycle it reads zero on; `TIMINT`'s bit 7 latches on the underflow and stays latched, so an overrun costs exactly the overrun. Polling `INTIM` cost an overrunning frame 290 lines where the work was 151.

The seam line of a text row is a budget, not a glitch. A seam that runs past cycle 76 does not glitch; it silently costs a second scanline. The first cut of the text kernel reached a `LDA` at cycle 77 on one path, every seat row was seven lines instead of six, and the frame was 278 lines --- a picture that rolls on anything that cares, and nothing about it looked wrong on screen.

#sect[The composer]

`bscomp` composes the game screen in passes, because a poll's recompose is about 3,900 cycles and the overscan between frames has about 2,200. The boards go between frames from the reply window with four blits a seat; the AUX plane --- hulls and cursor --- in the next frame's vblank; the text a frame later, and only the rows a poll can change: the status row, the fleets, and the two turn-marker cells of each name row through a TCELL blit. A screen change is three passes more.

#excerpt-at("bscomp.asm: the pass schedule", "listings/battleship/src/bscomp.asm", "CENTRY: lda", to: "; GCOMPB", size: 6.4pt)

The result cue rides the pair of status and last-attack position, because the status repeats across polls when nobody has fired since; the turn cue rides the active player's edge and fires last, so it is what is heard when both happen at once.

#sect[The lobby, the name, the menu, the placement]

The lobby lists the server's tables from a `/tables` reply --- 36-byte records starting at offset 1, after a count byte --- and joining is not a call: fetching the state for a table is the join. The row count comes from the listing's count byte, not from dividing the length by the stride, which says 5 only by accident of rounding.

The name bank reads the shared username from the appkey and puts it straight into a cartridge path buffer; if the slot is empty or there is no SD card, a three-row keyboard types one, shown through a PATH blit because the console cannot read the buffer back, and writes it back best-effort.

The menu bank exists for RESET: resume, how to play, leave. LEAVE sends `/leave` and then a fresh `/tables`, so the seat is given up rather than abandoned.

The placement screen opens on a fleet, not an empty board: five random legal placements are rolled --- one candidate per frame in the vblank hook, because a whole fleet does not fit in one overscan and the first version, which looped, dropped every button pressed at it --- the whole fleet is drawn, and the stick moves whichever ship's turn it is from where the roll put it. Overlaps are checked here, by walking each staged hull, because a hundred-byte occupancy map is most of the console's RAM.

#excerpt-at("bsplace.asm: one candidate a frame", "listings/battleship/src/bsplace.asm", "PROLLF: jsr", to: "; ----", size: 6.5pt)

#sect[Sound]

One TIA channel and a script engine that steps once a frame. A cue is a list of steps --- frames, control, frequency, volume --- ending in a zero. Twelve cues, in bank order, so that each bank's are a prefix of the list and the constant `SNDLAST` truncates its copy of the scripts there: the place bank fires four of the twelve and used to carry all of them, which was 148 bytes it did not have.

#excerpt-at("sound.inc: the cues, in bank order", "listings/battleship/src/sound.inc", "SNDMOVE EQU", to: "; ---", size: 6.5pt)

#sect[How it is checked]

#tbl((auto, 1fr),
  th[Target], th[What it proves],
  [`make hosttest`], [the four playfield transforms against a picture of the tables built from the bit map in prose, every slot, poisoned outside],
  [`make layout && make shot`], [the kernel with no network: tables baked in, snapshotted, and every cell line of every board read back and required to be the colour the picture says, plus the divider],
  [`make drive`], [a game against the live server at two seats, reading the table off the screen through the font; after every poll, the reply's game fields and the cartridge's tables must agree byte for byte],
  [`make drive4`], [the same at four seats, reading the fleet strips back and requiring the pips to match each record],
  [`make frames`, `make frames4`], [a VSYNC tap over a whole game: nothing but 262],
  [`make resettest`, `make resetleave`], [a 6507 restart, and the RESET switch, which are two different things],
  [build gates], [the equates against the firmware header, the image's size and claim and control-page opcodes, each bank's extent from the assembler's own listing, and the tail's])

#sect[Traps paid for here]

- A blit is single-slot on the RP2040: a burst of thirteen would lose most of them on hardware and none in MAME. BLITGEN exists because of this program.
- Missiles replicate with their player's copy count: with the text's three close copies there were three dividers.
- A text row leaks: the six-copy kernel goes on displaying its last two bytes until something blanks them, and a `JSR` right after the row routine's `RTS` lands at cycle 79 and costs a scanline without anything looking wrong.
- The seam line's two deadlines are not the same deadline: `COLUBK` before pixel 0 at cycle 22, the sprite blanking before the text block at cycle 39. Blanking first, where it is free, put the water in four clocks late.
- NTSC hue 4 is pink; red is hue 3. The text block is at clocks 52--99, not 46--93: a player positioned by `RESPn` completing at cycle N lands at clock 3N − 63, measured from the raster.
- The poll's recompose was three lines too long at four seats, and had been all along: `make frames` was two seats. `emu/banktime.lua` put the switch into the composer at +235.9 lines and the switch out at +263.5, so the pass wanted 27.6 lines of the 26.1 it had. The AUX plane became a pass of its own.
- A cold start's RAM clear writes every zero-page cell, so a write tap sees a spurious request in bank 0: that is the clear, not a fetch.
- Throttled is not a performance choice: the server's countdown and move clock are wall clock, and an unthrottled MAME sits at "starting in 2" forever.
