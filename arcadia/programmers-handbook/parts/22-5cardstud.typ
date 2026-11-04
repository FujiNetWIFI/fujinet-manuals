#import "../lib.typ": *

#booklet.update(true)
#bandfile.update(("apps.irata.online", "ARCADIA/!FUJINET/5 Card Stud.bin"))
= 5 Card Stud <fivecard>

== General

5 Card Stud is the FujiNet’s poker game: up to eight players at a table on
the server, robots among them if you like. The Arcadia client,
`fujinet-5cardstud/arcadia/`, is 2650 assembly in an 8K image, built like
Battleship and on the same mailbox library, with the Astrocade client’s
architecture: the server’s binary wire format, everything drawn straight
out of the reply window, and one opaque redraw per poll.

#shots(("fcs-tables", [the tables]), ("fcs-table", [a hand against the robots]),
  caption: [5 Card Stud, against the bench’s server])

== The Screen

Two modes, chosen by screen. The title, the name and the table list are 13
rows of 8 × 16 characters, and use `$1A00-$1ACF` as scratch while the lower
screen is off. The game is the 26-row mode with 8 × 8 characters and the
multicolour palette -- black or red ink on green felt or white cards:

#excerpt-at(auto, "listings/5cardstud/disp.inc", "DINI13: LODI,R0 $3B", n: 8)

A card is two cells, the rank and the suit, both in the suit’s colour on
the white card; the ten has a character of its own so it stays one cell, and
a hidden card is two cells of lattice at `$C0` -- a red card back, and the
one place a `$C0` cell is meant (its glyph is not 0, so it is not the
block-graphics switch). The user-defined characters are reloaded by screen:
the four suits on the title and the table, which are also the four sprites
that bob under the title; an arrow, `/` and `-` in the lobby.

== Reading the Reply Where It Lies

A table’s state is 154 bytes and 33 more for each player, up to 418, more
than one slice of the window. So the client never asks for "byte _n_": it
keeps a cursor, a slice and an offset, and `RXNEXT` returns the byte under
it and moves on, selecting the next slice when the offset wraps:

#excerpt-at(auto, "listings/5cardstud/state.inc", "RXNEXT: LODA,R0 *PRXSLC", to: "RXN2:")

`MSLICE` is `FNSLICE` of Section 4 written for block 2, where the mailbox
is in reach:

#excerpt-at(auto, "listings/5cardstud/mailbox.inc", "MSLICE: LODI,R1 FRRXSLC", to: "; MCHECK")

The chain that reaches it is the program’s deepest: drawing a seat prints a
name from the reply, which crosses a slice. The README audits it at five
return addresses; `depthcheck.py` agrees:

```
GLREQ -> RENDP -> SEATN2 -> RXPRNT -> RXNEXT -> MSLICE
```

== Believing the Reply

The reply is only believed when its length is exactly what the player count
says it should be; a short one would leave the fixed offsets reading what
the last reply left in the window:

#excerpt-at(auto, "listings/5cardstud/net.inc", "VALGM:  LODA,R0 FNRDATA+GOPLCNT", to: "VALOK:")

The table of expected lengths is `DWBE` words, read big-endian, because
33 × the player count does not fit in eight bits.

== The Controls

#grid(columns: (2.6in, 1fr), column-gutter: 0.35in, align: (center + top, left + top),
  overlay("5 Card Stud", ([move 1], [move 2], [move 3], [move 4], [move 5], none,
    none, none, none, [leave], [poll], [join]), head: [Action buttons: move 2, select]),
  [
    The keypad’s 1 to 5 choose a move from the server’s menu, checked against
    it before it is sent. The Action buttons are the 2’s wire, so in a hand
    they are strictly "move 2"; on the other screens they select. The disc
    moves through lists and spins the name wheel, and 4 and 6 move the name
    cursor.
  ])

== On the Bench

`listings/games.sh` builds the client with
`ENDPOINT=http://127.0.0.1:8793/`, and `emu/games.sh` walks it in real
time: the name, the first table (AI ROOM, two seats, a robot in the other),
and the hand, until the move menu shows #scr("1 FOLD").
