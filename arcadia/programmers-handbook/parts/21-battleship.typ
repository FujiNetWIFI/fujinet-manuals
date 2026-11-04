#import "../lib.typ": *

#booklet.update(true)
#bandfile.update(("apps.irata.online", "ARCADIA/!FUJINET/Battleship.bin"))
= Battleship <battleship>

== General

Battleship is the FujiNet’s game for two to four fleets on one ocean, played
against people or the server’s robot admirals. The Arcadia client is 2650
assembly, `fujinet-battleship/arcadia/` at the revision in the Parts List:
an 8K image, protocol 1, no banking. Its game logic is the Astrocade
client’s, cut again for this hardware. This section is about how it is
built; the Owner’s Manual tells how to play it.

#shots(("bs-place", [placing the ships]), ("bs-battle", [a shot fired and answered]),
  caption: [Battleship, against the bench’s server and its robot admiral])

== The Screen

Battleship runs the 26-row mode with 8 × 8 characters, and the multicolour
mode (bit 7 of `$18FD`): `$19F8` = `$46` and `$19F9` = `$AF`, so a cell’s
two colour bits choose white or red ink on blue or black. A framed 10 × 10
board is exactly 12 rows, so two boards, a status row and a footer fill the
26 with nothing left over -- and the split between the two screen halves
falls exactly between the boards. The frames are the 2637’s built-in glyphs
`$04-$0B`, which leaves all eight user-defined characters for the ships, the
hits and the misses; `$38` is also the targeting reticle’s image, sprite 0.

One routine writes every coloured cell, and it knows the trap of Section 5:

#excerpt-at(auto, "listings/battleship/disp.inc", "DPUTC:  IORA,R0 DCOLOR", n: 6)

A space with colour bits `11` would turn the row into block graphics, so
`DPUTC` writes `$80` instead, which looks the same here.

== The Controls

#grid(columns: (2.6in, 1fr), column-gutter: 0.35in, align: (center + top, left + top),
  overlay("Battleship", (none, [fire], none, [view], [turn], [view], none, none, none,
    [back], [poll], [select]), head: [Action buttons: fire, select]),
  [
    The disc moves the reticle in both directions, which most Arcadia
    programs do not attempt: both axes of a disc arrive at `$19FF`, one at a
    time, by the multiplexer of Section 9. `KEYRAW` flips the multiplexer
    once a frame, samples only the axis it selected the frame before (so the
    2637 has had a whole frame to digitise it), and decodes the direction
    from the _cached_ pair -- so a held direction reads the same every frame,
    which the edge detection and the auto-repeat need.
  ])

#excerpt-at(auto, "listings/battleship/input.inc", "KEYRAW: LODA,R0 AXSEL", to: "        LODA,R0 $1900")

The base value of `$19F9` lives in `BGCBAS`, set when a screen’s mode is,
because the same register holds the character height and the palette:
leave it unset and the first frame writes 0 over the colours.

== The Network

Block 2 shares the 2650’s page 1 with the mailbox, so the whole network
stack lives there and every hotspot read is a direct indexed load; block 1
holds what touches the screen. `net.inc` carries five rules the FujiNet
family learned on the Odyssey 2 and the Intellivision, at its head:

#excerpt-at(auto, "listings/battleship/net.inc", "; A 2650 transcription", to: "; All routines return")

`APICALL` is one round trip: close the previous request, open this one,
STATUS until two readings agree, READ, check the length:

#excerpt-at(auto, "listings/battleship/net.inc", "APICALL: STRA,R0 *PVURL", to: "APFAIL:")

The wire format is the server’s binary one (`?bin=1&v=2`), drawn straight
out of the reply window: the 100-cell board is read in order, one byte a
cell, and nothing is buffered.

== Placement

The ships are seeded at random and then moved by hand, and each move is
checked for overlap -- with 84 bytes of RAM in the 26-row mode and a 100-byte
board, there is nowhere to keep an occupancy map. So the screen is the map.
`PLDRWO` repaints your board with every hull but the one being moved, and
`TESTSHP` reads the cells that ship would cover back through the same
pointer the writer uses: legal if every one is open sea.

#excerpt-at(auto, "listings/battleship/place.inc", "PLTRY:  BSTA,UN PLDRWO", to: "; TESTSHP:")

== The Depth

The placement redraw is the program’s deepest chain. The client’s README
audits it by hand at six of the eight return addresses; `depthcheck.py`
agrees, counting the main loop’s `GLPLC` as the seventh routine:

```
GLPLC -> PLACSCR -> PLSHOW -> PLDRWO -> YBCLR -> DFILL -> DPUTC
```

The firmware’s `checkdepth.py` reports less, for the reasons of Section 7.

== On the Bench

`listings/games.sh` archives the client at its pin and builds it with
`ENDPOINT=http://127.0.0.1:8792/`, the bench’s own Battleship server;
`emu/games.sh` walks it in real time: the name screen, the table list (the
fifth table, AI-1, has one robot), READY, the five ships left where they
were seeded, and a shot two squares right and two down. The robot answers;
the walk passes when it is your turn again.

#important[`/ready` toggles, and the server’s countdown is wall-clock
time. A script that presses the Action button again in the lobby un-readies
the player and cancels the countdown: press once, and wait for the screen to
change.]
