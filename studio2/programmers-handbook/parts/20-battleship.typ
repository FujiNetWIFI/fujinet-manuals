#import "../lib.typ": *

#opener-art.update((sub: [2 to 4 players · either keypad],
  art: tvrow("bs-placement", "bs-turn12", "bs-game-over", w: 1.15in)))
= Battleship <battleship>

Fuji Battleship is played across the FujiNet by up to four players at once, people or the server’s bots, each with a fleet of five ships on a ten-by-ten sea. One shot lands on every opponent’s board at the same square. The Studio II port draws all four boards on one screen, every hit, miss and hull of them, with the cartridge’s mosaic cells. It is in `fujinet-battleship/studio2/`, and the handbook carries it unchanged in `listings/battleship/`.

== Playing it

#fig(goldpanel(inset: 8pt, w: auto, stack(dir: ltr, spacing: 0.3in,
  keypad(name: [AIMING], hot: (5,)), {
    set text(size: 7pt, weight: 700)
    set par(leading: 0.4em)
    align(left + horizon, [1–9: MOVE THE CURSOR, \ AS THE KEYS LIE \ 5: FIRE \ 0: MENU])
  })), caption: [Aiming: the keys move the cursor the way they lie on the pad, diagonals too.])

#tbl((0.95in, 1fr),
  [*Screen*], [*Keys*],
  [Name], [2 4 6 8 move on the grid, 5 types, 1 deletes, 3 done, 0 keeps the old name],
  [Tables], [1–8 joins that table, 0 the menu],
  [Waiting room], [5 ready or not, 0 the menu],
  [Placement], [2 4 6 8 move the blinking ship, 1 turns it, 5 keeps it, 3 rolls the rest again, 0 the menu],
  [Your turn], [1–9 move the cursor, 5 fires, 0 the menu],
  [Menu], [1 or 0 back, 2 leaves the table, 3 changes the name, 4 quits to CONFIG],
)

The fleet starts as a random legal roll, so five presses of 5 is a fleet. A beep marks your turn, and a shorter one every hit and sink.

== The screen

#crt2("bs-tables", "bs-waiting-room", caption: [The tables, and the waiting room.])

Your board is at the bottom left and the others go clockwise from the top left, as in every other port. Each board has its name above it, the player to move in inverse, and the panel at the right shows the clock, whose turn it is, the last shot and the keys.

== Four boards on 160 cells

Four boards of a hundred squares will not go in 32 glyphs: two squares by three to a cell, with five states each, is thousands of combinations. The text engine’s mosaic cells were added for this game. A square is one tile; `tiles.inc` defines sixteen, and they are chosen so one OR makes a square’s tile: the game field’s byte (0 unknown, 1 hit, 2 miss) ORed with a mark (hull, cursor, the ship being placed).

#wex("listings/battleship/src/tiles.inc", "tiles:  DB", n: 16, at: bottom)

`board.inc` composes a board row, fifteen tile pairs, into one MOSAIC operation: four to a board, sixteen to redraw all four, about 7,500 instructions, a tenth of a second. The cursor blinks by redefining three tiles: the cartridge then redraws only the cells that use them.

#note[The boards are lit fields with dark marks. With a dark sea, the boards vanished into the black around them.]

== The network

`net.inc` is 5 Card Stud’s, as is, and carries the rules every FujiNet game client on a small console has learned:

- The CLOSE goes at the *start* of the next request, never after the READ: every transaction repaints the reply window, and the screens draw straight out of it between polls.
- Take the reply’s length right after the READ.
- STATUS reports as soon as _some_ of the response is in: poll until two readings agree *and* a known minimum has arrived.
- STATUS’s fourth byte must be 1: an HTTP error page has a readable body too.
- Check the length against what the player count implies before believing a byte.

#wex("listings/battleship/src/net.inc", "; nbeg --", to: "; ngo --", at: top)

The requests are short paths on the server, `state`, `ready/1`, `place/a,b,c,d,e`, `attack/p`, each with `?table=&player=&bin=1&v=2`. `url.inc` streams the devicespec into the TX stream a byte at a time, percent-encoding the name and the table, and never builds it in RAM: a placement is about 110 of the 320 bytes a transaction carries.

#note[The settle minimum must be the shortest state that can follow the last one. Using the last state’s exact length wedged every move from the lobby to placement, because placement’s reply is ten bytes shorter.]

== The server, at home

The server is `fujinet-game-system/battleship` in the FujiNet servers repository, a Go program:

```
cd servers/fujinet-game-system/battleship
PORT=8771 go run .
```

Build the client against it with `ENDPOINT=http://127.0.0.1:8771/ make`. It does not tell the public lobby about itself unless `GO_PROD=1` is set. Test against your own; the public server is where people play.

== Played through, in MAME

The game’s own `emu/bsdrive.lua` plays a whole game against the local server, with the handbook’s bench: it types a name when the app key is empty, joins `AI - 3 BOTS`, readies, moves and turns the carrier, keeps the fleet, fires on every turn, visits the menu, and leaves the table at the end. `emu/games.sh battleship` runs it; the screens in this chapter are its snapshots. It runs MAME at real speed: the server’s clocks are real time.

#crt2("bs-placed", "bs-menu", caption: [The fleet placed, and the menu.])
