#import "../lib.typ": *

= Game Three: Fujitzee

#lead[Five dice, three rolls, thirteen boxes to fill. Fujitzee is the one
game here that uses the NES's sprites -- and the one whose whole state
arrives in a single 599-byte structure.]

#shots("fz-1", "fz-3", w: 2.4in, caption: [Waiting for the others to get
ready; the scorecard, the dice and the cursor -- the dotted frame round the
second die is twelve sprites.])

#objbox("Object of the game / Game description")[Each turn, roll up to three
times, keeping any dice you like between rolls, then score the result in one
of the thirteen boxes. Up to six players sit at a table; more can watch.]

== Requests and replies

The requests are `state`, `ready`, `roll/` followed by five 0s and 1s -- which
dice to keep -- `score/` and a box number, and `leave`. With `bin=1` the reply
is the table's name and prompt, the round, the rolls left, whose turn it is,
the dice, the dice kept, which boxes are open, and then for every player a
name and sixteen scores of two bytes each.

The client declares the same layout as a C structure and the server's bytes
go straight into it. If cc65 ever padded that structure, every field after the
padding would be wrong -- so the NES layer refuses to compile if it is not
exactly the size the server sends:

#excerpt-at("src/nes/util.c", "listings/games/fujitzee/util.c",
  "/* The server sends the packed wire layout", n: 3, size: 7pt)

599 is 95 bytes of table and 42 for each of twelve players. A reply for three
players is 221 bytes.

== The active column

The scorecard has a column per player, and the player whose turn it is gets
a black column instead of a blue one. Each column is exactly one attribute
byte wide, and background palette 1 is palette 0 with blue made black -- so
the whole highlight is five attribute bytes:

#excerpt-at("src/nes/graphics.c: columnAttr", "listings/games/fujitzee/graphics.c",
  "static void columnAttr", to: "void setHighlight", size: 6.8pt)

== Sprites for the cursor

The cursor round a die is a checkerboard frame a pixel outside it -- twelve
sprites, so moving it never touches the nametable. Their 256-byte page has to
be page-aligned, so the linker configuration shrinks the work RAM by a page
and puts the sprites at `$7F00`. A sprite DMA, like any PPU access, has to
happen in vblank:

#excerpt-at("src/nes/graphics.c: oamFlush", "listings/games/fujitzee/graphics.c",
  "static void oamFlush(void)", to: "static void blitShadow", size: 6.8pt)

The queue is drained first, so the NMI that `waitvsync()` waits for has
nothing to flush and leaves most of the vblank for the DMA. And because the
PPU forgets its sprites while rendering is off, the whole-screen redraw does
the DMA again before it turns the picture back on.

== The keyboard as a key source

Battleship's on-screen keyboard runs its own editing loop. Fujitzee's feeds
the shared code's ordinary text-entry routine instead, one key at a time,
through `kbhit()` and `cgetc()` (Listings 18 and 19). The shared code does the
editing; the keyboard only has to say which key was pressed:

#excerpt-at("src/nes/input.c", "listings/games/fujitzee/input.c",
  "unsigned char kbhit", n: 14, size: 6.8pt)

== One player

The other clients let two or more people play from one computer. The NES has
one controller here, so the NES build defines `SINGLE_LOCAL_PLAYER` and the
screen that groups local players is compiled out.

== The server

The server is Go, in `servers/fujinet-game-system/fujitzee`. Its bots --
numbered, so "1AI CLYD" -- chase a large straight when one is close, otherwise
keep their biggest set, and fill the upper boxes first when that will earn
the bonus. Tables `ai2` and `ai4` have bots; `bar` and `kit` start empty.
