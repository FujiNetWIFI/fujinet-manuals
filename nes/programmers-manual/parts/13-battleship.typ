#import "../lib.typ": *

= Game Two: Battleship

#lead[Fuji Battleship: up to four players, each with five ships and a
ten-by-ten sea, every shot fired at every opponent at once.]

#shots("fbs-1", "fbs-3", "fbs-4", w: 1.95in, caption: [Ready to start against
three bots; placing the fleet; four of five placed, the B button turning the
fifth.])

#objbox("Object of the game / Game description")[Place five ships, then take
turns choosing one square. Every opponent's sea is hit at that square at once.
The last fleet afloat wins. As with 5 Card Stud, the server does the work and
the client asks, draws and answers.]

== What is different here

Battleship's NES layer has the same shape as 5 Card Stud's -- a `src/nes/`
directory behind the shared code, the same `ppu.s`, the same split CHR -- with
three things worth a closer look: how it draws a whole screen, how it waits
for a frame, and `fujinet.c`, the one file through which it talks to the
FujiNet.

#note[At the time of writing the NES port of Battleship is not yet committed
to its repository; the listings here are taken from the working tree.]

== One file for the FujiNet

On the NES, most of fujinet-lib's `fuji_` calls are macros over the bus call.
The shared code's own prototypes for them would link against nothing, so
everything that talks to the cartridge is in one file that includes only the
library's headers, and the shared code reaches it through three hooks:

#excerpt-at("src/nes/fujinet.c: the hooks", "listings/games/battleship/fujinet.c",
  "int16_t custom_network_call", to: "static void quitStatus", size: 6.8pt)

The rest of `fujinet.c` (Listing 15) is the trip back to the Lobby, the same as
5 Card Stud's.

== Wire format

Requests are `state`, `ready`, `place/` with the five ships' squares,
`attack/` with one square, and `leave`, with `bin=1&v=2`. The reply has two
shapes, chosen by its status byte: in the lobby, the server's name and each
player's name and status; in play, the last shot, the player's own ships, and
for each player a 100-byte sea -- the squares hit and missed -- and how many of
each ship is still afloat.

== A whole screen at once

A full 32×24 screen through cc65's queue takes eleven frames -- a third of a
second, plainly visible as the picture is painted in. So for the two
operations that change everything, Battleship stops the picture and writes
the nametable directly from its shadow copy:

#excerpt-at("src/nes/graphics.c: blitShadow", "listings/games/battleship/graphics.c",
  "static void blitShadow(void)", to: "/**", n: 40, size: 6.6pt)

It drains the queue first, or the queue would land stale cells on top
afterwards. It turns the NMI off for the duration, because the NMI handler's
flush and scroll reset write `$2006` too. And it turns the picture back on at
the top of a frame, so the screen never starts halfway down.

Everything else goes through `put()`, which queues a cell only if it has
changed:

#excerpt-at("src/nes/graphics.c: put", "listings/games/battleship/graphics.c",
  "static void put(unsigned char x", to: "/**", size: 6.8pt)

#note[Battleship's art is the MS-DOS client's CGA tile sheet, converted tile
for tile: CGA's four colours are exactly one NES palette, so Battleship never
writes an attribute byte after start-up. It uses all 256 tiles.]

== Waiting for a frame

#excerpt-at("src/nes/util.c: waitvsync", "listings/games/battleship/util.c",
  "  cc65's own waitvsync()", to: "void resetTimer", size: 6.8pt)

== Buttons

#tbl((auto, 1fr),
  th[Button], th[Does],
  [A], [Choose; fire],
  [B], [Rotate the ship being placed; refresh],
  [START], [The menu],
  [SELECT], [Change your name],
  [SELECT + A / B / START], [Help / sound / quit to the Lobby],
)

As in 5 Card Stud every button is a key to the shared code, and Select is a
shift that reports on release only if nothing else was pressed with it
(Listing 17).

== The server

The server is Go, in `servers/fujinet-game-system/battleship`. There is no
"join": a player who asks for a table's state is seated at it. Tables `ai1`
to `ai3` have one to three bots, which take three seconds a move. The bots do
not cheat: each builds a map of where an enemy ship could still be from what
it has hit and missed -- a single hit, a gap between two hits, a line of hits
-- and prefers squares that could hit more than one player's ship at once.
When a human sits down at a full table, a bot gets up for them.
